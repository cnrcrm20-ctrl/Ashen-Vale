extends SceneTree
## Use the real sound channel and shipped takes, not a mock voice server. Test with --headless.
const NightSet = preload("res://scripts/kalkstein.gd")
var failures = 0


func check(ok, note: String):
	if not ok:
		push_error("Voice/night QA: " + note)
		failures += 1


func _initialize():
	call_deferred("run")


# Measure actual decoded signal on an isolated bus (no music, steps or rain).
func heard_voice(tap: AudioEffectCapture) -> bool:
	tap.clear_buffer()
	var until = Time.get_ticks_msec() + 1800
	while Time.get_ticks_msec() < until:
		await create_timer(.09).timeout
		for frame in tap.get_buffer(tap.get_frames_available()):
			if frame.length_squared() > .0004:
				return true
	return false


func screen_touch(id: int, pos: Vector2, down = true) -> InputEventScreenTouch:
	var touch = InputEventScreenTouch.new()
	touch.index = id
	touch.position = pos
	touch.pressed = down
	return touch


func run():
	var g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_physics_process(false)
	g.options.dub = true
	g.cmd("new")
	check(g.mode == "explore" and g.world is NightSet, "control from the first frame")
	check(g.hero.animator.has_animation("Crouch_Fwd") and g.hero.mark != null and g.hero.birth_skin != null and not g.hero.birth_skin.detail_enabled, "bound skeleton, crouch clip, hidden right forearm ink")
	var takes = {}
	for b in g.beats:
		for line in b.get("entry", []) + b.lines:
			if line.size() == 3:
				var clip = load("res://audio/voices/tr/%s.ogg" % line[2])
				check(clip is AudioStreamOggVorbis and clip.get_length() > 1. and not clip.loop, str(line[2]))
				takes[line[2]] = line[0]
	check(takes.size() == 10, "ten authored takes referenced")
	var bus = AudioServer.bus_count
	AudioServer.add_bus(bus)
	AudioServer.set_bus_name(bus, "Only Speech")
	var tap = AudioEffectCapture.new()
	AudioServer.add_bus_effect(bus, tap)
	g.audio.dialogue.bus = "Only Speech"
	g.voices_tick(.2)
	check(await heard_voice(tap), "Lyander waveform reaches isolated dialogue bus")
	var performing = false
	for i in range(55):
		g.audio.track_voice()
		for face in g.hero.face_meshes:
			if face.visible and face.get_blend_shape_value(0) > .035: performing = true
		if performing: break
		await create_timer(.025).timeout
	check(performing, "audible take drives the visible skinned jaw")
	check(g.audio.voice_anchor == g.hero and g.audio.last_take == "lyander_carik", "first line on moving hero")
	g.voices_tick(10.)
	check(g.audio.voice_anchor == g.world.people.Lyra and g.audio.last_take == "lyra_kapi", "reply comes from Lyra's hiding place")
	for face in g.hero.face_meshes: check(face.get_blend_shape_value(0) == 0., "previous speaker releases the jaw")
	check(await heard_voice(tap), "Lyra waveform reaches isolated dialogue bus")
	# Desktop with only a pad may hide the dial. The first actual touch must
	# hit the pressed action without needing a second tap or a physics frame.
	g.ui.touch_surface = false
	g.ui.pad = true
	var crouch_button = g.ui.action_buttons.crouch
	var action_pos = crouch_button.get_global_rect().get_center()
	check(not g.ui.dial.visible, "desktop pad-only HUD")
	g._input(screen_touch(3, action_pos)); g._input(screen_touch(3, action_pos, false))
	check(g.hero.crouched and g.ui.dial.visible, "first touch from pad mode activates the button")
	g.crouch()
	# Two simultaneous contacts, then an independent action finger; a HUD button
	# must not steal movement or camera ownership and must not fire twice.
	var left = Vector2(120, 570)
	var right = Vector2(880, 400)
	g._unhandled_input(screen_touch(0, left))
	g._unhandled_input(screen_touch(1, right))
	var drag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = left + Vector2(0,-65)
	g._unhandled_input(drag)
	drag.index = 1
	drag.relative = Vector2(12,-4)
	g._unhandled_input(drag)
	var pad_button = InputEventJoypadButton.new()
	pad_button.button_index = JOY_BUTTON_X; pad_button.pressed = true
	var was_running = g.run
	g._input(pad_button)
	check(g.run != was_running and g.ui.pad and g.ui.dial.visible, "pad works without hiding live touch actions")
	g._input(screen_touch(2, action_pos))
	check(g.hero.crouched and g.touch_move.y < -.7 and g.yaw != 0. and g.look_id == 1, "move/look/action together")
	g._input(screen_touch(0, left, false))
	g._input(screen_touch(1, right, false))
	g.crouch()
	g.cmd("pause")
	g.voices_tick(.05)
	check(g.audio.voice_held and not g.audio.dialogue.playing, "opening the journal/menu does not talk over it")
	g.cmd("resume")
	g.voices_tick(.05)
	check(not g.audio.voice_held and g.audio.dialogue.playing, "voice resumes")
	g.hero.position = g.world.loc(7.9, -1.4)
	g.interact()
	check(g.mode == "dialog" and g.audio.last_take == "lyra_zeytin", "optional bark is interrupted by the nearby conversation")
	var remain = g.spoken_left
	g.cmd("pause"); g.voices_tick(9.)
	check(g.mode == "pause" and g.audio.voice_held and g.spoken_left == remain, "pausing a conversation freezes its auto-advance clock")
	g.cmd("resume")
	check(g.mode == "dialog" and g.line_no == 0 and g.audio.dialogue.playing, "resume returns to the same voiced subtitle")
	g.cmd("next")
	check(g.audio.voice_anchor == g.hero and g.audio.last_take == "lyander_iskele", "skip replaces foreground voice, not simultaneous playback")
	g.voices_tick(9.)
	check(g.beat.kind == "night_hear", "voiced exchange advances naturally")
	g.options.dub = false
	g.hero.position = g.world.loc(22., -1.9)
	g.interact()
	check(g.lines[g.line_no][0] == "İskele kâtibi" and g.audio.last_take == "" and g.spoken_left == 0., "mute retains subtitle; clerk is not Dorian")
	g.options.dub = true
	g.show_line()
	check(g.audio.last_take == "katip_tablet" and await heard_voice(tap), "clerk waveform and cast")
	g.cmd("next")
	check(g.audio.last_take == "matilda_muhur" and await heard_voice(tap), "Matilda waveform and cast")
	check(g.lines[g.line_no][0] == "Matilda", "correct speaker after skipping")
	g.cmd("next")
	g.hero.position = g.world.loc(28., 4.7)
	g.interact()
	check(g.beat.kind == "night_pass" and g.flags.passage == "cellar", "physical choice opens cellar")
	check(not g.world.passable(g.world.loc(34.4, 4.8)), "low hatch stops upright locomotion")
	g.cmd("crouch")
	check(g.hero.crouched and g.world.passable(g.world.loc(34.4, 4.8)), "crouch clears hatch")
	check(not g.world.passable(g.world.loc(34.4, -4.8)), "other route remains locked")
	g.hero.position = g.world.loc(34.3, 4.8)
	g.checkpoint()
	g.start(true)
	check(g.world.route == "cellar" and g.hero.crouched and g.hero.position.distance_to(g.world.loc(34.3, 4.8)) < .1, "save inside hatch restores route, posture and reachable position")
	g.cmd("crouch")
	check(g.hero.crouched, "cannot stand through stone")
	g.options.dub = true
	g.audio.speak(["Dorian", "Altı boş."], g.hero, g.hero.position, true)
	check(g.audio.last_take.is_empty() and not g.audio.dialogue.playing, "unrecorded line never borrows a voice")
	g.cmd("title")
	g.start(false)
	# Check the actual light and the walls independently of animation-frame timing.
	g.enter(1)
	var w = g.world
	check(w.opaque(w.loc(15., 2.) + Vector3.UP, w.loc(15., 3.9) + Vector3.UP), "cover interrupts line of sight")
	w.reprieve = 0.
	var found = false
	for i in range(65):
		var lit = w.lantern.global_position - w.cone.global_basis.z * 1.8
		lit.y = 0.
		if w.tick_patrol(.05, lit, 0.):
			found = true
			break
	check(found, "remaining in a moving lantern beam is detected without sprinting")
	w.retry_position()
	check(w.suspicion == 0. and w.reprieve > 0., "suspicion resets at nearby cover")
	g.enter(2)
	g.hero.position = w.loc(28., -4.85)
	g.interact()
	check(w.route == "kitchen" and w.passable(w.loc(34.4, -4.8)), "kitchen is a separate standing route")
	var start = w.guard.position
	for i in range(20): w.tick_patrol(.05, g.hero.position, 0.)
	check(w.guard.position.distance_to(w.loc(27.7, -4.4)) < start.distance_to(w.loc(27.7, -4.4)), "clatter actually diverts the guard")
	g.enter(4)
	g.hero.position = w.loc(40.,.5); g.interact(); g.follow(.045)
	check(g.hero.eyeline.active and w.people.Lyra.eyeline.active,"the two listeners have height-aware eyelines")
	check(g.direction.fish_parts.size() == 2 and g.direction.fish_parts[0].get_parent() == w.people.Lyra.socket("hand_l"),"head remains in Lyra's hand")
	g.cmd("next")
	check(g.direction.fish_parts[1].get_parent() == g.hero.socket("hand_l"),"Lyander receives only the tail")
	g.enter(5)
	w.chase_started = true
	w.reprieve = 0.
	check(w.tick_patrol(.05, w.guard.position, 0.), "chaser can catch up")
	check(w.retry_position().z < -40. and w.route == "kitchen", "retry keeps route and fish")
	g.cmd("title")
	check(not g.audio.dialogue.playing and g.barks.is_empty(), "title clears pending speech")
	g.audio.dialogue.bus = &"Master"
	AudioServer.remove_bus(bus)
	g.audio.ambience.stop()
	g.audio.music.stop()
	g.queue_free()
	for i in range(12): await process_frame
	await create_timer(.4).timeout
	print("VOICE_NIGHT_SMOKE ", "PASS" if failures == 0 else "FAIL", " takes=", takes.size(), " routes=2")
	quit(int(failures > 0))

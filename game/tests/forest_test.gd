extends SceneTree
## Exercise both banks using production locomotion, including failure and a midstream save.
var g
var failures = 0


func check(ok: bool, reason: String):
	if not ok:
		push_error("Forest QA: " + reason)
		failures += 1


func _initialize(): call_deferred("run")


func step_toward(point: Vector3):
	var d = point-g.hero.position
	g.yaw = 0.; g.touch_move = Vector2(d.x,d.z).normalized()
	g.walk(.04)


func run():
	g = load("res://main.tscn").instantiate()
	root.add_child(g); await process_frame
	g.start(false); g.set_physics_process(false)
	var start = -1
	for b in g.beats:
		if b.kind == "forest_cross": start = int(b.id); break
	check(start > 0,"authored crossing")
	g.enter(start); g.cmd("close_ribbon")
	var w = g.world
	g.hero.position = w.bank(w.LOG_X,-5.5); g.hero.crouched = false
	for i in range(32): step_toward(w.bank(w.LOG_X,5.5))
	check(g.feedback.begins_with("Islak gövdede") and g.index == start, "slip returns to bank, not past the forest")
	g.crouch()
	for i in range(130):
		step_toward(w.bank(w.LOG_X,5.5))
		if w.channel(g.hero.position) > -.24: break
	check(w.crossed_by == w.LOG, "low gait engages log")
	g.checkpoint(); g.start(true); g.cmd("close_ribbon"); w = g.world
	check(w.channel(g.hero.position) < -4.25 and g.hero.crouched and g.index == start, "restart is on stable ground")
	g.crouch(); g.hero.position = w.bank(w.FORD_X,-5.3); w.water_clock = 1.5
	for i in range(75): step_toward(w.bank(w.FORD_X,5.55))
	check(g.feedback.begins_with("Su son taşın") and not g.flags.has("brook"), "visible high water can wash the last step out")
	w.water_clock = 4.5
	for i in range(140):
		step_toward(w.bank(w.FORD_X,5.3))
		if w.channel(g.hero.position) > 4.6: break
	g.touch_move = Vector2.ZERO; g._physics_process(.04)
	check(g.flags.get("brook", "") == w.FORD and g.beat.kind == "forest_ember", "actual steps cross via the ford")
	g.hero.position = w.point(g.beat.at)+Vector3.BACK*.85; g.interact()
	check(g.mode == "explore", "wet wood is not tinder")
	g.hero.position = w.point(g.beat.at)+Vector3.FORWARD*.85; g.interact()
	check(g.mode == "dialog" and g.lines[0][0] == "Değirmenci", "occupied hearth and useful dry wood")
	while g.mode == "dialog": g.cmd("next")
	g.hero.position = w.point(g.beat.at); g.interact()
	check(g.lines[0][0] == "Lyander" and "Taşın üstünde" in g.lines[0][1], "route recalled before the family conversation")
	while g.mode == "dialog" and not g.direction.remembering: g.cmd("next")
	check(g.direction.remembering and g.direction.orfen.title == "Orfen" and not g.direction.shot().is_empty(), "Orfen appears only in Aldric's account")
	g.cmd("next")
	check(not g.direction.remembering and not g.direction.memory.visible, "cut returns to the same hearth after skipping")
	var at = w.point([80.,7.]); w.frame(.05,at)
	var villager = w.locals[0].actor
	check(is_instance_valid(villager) and villager.visible, "water carrier present near the workshops")
	var old = villager.position
	for i in range(42): w.frame(.1,at)
	check(old.distance_to(villager.position) > .75 and w.locals[0].carry.visible, "load carried between two work sites")
	w.frame(.1,w.loc(-64.,0.))
	check(not villager.visible and not villager.animator.active,"distant workers culled")
	for b in g.beats:
		if int(b.zone) == 4 and b.model == "Aldric" and b.kind == "talk":
			g.enter(int(b.id)); break
	g.cmd("close_ribbon"); g.hero.position = g.world.point(g.beat.at)+Vector3.BACK*.98; g.interact()
	var blocking = g.direction
	check(blocking.meal_time == 0. and blocking.platter.get_parent() == blocking.edda.socket("hand_l"),"Edda brings her plate in her hand")
	for i in range(81): blocking.tick(.05)
	check(blocking.edda.position.distance_to(blocking.table)>1. and blocking.platter.position.distance_to(blocking.tray_rest)<.035,"plate on table while Edda leaves")
	g.cmd("title"); g.audio.fire.stop(); g.audio.quiet(); g.audio.ambience.stop(); g.audio.music.stop()
	g.queue_free(); g = null
	for i in range(12): await process_frame
	await create_timer(.35).timeout
	print("FOREST_SMOKE ", "PASS" if failures == 0 else "FAIL", " routes=2")
	quit(int(failures > 0))

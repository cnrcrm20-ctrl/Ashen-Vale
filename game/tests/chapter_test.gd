extends SceneTree
## Accelerated end-to-end state/input test. Not a measurement of human playtime.
var g
var steps = 0
var failed = false
var grid: AStarGrid2D
var nav_zone = -1
var walk_s = 0.
var walk_m = 0.
var read_words = 0
var tested_retry = false
var saved_clue = false
var saved_course = false
var trail_seconds = 0.


func _initialize():
	call_deferred("run")


func check(ok: bool, reason: String):
	if not ok:
		push_error("TEST: " + reason)
		failed = true


func run():
	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_physics_process(false)
	check(g.mode == "title", "title boot")
	g.cmd("new")
	g.cmd("close_ribbon")
	g.checkpoint()
	g.start(true)
	check(g.index == 0, "saved chapter resumes")
	g.cmd("close_ribbon")
	var encountered = {}
	var quality = g.options.high
	var ev = InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_START
	ev.pressed = true
	g._input(ev)
	check(g.mode == "pause", "controller pause")
	g.cmd("settings")
	g.cmd("quality")
	g.cmd("quality")
	check(quality == g.options.high, "settings")
	g.cmd("settings_back")
	g.cmd("resume")
	while not g.completed and steps < 2200 and not failed:
		steps += 1
		encountered[g.beat.kind] = true
		match g.mode:
			"crossing":
				for i in range(70):
					g._physics_process(.05)
			"ribbon":
				g.cmd("close_ribbon")
			"explore":
				if g.trail:
					for i in range(1700):
						if not g.trail:
							break
						var guide = g.world.people["Tamar"].position
						var diff = guide - g.hero.position
						g.touch_move = (
							Vector2(diff.x, diff.z).normalized()
							if diff.length() > 3.
							else Vector2.ZERO
						)
						g._physics_process(.05)
						trail_seconds += .05
					g.touch_move = Vector2.ZERO
					check(not g.trail, "follow Tamar on foot")
				elif g.vaulting:
					for i in range(25):
						g._physics_process(.05)
				else:
					var dest = g.terrain_target()
					walk_to(dest, 2.45)
					g.nearby_note = -1
					if g.round_no >= 0 and g.beat.kind == "paired":
						g.hero.heading = atan2(
							dest.x - g.hero.position.x, dest.z - g.hero.position.z
						)
						g.selected = int(g.current_stop().spell)
						g.course_wave = .8
						g.cooldown = 0
						g.cast()
					else:
						g.interact()
			"chart":
				var board = g.ui.board
				board.submit()
				check(g.mode == "chart", "unsolved route cannot submit")
				for k in board.route:
					if k == board.route[0] or k == board.route[-1]:
						continue
					board.cursor = k
					while board.turns[k] % 4 != 0:
						board.turn_tile()
				board.submit()
			"dialog":
				read_words += words(str(g.lines[g.line_no][1]))
				if g.mask == 1 and not saved_clue and g.beat.kind == "search":
					saved_clue = true
					g.checkpoint()
					g.start(true)
					g.cmd("close_ribbon")
					check(g.mask == 1, "partial evidence restored")
				elif g.beat.kind == "paired" and g.round_no == 1 and not saved_course:
					saved_course = true
					g.checkpoint()
					g.start(true)
					check(
						g.round_no == 1 and g.learned.size() == 4,
						"field checkpoint and spells restored"
					)
				else:
					g.cmd("next")
			"choice":
				read_words += words(g.ask.q)
				for opt in g.ask.options:
					read_words += words(opt[0])
				if not tested_retry and int(g.ask.correct) >= 0:
					tested_retry = true
					g.choose((int(g.ask.correct) + 1) % g.ask.options.size())
					check(g.after == "retry", "incorrect conclusion can be retried")
				else:
					g.choose(maxi(0, int(g.ask.correct)))
			"ritual":
				var r = g.ui.ritual
				if r.done or r.result_time > 0:
					r._process(.9)
				elif r.kind == "water":
					if r.sampled.has(false):
						r.selection = r.sampled.find(false)
						r.press()
						r._process(.95)
					else:
						r.selection = r.goal
						r.press()
				elif r.kind in ["guard", "dodge"]:
					for i in range(140):
						if r.phase > .72 and r.phase < .89:
							break
						r._process(.034)
					r.press()
				else:
					if r.kind == "wick":
						r.selection = r.goal
					else:
						var target = -.52 if r.goal == 0 else .52
						for i in range(20):
							if absf(r.aim - target) < .08:
								break
							r.adjust(1 if target > r.aim else -1)
					r.press()
					r._process(.64)
					r.released()
					if r.flight >= 0:
						r._process(.75)
			_:
				check(false, "unexpected state: " + g.mode)
		if steps % 12 == 0:
			await process_frame
	check(g.completed, "chapter reaches ending: " + str(g.index) + " / " + g.mode)
	check(g.learned.size() == 4, "four learned spells")
	check(g.archive.spells.size() == 34, "full codex")
	check(g.records.size() == g.beats.size(), "all beats checkpointed")
	check(g.slot_done(), "completed save readable")
	check(g.zones.size() == 7, "seven districts")
	check(tested_retry and saved_clue and saved_course, "retry and save scenarios covered")
	print(
		"PACE_MODEL route_m=",
		roundi(walk_m),
		" locomotion_s=",
		roundi(walk_s + trail_seconds),
		" mandatory_visible_words=",
		read_words,
		" minutes_at_180wpm_plus_walk=",
		snappedf((walk_s + trail_seconds) / 60. + read_words / 180., .1),
		" (modeled; excludes thinking, tablet/ritual time, optional notes; not a human timing)"
	)
	print(
		"CHAPTER_SMOKE ",
		"FAIL" if failed else "PASS",
		" steps=",
		steps,
		" beats=",
		g.records.size(),
		" mechanics=",
		encountered.keys()
	)
	g.audio.music.stop()
	for stream in g.audio.pool:
		stream.stop()
	g.queue_free()
	g = null
	for i in range(12):
		await process_frame
	await create_timer(.35).timeout
	quit(1 if failed else 0)


# Find a walkable grid route and drive the production analogue locomotion along it.
# The runner advances simulation ticks without sleeping; reading time is a separate model.
func navmesh():
	if nav_zone == g.zone:
		return
	nav_zone = g.zone
	grid = AStarGrid2D.new()
	var depth = ceili(g.world.length) + 18
	grid.region = Rect2i(-49, -depth, 100, depth + 14)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(grid.region.position.x, grid.region.end.x):
		for z in range(grid.region.position.y, grid.region.end.y):
			if not g.world.passable(Vector3(x, 0, z)):
				grid.set_point_solid(Vector2i(x, z), true)


func snap(p: Vector3) -> Vector2i:
	var at = Vector2i(roundi(p.x), roundi(p.z))
	var best = INF
	var found = at
	for x in range(-3, 4):
		for z in range(-3, 4):
			var i = at + Vector2i(x, z)
			var ds = Vector2(i).distance_squared_to(Vector2(p.x, p.z))
			if ds < best and grid.is_in_boundsv(i) and not grid.is_point_solid(i):
				best = ds
				found = i
	return found


func walk_to(p: Vector3, reach: float):
	navmesh()
	var begin = g.hero.position
	var nodes = grid.get_id_path(snap(begin), snap(p))
	var cid = 0
	var ticks = 0
	while g.hero.position.distance_to(p) > reach and ticks < 3700:
		var h = g.hero.position
		var target = Vector2(p.x, p.z)
		while cid < nodes.size() and Vector2(nodes[cid]).distance_to(Vector2(h.x, h.z)) < .65:
			cid += 1
		if cid < nodes.size():
			target = Vector2(nodes[cid])
		var wish = target - Vector2(h.x, h.z)
		g.touch_move = wish.limit_length(1.) if wish.length() < .7 else wish.normalized()
		g.yaw = 0
		g.walk(.05)
		ticks += 1
		walk_m += h.distance_to(g.hero.position)
	g.touch_move = Vector2.ZERO
	g.velocity = Vector3.ZERO
	walk_s += float(ticks) * .05
	check(
		ticks < 3700,
		(
			"walkable approach: "
			+ str(g.index)
			+ " round="
			+ str(g.round_no)
			+ " from="
			+ str(begin)
			+ " to="
			+ str(p)
			+ " at="
			+ str(g.hero.position)
		)
	)


func words(t: String) -> int:
	return t.split(" ", false).size()

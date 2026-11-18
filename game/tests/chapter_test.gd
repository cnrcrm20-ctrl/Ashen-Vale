extends SceneTree
## Accelerated end-to-end state/input test. Not a measurement of human playtime.
var g
var steps = 0
var failed = false


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
	g.pause_game()
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
			"ribbon":
				g.cmd("close_ribbon")
			"explore":
				if g.trail:
					for i in range(1700):
						if not g.trail:
							break
						g.hero.position = g.world.people["Tamar"].position + Vector3.BACK * 2
						g._physics_process(.05)
				elif g.vaulting:
					for i in range(25):
						g._physics_process(.05)
				else:
					var dest = g.terrain_target()
					g.hero.position = dest + Vector3.BACK * .8
					g.nearby_note = -1
					g.interact()
			"dialog":
				g.cmd("next")
			"choice":
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
	quit(1 if failed else 0)

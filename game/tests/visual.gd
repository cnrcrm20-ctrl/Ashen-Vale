extends SceneTree


func _initialize():
	call_deferred("run")


func run():
	var g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	var path = OS.get_environment("SHOT_DIR")
	for j in [-1, 0, 2, 4, 6]:
		if j >= 0:
			if j == 0:
				g.start(false)
			else:
				for b in g.beats:
					if int(b.zone) == j:
						g.enter(int(b.id))
						break
			g.cmd("close_ribbon")
			g.hero.position = g.world.loc(8, 0)
		for i in range(18):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path + "/scene-" + str(j) + ".png")
	print("VISUAL_SMOKE PASS")
	quit()

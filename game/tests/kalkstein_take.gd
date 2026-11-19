extends SceneTree
## Record one uninterrupted exchange with Godot Movie Maker. Only stage the
## starting marks; the production camera, line timer, animation and mixer run.
## Use an isolated XDG_DATA_HOME (this creates a new save).
var g


func _initialize(): call_deferred("take")


func take():
	if Engine.get_write_movie_path().is_empty():
		push_error("Use --write-movie /absolute/path/take.avi --fixed-fps 24"); quit(1); return
	g = load("res://main.tscn").instantiate(); root.add_child(g)
	g.options.dub = true; g.start(false)
	var lyra = g.world.people.Lyra
	g.hero.position = g.world.loc(7.03,-1.13)
	g.hero.face(lyra.position); g.hero.rotation.y = g.hero.heading
	lyra.face(g.hero.position); lyra.rotation.y = lyra.heading
	g.interact()
	if g.audio.last_take != "lyra_zeytin": quit(1); return
	print("TAKE_BEGIN frame=",Engine.get_frames_drawn())
	var reply = false
	for i in range(420):
		await process_frame
		reply = reply or g.audio.last_take == "lyander_iskele"
		if g.beat.kind == "night_hear": break
	var done = reply and g.beat.kind == "night_hear"
	print("TAKE_END frame=",Engine.get_frames_drawn()," both_lines=",done)
	g.audio.quiet(); g.audio.music.stop(); g.audio.ambience.stop(); g.audio.fire.stop()
	for stream in g.audio.pool + g.audio.spatial: stream.stop()
	g.queue_free(); g = null
	for i in range(4): await process_frame
	quit(int(not done))

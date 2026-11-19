extends SceneTree
## Photograph actual scenes. Reject flat world pixels even if a legible HUD masks them.
var g
var folder = OS.get_environment("SHOT_DIR")
var failed = false


func _initialize(): call_deferred("run")


func photo(id: String):
	await process_frame
	if RenderingServer.render_loop_enabled:
		await RenderingServer.frame_post_draw
	else:
		# The CPU-only CI runner need not draw the staging/cleanup ticks. Warm
		# the real viewport, then draw/read the actual posed frame at full size.
		RenderingServer.force_draw(true, 1. / 24.)
		await process_frame
		RenderingServer.force_draw(true, 1. / 24.)
	var img = root.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("No rendered viewport for " + id); failed = true; return
	var name_ = folder.path_join("scene-%s.png" % id)
	if img.save_png(name_) != OK:
		push_error("Could not save " + name_); failed = true
	var lo = 1.; var hi = 0.; var total = 0.; var squares = 0.; var n = 0
	for y in range(5,19):
		for x in range(4,29):
			var l = img.get_pixel(img.get_width()*x/32,img.get_height()*y/26).get_luminance()
			lo = minf(lo,l); hi = maxf(hi,l); total += l; squares += l*l; n += 1
	var spread = sqrt(maxf(0., squares/n - pow(total/n,2)))
	print("FRAME ",id," ",img.get_size()," world_luma_range=",snappedf(hi-lo,.001)," sigma=",snappedf(spread,.001))
	if spread < .016 or hi-lo < .095:
		failed = true; push_error("Blank world pixels: " + id)


func settle():
	g.camera_ready = false
	for i in range(4):
		g._physics_process(.045)
		await process_frame
	# Sample the same animation/attachment state that was submitted for this shot.
	g.follow(.045)


func at(kind: String, area: int, model = ""):
	for b in g.beats:
		if b.kind == kind and int(b.zone) == area and (model == "" or b.model == model):
			g.enter(int(b.id)); g.cmd("close_ribbon"); return
	push_error("Unknown scene: " + kind); failed = true


func type_check():
	var title = TextLine.new()
	title.add_string("ASHEN VALE",preload("res://fonts/display.ttf"),80)
	for glyph in TextServerManager.get_primary_interface().shaped_text_get_glyphs(title.get_rid()):
		if glyph.advance < 0.:
			failed = true; push_error("Backward glyph in the title: check the text driver's kerning units")


func check_service_frame():
	# A nonblank shot once passed with all of Edda behind Aldric; then with the
	# plate behind the subtitle box. Check the actual projected marks as well.
	var edda = g.direction.edda
	var size_ = root.get_visible_rect().size
	for target in [edda.gaze_point(), g.direction.platter.global_position]:
		var uv = g.camera.unproject_position(target) / size_
		if g.camera.is_position_behind(target) or not Rect2(.06,.042,.88,.617).has_point(uv):
			failed = true; push_error("Face or plate outside the usable frame: %s" % uv)
		for actor_ in [g.hero, g.world.people.Aldric]:
			for pole in [actor_.gaze_point(), actor_.position + Vector3.UP * .95]:
				var cut = Geometry3D.get_closest_point_to_segment(pole, target, g.camera.global_position)
				if cut.distance_to(pole) < .30:
					failed = true; push_error("Bystander masks the serving window: " + actor_.title)


func talk():
	g.hero.position = g.world.point(g.beat.at) + Vector3(.13,0,1.14)
	g.interact(); await settle()
	if g.mode != "dialog": failed = true; push_error("The staged exchange was not reachable")


func run():
	if folder == "" or DirAccess.make_dir_recursive_absolute(folder) != OK:
		push_error("Set SHOT_DIR to a writable directory"); quit(1); return
	g = load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame
	g.set_physics_process(false)
	type_check()
	await photo("-1")
	g.start(false); await settle(); await photo("0")
	g.hero.position = g.world.loc(7.3,-1.02); g.interact(); await settle()
	await photo("0-lyra")
	at("night_hear",0); await talk(); g.cmd("next"); await settle(); await photo("0-matilda")
	at("surge",1); await talk(); g.cmd("next"); await settle(); await photo("1-kol")
	at("forest_cross",2)
	g.hero.position = g.world.bank(g.world.LOG_X,-7.4); await settle(); await photo("2")
	at("talk",2,"shelter"); await talk()
	for line in g.beat.lines:
		if g.direction.remembering: break
		g.cmd("next")
	if not g.direction.remembering: failed = true; push_error("Expected Aldric's recollection")
	await settle(); await photo("2-orfen")
	at("witness",2)
	g.hero.position = g.world.loc(96.,5.); g.yaw = -.4; await settle(); await photo("2-avlu")
	at("search",4); g.hero.position = g.world.loc(12.,1.4); await settle(); await photo("4")
	at("talk",4,"Aldric"); await talk()
	for i in range(14): g._physics_process(.05)
	await settle(); check_service_frame(); await photo("4-edda")
	at("look",6); g.hero.position = g.world.point(g.beat.at)+Vector3(2.1,0,4.6); await settle(); await photo("6")
	g.audio.quiet(); g.audio.fire.stop(); g.audio.ambience.stop(); g.audio.music.stop()
	for stream in g.audio.pool + g.audio.spatial: stream.stop()
	g.queue_free(); g = null
	for i in range(12): await process_frame
	await create_timer(.35).timeout
	print("VISUAL_SMOKE ", "FAIL" if failed else "PASS")
	quit(int(failed))

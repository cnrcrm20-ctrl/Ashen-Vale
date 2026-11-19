extends Node3D
## Short, interruptible pieces of blocking. Nothing in a recollection changes the present.
const Actor = preload("res://scripts/actor.gd")
const Surfaces = preload("res://scripts/surfaces.gd")
var world
var memory: Node3D
var echo_env: Environment
var orfen
var remembering = false
var memory_time = 0.
var wrist: Node3D
var wrist_time = -1.
var meal_time = -1.
var edda
var platter: MeshInstance3D
var table: Vector3
var departure: Vector3
var tray_rest: Vector3
var service_rail: Vector3
var fish_parts: Array = []


func reset():
	if remembering and is_instance_valid(world): world.sun.show()
	remembering = false; wrist = null; wrist_time = -1.
	if is_instance_valid(memory): memory.hide()
	if is_instance_valid(edda):
		world.directed.erase(edda)
		edda.position = departure
	if is_instance_valid(platter): platter.queue_free()
	platter = null; edda = null; meal_time = -1.
	for part in fish_parts:
		if is_instance_valid(part): part.queue_free()
	fish_parts.clear()


func prop(parent: Node3D, id: String, at: Vector3, size_: float) -> MeshInstance3D:
	var m = MeshInstance3D.new(); m.mesh = world.set_mesh(id)
	parent.add_child(m); m.position = at; m.scale = Vector3.ONE * size_
	return m


func stonework(parent: Node3D, pos: Vector3, size_: Vector3, material: Material):
	var block = MeshInstance3D.new(); var box = BoxMesh.new(); box.size = size_
	block.mesh = box; block.material_override = material; parent.add_child(block); block.position = pos


func make_memory():
	memory = Node3D.new(); add_child(memory); memory.position = Vector3(0,-145,0)
	var floor_ = MeshInstance3D.new(); var slab = BoxMesh.new(); slab.size = Vector3(9,.22,9)
	floor_.mesh = slab; floor_.material_override = Surfaces.get_material("cobble",1.8)
	memory.add_child(floor_); floor_.position.y = -.11
	prop(memory,"bay_cl_arch",Vector3(0,0,-1.1),.65)
	var timber = Surfaces.get_material("boards",1.07)
	var stone = Surfaces.get_material("masonry",1.70)
	var leaf = prop(memory,"door_leaf",Vector3(0,0,-1.03),1.28); leaf.material_override = timber
	for x in [-2.83,2.83]: stonework(memory,Vector3(x,1.8,-1.21),Vector3(3.75,3.6,.45),stone)
	stonework(memory,Vector3(0,3.65,-.48),Vector3(8,.34,4.9),timber)
	for y in [.46,2.52]: stonework(memory,Vector3(0,y,-.87),Vector3(1.87,.09,.06),world.material("#55514a"))
	echo_env = Environment.new(); echo_env.background_mode = Environment.BG_COLOR
	echo_env.background_color = Color("2b302e"); echo_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	echo_env.ambient_light_color = Color("9da7ad"); echo_env.ambient_light_energy = .45
	echo_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	prop(memory,"lamp_lantern",Vector3(-1.28,1.73,-.92),.75)
	var lamp = OmniLight3D.new(); memory.add_child(lamp); lamp.position = Vector3(-1.22,1.79,.24)
	lamp.light_color = Color("ffca9c"); lamp.light_energy = 1.62; lamp.omni_range = 6.9
	orfen = Actor.new(); memory.add_child(orfen); orfen.make("Orfen")
	orfen.position = Vector3(.34,0,-.15); orfen.rotation.y = -.22; orfen.heading = orfen.rotation.y
	prop(memory,"keyring",Vector3(-.73,.69,-.39),1.3)
	prop(memory,"bedside",Vector3(-.74,0,-.43),.96)


func fish(tail: bool, owner_: Node3D) -> MeshInstance3D:
	# Thumb-sized fired clay. The same irregular section closes both broken edges.
	var rings = [[-.064,.003,.006],[-.058,.013,.016],[-.039,.020,.028],[-.012,.023,.035],[.008,.019,.029]]
	if tail: rings = [[.008,.019,.029],[.031,.011,.016],[.044,.008,.010],[.071,.006,.026],[.077,.003,.023]]
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var paths = []
	for r in rings:
		var ring_ = []
		for j in range(12):
			var a = j * TAU / 12.
			ring_.append(Vector3(r[0]+(.002*sin(a*3.) if r[0] == .008 else 0.),sin(a)*r[2],cos(a)*r[1]))
		paths.append(ring_)
	for i in range(paths.size()-1):
		for j in range(12):
			var k = (j+1)%12
			for v in [paths[i][j],paths[i+1][k],paths[i+1][j],paths[i][j],paths[i][k],paths[i+1][k]]: st.add_vertex(v)
	for i in [0,paths.size()-1]:
		for j in range(1,11):
			for k in [0,j,j+1]: st.add_vertex(paths[i][k])
	st.generate_normals()
	var piece = MeshInstance3D.new(); piece.mesh = st.commit(); piece.material_override = world.material("#ad6a4d")
	owner_.add_child(piece); piece.position = Vector3(0,.043,.016)
	fish_parts.append(piece); return piece


func on_line(b: Dictionary, speaker: String, text: String, hero):
	remembering = b.model == "shelter" and speaker == "Aldric" and text.begins_with("Orfen,")
	if remembering and not is_instance_valid(memory): make_memory()
	if is_instance_valid(memory):
		memory.visible = remembering; world.sun.visible = not remembering
		if remembering:
			memory_time = 0.; orfen.crouched = false; orfen.gesture("Idle_No",1.25)
	wrist = hero if b.model == "mark" and speaker == "Aldric" else null
	wrist_time = 0. if is_instance_valid(wrist) else -1.
	if b.kind == "night_fish":
		if fish_parts.is_empty():
			fish(false,world.people.Lyra.socket("hand_l")); fish(true,world.people.Lyra.socket("hand_r"))
		if speaker == "Lyander":
			fish_parts[1].reparent(hero.socket("hand_l"),false)
			hero.gesture("Interact",1.1)
	if world.zone == 4 and b.model == "Aldric" and text.begins_with("Hagen de") and meal_time < 0.:
		var anchor = world.point(b.at)
		table = anchor + Vector3(1.53,0,-1.67); table.y = world.altitude(table.x,table.z)
		edda = world.person_on_set("Edda",table); edda.heading = -.55; edda.rotation.y = edda.heading
		world.directed.append(edda)
		tray_rest = anchor + Vector3(1.44,.676,-.94)
		platter = prop(edda.socket("hand_l"),"plate",Vector3(0,.07,.08),1.10)
		service_rail = clear_service_angle(hero, world.people.Aldric)
		departure = table + Vector3(3.8,0,-2.7); departure.y = world.altitude(departure.x,departure.z)
		edda.gesture("PickUp_Table",1.65); meal_time = 0.


func clear_service_angle(hero, aldric) -> Vector3:
	# The player can start from either side of Aldric. Pick once, otherwise the
	# cut can oscillate as Edda bends. Check the tray as well as her face.
	var eye = edda.gaze_point()
	var clearest = -INF
	var best = table
	var offsets = [Vector3(1.04,1.46,1.89), Vector3(-1.04,1.46,1.75), Vector3(1.71,1.43,.95)]
	for offset in offsets:
		var candidate = world.camera_safe(eye, table + offset)
		var clearance = candidate.distance_to(eye)
		for bystander in [hero, aldric]:
			for pole in [bystander.gaze_point(), bystander.position + Vector3.UP * .95]:
				for target in [eye, tray_rest]:
					var cut = Geometry3D.get_closest_point_to_segment(pole, target, candidate)
					clearance = minf(clearance, pole.distance_to(cut))
		if clearance > clearest:
			clearest = clearance
			best = candidate
	return best


func tick(dt: float):
	if wrist_time >= 0.: wrist_time += dt
	if remembering:
		memory_time += dt
		orfen.crouched = memory_time >= 1.25
		orfen.motion(0.,Vector3.ZERO,dt)
	if meal_time < 0.: return
	meal_time += dt
	if meal_time >= .38 and platter.get_parent() != self:
		platter.reparent(self,true)
	if meal_time <= 1.7:
		if platter.get_parent() == self:
			platter.position = platter.position.lerp(tray_rest,1.-exp(-dt*6.8))
			platter.rotation = platter.rotation.lerp(Vector3.ZERO,1.-exp(-dt*6.8))
		edda.motion(0.,Vector3.ZERO,dt)
	else:
		var prev = edda.position
		edda.position = edda.position.move_toward(departure,dt*1.23)
		edda.motion(prev.distance_to(edda.position)/dt,(edda.position-prev).normalized(),dt)


func shot() -> Array:
	if remembering:
		var eye = orfen.gaze_point()
		return [eye + Vector3(-.73,.11,1.52), eye - Vector3.UP*.15, 45.]
	if is_instance_valid(wrist) and wrist_time < 1.48:
		var pose = wrist.mark_pose(); var p = pose.origin
		var outward = -wrist.global_basis.x.normalized()
		return [p + pose.basis.z.normalized()*.33 + outward*.19 + Vector3.UP*.045, p, 39.]
	if meal_time >= .32 and meal_time <= 3.10:
		return [service_rail, edda.gaze_point().lerp(tray_rest, .78), 54.]
	return []

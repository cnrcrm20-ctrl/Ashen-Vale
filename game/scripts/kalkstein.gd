extends "res://scripts/world.gd"
## Authored in metres. Depth increases towards the market; x<0 is the kitchen.
## Sight, camera and locomotion all read the same opaque set, not a painted trigger circle.
const KITCHEN = "kitchen"
const CELLAR = "cellar"
const SWITCH_DEPTH = 28.
const LATCH_X = 4.8
var solids: Array[AABB] = []
var doors = {}
var guard
var lantern: Node3D
var cone: SpotLight3D
var stage_id = ""
var route = ""
var ducking = false
var suspicion = 0.
var reprieve = 0.
var patrol_time = 0.
var step_clock = 0.
var chase_gap = 0.
var heard = false
var in_light = false
var chase_started = false
var clatter: Node3D
var rain: CPUParticles3D


func center(_d: float) -> float:
	return 0.


func altitude(_x: float, _z: float) -> float:
	return 0.


func box_at(p: Vector3, size_: Vector3, mat: Material, solid = false) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size_
	node.mesh = box
	node.material_override = mat
	node.position = p
	add_child(node)
	if solid:
		solids.append(AABB(p - size_ * .5, size_))
		if size_.length() > 4.: occluder(p,size_*.98)
	return node


func wall(x: float, depth: float, width: float, long_: float, height = 3.6, surface = "masonry"):
	box_at(Vector3(x, height * .5, -depth), Vector3(width, height, long_), Surfaces.get_material(surface), true)


func opaque(from: Vector3, to: Vector3) -> bool:
	for bounds in solids:
		if bounds.intersects_segment(from, to) != null:
			return true
	return false


func camera_safe(focus: Vector3, desired: Vector3) -> Vector3:
	var travel = desired - focus
	var dist = travel.length()
	var nearest = dist
	for bounds in solids:
		var hit = bounds.grow(.09).intersects_segment(focus, desired)
		if hit != null:
			nearest = minf(nearest, maxf(.18, focus.distance_to(hit) - .10))
	return focus + travel.normalized() * nearest


func passable(p: Vector3) -> bool:
	var d = -p.z
	if d < -3.4 or d > 64.4:
		return false
	var span = 5.25 if d < 11. else (3.93 if d < 24. else (6.7 if d < 39. else 5.6))
	if absf(p.x) > span:
		return false
	if d > 31.6 and d < 38.5:
		if route == "" or ((p.x < 0) != (route == KITCHEN)):
			return false
		if route == CELLAR and d > 33.5 and d < 35.3 and not ducking:
			return false
	# The cart wall is only crossed by the vault, not by walking through the mesh.
	if d > 51.75 and d < 52.7:
		return false
	for bounds in solids:
		if bounds.position.y > 1.18 or bounds.end.y < .16:
			continue
		if p.x > bounds.position.x - .25 and p.x < bounds.end.x + .25 and p.z > bounds.position.z - .25 and p.z < bounds.end.z + .25:
			return false
	return true


func glow(at: Vector3, tint: Color, strength: float, radius: float) -> OmniLight3D:
	var light = OmniLight3D.new()
	light.light_color = tint
	light.light_energy = strength
	light.omni_range = radius
	light.position = at
	add_child(light)
	return light


func lamp(x: float, d: float, y: float, turn: float):
	var pos = Vector3(x, y, -d)
	furnish("lamp_lantern", pos, .8, turn)
	glow(pos + Vector3(sin(turn), 0, cos(turn)) * .53, Color("ffba73"), 1.65, 5.6)


func setup(index: int, beats: Array, quality: bool):
	zone = index
	high = quality
	length = 65.
	rng.seed = 1313
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("17212f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("94a3b4")
	env.ambient_light_energy = .37
	env.ambient_light_sky_contribution = 0.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = .84
	env.fog_enabled = true
	env.fog_density = .014
	env.fog_light_color = Color("37475b")
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("aac9ed")
	sun.light_energy = .21
	sun.rotation_degrees = Vector3(-42, -32, 0)
	sun.shadow_enabled = high
	sun.directional_shadow_max_distance = 46.
	add_child(sun)
	if RenderingServer.get_current_rendering_method() == "forward_plus" and high:
		env.ssao_enabled = true
		env.glow_enabled = true
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = .013
	var boards = Surfaces.get_material("boards", 1.8)
	box_at(Vector3(0, -.11, -3.45), Vector3(11.2, .22, 15.1), boards)
	box_at(Vector3(0, -.12, -37.5), Vector3(14.6, .24, 53.8), Surfaces.get_material("cobble", 2.3))
	wall(0, -4, 11.2, .4)
	wall(0, 64.8, 12.1, .5)
	for side in [-1., 1.]:
		# Two narrow, genuinely open mullioned windows. Stone sill, timber head,
		# blue exterior and nearby trees; they read differently from the lamp side.
		for span in [[-4.2,-.3],[1.18,5.08],[6.56,11.]]:
			wall(side*5.6,(span[0]+span[1])*.5,.44,span[1]-span[0],3.6,"lime")
		for sill in [.44,5.82]:
			wall(side*5.6,sill,.50,1.48,1.19,"masonry")
			box_at(Vector3(side*5.6,3.22,-sill),Vector3(.5,.76,1.48),Surfaces.get_material("lime"),true)
			box_at(Vector3(side*5.59,1.24,-sill),Vector3(.76,.13,1.67),boards)
			for mullion in [-.57,0.,.57]:
				box_at(Vector3(side*5.6,2.03,-sill+mullion),Vector3(.10,1.64,.07),boards)
			box_at(Vector3(side*5.6,2.18,-sill),Vector3(.12,.075,1.48),boards)
			tree(loc(sill-3.,side*15.2),7.1,true)
		wall(side * 3.6, 10.9, 4.15, .47)
		wall(side * 4.25, 17.5, .43, 13.25)
		wall(side * 5.6, 24., 2.8, .42)
		wall(side * 7.06, 31.6, .47, 15.9)
		wall(side * 6., 52., .50, 26., 2.05)
		for row in range(3):
			var bed = loc(.8 + row * 3.45, side * 4.0)
			furnish("bed_pallet" if row == 0 else ("bunk" if row == 2 and side > 0 else "bed"), bed, .96, side * PI * .5)
			solids.append(AABB(bed - Vector3(1.06, 0, .53), Vector3(2.12, .66, 1.06)))
			furnish("bedside", bed + Vector3(.05 * side, 0, .96), .78, side * PI * .5)
		for d in [0., 5., 10.5, 15., 20., 24.]:
			var col = (5.28 if d < 10.6 else 3.97) * side
			box_at(Vector3(col, 1.82, -d), Vector3(.20, 3.65, .26), boards)
		for d in [14.8, 20.1]:
			var pp = loc(d, side * 3.12)
			furnish("crate_stack", pp, .92, side * .14)
			solids.append(AABB(pp - Vector3(.80, 0, .56), Vector3(1.60, 1.56, 1.12)))
		for d in [43., 53., 63.]:
			scenery("lodge_shell" if d != 53. else "inn_shell", loc(d, side * 12.), 10. + d * .025, side * PI * .5)
	for d in [-2., 2., 6., 10., 14., 18., 22., 26., 31.]:
		box_at(Vector3(0, 3.48, -d), Vector3(11.3 if d < 11 else 8.5, .24, .25), boards)
	box_at(Vector3(0, 3.89, -15.1), Vector3(14.2, .24, 38.), boards, true)
	# Linen, tableware, the seal and the two exits have distinct silhouettes in the dark.
	furnish("chest",loc(1.15,-4.78),.78,-PI*.49)
	furnish("sack_tied",loc(4.9,4.54),.71,.31)
	furnish("pot",loc(6.4,4.95),.51,.22)
	furnish("bench", loc(7.6, -4.9), .79, PI * .5)
	furnish("plate", loc(7.6, -4.9) + Vector3.UP * .39, 1.2)
	# Two remained in his bowl. Lyra kept the third; don't duplicate it.
	for i in range(2):
		put("leaf", "#504c36", loc(7.6, -4.9) + Vector3(-.038 + .067 * i, .392, .035 if i == 1 else -.02), Vector3(.039,.033,.045))
	furnish("table_laid", loc(22.55, -3.2), .90, PI * .5)
	furnish("candle_cluster", loc(22.6, -3.3) + Vector3.UP * .73)
	wall(0, 31.35, .58, 12.25, 3.45)
	furnish("table_trestle", loc(28.5, -5.95), 1., PI * .5)
	furnish("shelf_tall", loc(26.7, -6.18), .9, PI * .5)
	clatter = MeshInstance3D.new()
	clatter.mesh = set_mesh("pan")
	clatter.position = loc(SWITCH_DEPTH, -5.7) + Vector3.UP * 1.34
	clatter.rotation.z = -1.3
	add_child(clatter)
	furnish("cupboard", loc(26.4, -6.2), .87, PI * .5)
	furnish("keyring", loc(SWITCH_DEPTH, LATCH_X) + Vector3.UP * .66, 1.7)
	furnish("bedside", loc(SWITCH_DEPTH, LATCH_X), .96)
	for d in [25.9, 30.2, 36.1]:
		furnish("cask_stack", loc(d, 5.98), .82, .18)
		furnish("jar_storage", loc(d + 1, -6.35), .9)
	for side in [-1., 1.]:
		wall(side * 1.70, 34.4, 3., .5)
		wall(side * 6.48, 34.4, 1.35, .5)
		var key = KITCHEN if side < 0 else CELLAR
		var pivot = Node3D.new()
		pivot.position = loc(34.4, side * 3.2)
		add_child(pivot)
		var leaf = MeshInstance3D.new()
		leaf.mesh = set_mesh("door_leaf")
		leaf.scale = Vector3(1.79, .52 if side > 0 else 1., 1.)
		leaf.position.x = 1.32 * side
		pivot.add_child(leaf)
		doors[key] = pivot
	box_at(Vector3(LATCH_X, 2.28, -34.4), Vector3(2.72, 1.92, 1.9), Surfaces.get_material("masonry"), true)
	furnish("sack_tied", loc(33.7, 6.13), 1.15)
	furnish("court_fountain", loc(41, -2.95), .42)
	furnish("ivy", loc(46., -5.68), 1.1, PI * .5)
	furnish("bench_stone", loc(41.4, 2.75), .9, .3)
	for side in [-1., 1.]:
		wall(side * 3.67, 52.3, 4.7, .68, 1.14)
	wall(0, 52.3, 2.65, .72, .64)
	furnish("market_stall_a", loc(62.9, -2.9), 1.03, .38)
	furnish("banner_sheaf", loc(62., .6), .9)
	for d in [40., 48., 59.]:
		tree(loc(d, 8.), 7. + d * .018)
	lamp(-5.24, 6.8, 1.98, PI / 2)
	lamp(-3.94, 22.9, 2.14, PI / 2)
	lamp(-6.76, 28.5, 2.05, PI / 2)
	lamp(6.79, 32., 1.64, -PI / 2)
	lamp(-5.69, 42., 2.06, PI / 2)
	glow(loc(2., 3.) + Vector3.UP * 2.4, Color("b1c2d5"), 1.72, 7.6)
	# Reflected lamplight falls across the bed and faces, not just the wall.
	glow(loc(6.55,-.93) + Vector3.UP * 1.92, Color("f3c89a"), 1.70, 4.5)
	glow(loc(40.3,1.18) + Vector3.UP * 2.04, Color("b5c6d5"), 1.24, 5.1)
	glow(loc(37.5, 1.) + Vector3.UP * 2.7, Color("9fc6dc"), 1.0, 7.)
	var lyra = person_on_set("Lyra", loc(8., -2.))
	var olive = MeshInstance3D.new(); olive.name = "UcuncuZeytin"
	lyra.socket("hand_l").add_child(olive); olive.mesh = geometry("leaf")
	olive.material_override = material("#494332"); olive.scale = Vector3(.036,.041,.033)
	olive.position = Vector3(0,.082,.034)
	person_on_set("Matilda", loc(22.8, -3.04))
	person_on_set("İskele kâtibi", loc(23.5, -.2))
	guard = person_on_set("Nöbetçi", loc(18.3, -1.8))
	lantern = Node3D.new()
	guard.add_child(lantern)
	lantern.position = Vector3(-.27, 1.31, .32)
	var cage = MeshInstance3D.new()
	cage.mesh = set_mesh("lamp_lantern")
	cage.scale = Vector3.ONE * .50
	lantern.add_child(cage)
	cone = SpotLight3D.new()
	lantern.add_child(cone)
	cone.light_color = Color("ffd19a")
	cone.light_energy = 5.5
	cone.spot_range = 8.
	cone.spot_angle = 39.
	cone.spot_attenuation = .72
	cone.rotation = Vector3(-.22, PI, 0.)
	cone.shadow_enabled = quality
	var wick = OmniLight3D.new()
	lantern.add_child(wick)
	wick.light_color = cone.light_color
	wick.light_energy = .88
	wick.omni_range = 2.65
	rain = CPUParticles3D.new(); add_child(rain)
	rain.amount = 170 if high else 85; rain.lifetime = .86; rain.local_coords = false
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(5.1,.35,6.3); rain.direction = Vector3(.08,-1.,-.06)
	rain.spread = 3.; rain.initial_velocity_min = 7.; rain.initial_velocity_max = 8.2
	rain.gravity = Vector3(.66,-.8,-.36); rain.emitting = false
	var drop = BoxMesh.new(); drop.size = Vector3(.009,.13,.011)
	var wet = StandardMaterial3D.new(); wet.albedo_color = Color(.57,.68,.78,.35)
	wet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.material = wet; rain.mesh = drop; rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	way = Node3D.new()
	add_child(way)
	flush()
	for b in beats:
		sites[int(b.id)] = point(b.at)


func set_route(value: String, animated = false):
	route = value
	for side in doors:
		var angle = (1.4 if side == KITCHEN else -1.4) if side == route else 0.
		if animated:
			doors[side].create_tween().tween_property(doors[side], "rotation:y", angle, .42)
		else:
			doors[side].rotation.y = angle
	if route == KITCHEN:
		if animated:
			var tween = clatter.create_tween().set_parallel(true)
			tween.tween_property(clatter, "position:y", .09, .42).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.tween_property(clatter, "rotation:z", .12, .35)
		else:
			clatter.position.y = .09


func closest_route(player: Vector3) -> String:
	return KITCHEN if player.x <= 0. else CELLAR


func destination(b: Dictionary, player: Vector3) -> Vector3:
	if b.kind == "night_fork":
		return loc(SWITCH_DEPTH, -LATCH_X if closest_route(player) == KITCHEN else LATCH_X)
	if b.kind == "night_pass":
		return loc(37., -LATCH_X if route == KITCHEN else LATCH_X)
	return point(b.at)


func stage(b: Dictionary):
	stage_id = b.kind
	suspicion = 0.
	heard = false
	in_light = false
	people.Lyra.socket("hand_l").get_node("UcuncuZeytin").visible = stage_id == "night_wake"
	reprieve = .8
	if stage_id == "night_fork":
		people.Lyra.position = loc(24., -.6)
	elif stage_id in ["night_pass", "night_fish", "night_chase", "night_out"]:
		people.Lyra.position = loc(41., 0.)
	else:
		people.Lyra.position = loc(8., -2.)
	if stage_id == "night_chase":
		reset_chase()


func ensemble(_pages: Array, _at: Vector3, _player: Vector3):
	# Eavesdropping must not teleport Matilda and the clerk to the player's shoulder.
	pass


func reset_chase():
	guard.position = loc(39.1 if route == KITCHEN else 36.6, -2. if route == KITCHEN else 2.6)
	chase_started = false
	chase_gap = 4.0
	reprieve = 1.55


func frame(dt: float, player: Vector3, _walking_guide = false):
	clock += dt
	rain.position = Vector3(player.x,5.3,clampf(player.z,-62.,-44.7))
	rain.emitting = -player.z > 38.
	for a in actors:
		if a != guard:
			if a.title == "Matilda" and stage_id == "night_hear":
				a.face(people["İskele kâtibi"].position)
			elif a.title == "İskele kâtibi" and stage_id == "night_hear":
				a.face(people.Matilda.position)
			elif a.position.distance_squared_to(player) < 48.:
				a.face(player)
			a.motion(0., Vector3.ZERO, dt)


func tick_patrol(dt: float, p: Vector3, speed: float) -> bool:
	patrol_time += dt
	reprieve = maxf(0., reprieve - dt)
	var old: Vector3 = guard.position
	var next = loc(18.1 + sin(patrol_time * .65) * .65, sin(patrol_time * .72) * 2.65)
	if stage_id == "night_pass" and route == KITCHEN:
		next = loc(27.7, -4.4)
		guard.position = old.move_toward(next, 2.8 * dt)
	elif stage_id == "night_chase":
		chase_started = chase_started or -p.z > 42.3 or speed > 1.7
		if chase_started and reprieve <= 0.:
			guard.position = old.move_toward(Vector3(p.x, 0, p.z), dt * (3.02 if route == KITCHEN else 2.68))
		chase_gap = p.distance_to(guard.position)
	elif stage_id not in ["night_fish", "night_out"]:
		guard.position = next
	var movement: Vector3 = guard.position - old
	guard.motion(movement.length() / dt, movement.normalized(), dt)
	lantern.rotation.z = sin(patrol_time * 3.6) * .10
	lantern.rotation.y = sin(patrol_time * 1.15) * .25
	if stage_id == "night_chase":
		return chase_started and reprieve <= 0. and chase_gap < .83
	if stage_id != "night_hear":
		return false
	var eye = lantern.global_position
	var to = p + Vector3.UP * (.75 if ducking else 1.35)
	var delta_ = to - eye
	var gap = delta_.length()
	in_light = gap < cone.spot_range and (-cone.global_basis.z).normalized().dot(delta_.normalized()) > cos(deg_to_rad(cone.spot_angle)) and not opaque(eye, to)
	heard = speed > 3.25 and gap < 4.7
	var attention = (.48 if ducking else .90) if in_light else 0.
	attention += .55 if heard else 0.
	suspicion = clampf(suspicion + dt * (attention if attention > 0. and reprieve <= 0 else -.85), 0., 1.)
	return suspicion >= 1.


func retry_position() -> Vector3:
	if stage_id == "night_chase":
		reset_chase()
		return loc(41.6, .65)
	suspicion = 0.
	reprieve = 2.35
	return loc(12.4, -2.5)

extends Node3D
## Deterministic art direction: authored landmarks on a winding path, pooled static geometry.
const Actor = preload("res://scripts/actor.gd")
const WATER = preload("res://shaders/river.gdshader")
const LINEN = preload("res://shaders/linen.gdshader")
const PEOPLE = ["Mina", "Hedi", "Tamar", "Oris", "Ruva", "Ekin", "Ese", "Sarpel"]
var zone = 0
var length = 250.0
var rng = RandomNumberGenerator.new()
var batches = {}
var shapes = {}
var mats = {}
var obstacles: Array = []
var people = {}
var sites = {}
var actors: Array = []
var env: Environment
var sun: DirectionalLight3D
var way: Node3D
var ring: MeshInstance3D
var target_pos = Vector3.ZERO
var water_mat: ShaderMaterial
var cloth_mat: ShaderMaterial
var clock = 0.0
var high = true
var vistas = ["#a89b77", "#bd976f", "#8eab88", "#baac8a", "#bc9c8e", "#93ae86", "#8ba29b"]


func center(d: float) -> float:
	return sin(d * .022 + zone * .77) * 10 + sin(d * .05 + zone) * 2.6


func altitude(x: float, z: float) -> float:
	var d = -z
	var edge = absf(x - center(d))
	var h = sin(d * .026 + zone) * 1.75 + sin(x * .055 + d * .018) * .7
	if zone == 2:
		h += 10.0 * exp(-maxf(d, 0) * .023)
	if zone == 6:
		h -= 1.05 * sin(d * .019)
	return h + maxf(edge - 31, 0) * (.105 + .065 * sin(d * .05))


func loc(d: float, lane: float) -> Vector3:
	var x = center(d) + lane
	return Vector3(x, altitude(x, -d), -d)


func point(a: Array) -> Vector3:
	return loc(float(a[0]), float(a[1]))


func passable(p: Vector3) -> bool:
	if -p.z < -12 or -p.z > length + 15 or absf(p.x - center(-p.z)) > 34:
		return false
	for r in obstacles:
		if absf(p.x - r.x) < r.z + .31 and absf(p.z - r.y) < r.w + .31:
			return false
	return true


func camera_safe(focus: Vector3, desired: Vector3) -> Vector3:
	var end = desired
	for i in range(1, 12):
		var f = i / 11.0
		var p = focus.lerp(desired, f)
		if p.y < altitude(p.x, p.z) + .55:
			end = focus.lerp(desired, maxf(.14, f - .11))
			break
		var blocked = false
		for r in obstacles:
			if (
				absf(p.x - r.x) < r.z + .2
				and absf(p.z - r.y) < r.w + .2
				and p.y < altitude(p.x, p.z) + 5.3
			):
				blocked = true
				break
		if blocked:
			end = focus.lerp(desired, maxf(.14, f - .11))
			break
	return end


func material(color: String, emissive = false) -> Material:
	var key = color + str(emissive)
	if not mats.has(key):
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(color)
		m.roughness = .92
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		if emissive:
			m.emission_enabled = true
			m.emission = Color(color)
			m.emission_energy_multiplier = .65
		mats[key] = m
	return mats[key]


func geometry(key: String) -> Mesh:
	if shapes.has(key):
		return shapes[key]
	var m: Mesh
	match key:
		"box":
			m = BoxMesh.new()
		"roof":
			m = prism_roof()
		"arch":
			m = arch_mesh()
		"pot":
			m = lathe(
				[
					Vector2(.32, 0),
					Vector2(.43, .16),
					Vector2(.70, .57),
					Vector2(.57, .86),
					Vector2(.25, 1.0),
					Vector2(.27, 1.12),
					Vector2(.32, 1.15)
				],
				14
			)
		"shaft":
			m = lathe(
				[
					Vector2(.54, 0),
					Vector2(.56, .06),
					Vector2(.46, .08),
					Vector2(.34, .13),
					Vector2(.30, .88),
					Vector2(.46, .92),
					Vector2(.53, .96),
					Vector2(.53, 1)
				],
				14
			)
		"cone":
			var c = CylinderMesh.new()
			c.top_radius = .07
			c.bottom_radius = .65
			c.height = 1
			c.radial_segments = 9
			c.rings = 1
			m = c
		"rod":
			var c = CylinderMesh.new()
			c.top_radius = .44
			c.bottom_radius = .54
			c.height = 1
			c.radial_segments = 8
			c.rings = 1
			m = c
		"leaf", "rock":
			var q = SphereMesh.new()
			q.radius = .58
			q.height = 1.0
			q.radial_segments = 9 if key == "leaf" else 7
			q.rings = 4
			m = q
		"sheet":
			var q = PlaneMesh.new()
			q.size = Vector2.ONE
			q.subdivide_width = 8
			q.subdivide_depth = 4
			m = q
		_:
			m = BoxMesh.new()
	shapes[key] = m
	return m


func lathe(p: Array, n: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(p.size() - 1):
		for i in range(n):
			var a = i * TAU / n
			var b = (i + 1) * TAU / n
			var l = p[row]
			var u = p[row + 1]
			var pts = [
				Vector3(cos(a) * l.x, l.y, sin(a) * l.x),
				Vector3(cos(b) * l.x, l.y, sin(b) * l.x),
				Vector3(cos(b) * u.x, u.y, sin(b) * u.x),
				Vector3(cos(a) * u.x, u.y, sin(a) * u.x)
			]
			for j in [0, 1, 2, 0, 2, 3]:
				st.set_normal(Vector3(pts[j].x, .12, pts[j].z).normalized())
				st.add_vertex(pts[j])
	return st.commit()


func prism_roof() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts = [
		Vector3(-.5, 0, -.5),
		Vector3(.5, 0, -.5),
		Vector3(0, 1, -.5),
		Vector3(-.5, 0, .5),
		Vector3(.5, 0, .5),
		Vector3(0, 1, .5)
	]
	for face in [[0, 2, 1], [3, 4, 5], [0, 3, 5, 0, 5, 2], [1, 2, 5, 1, 5, 4]]:
		var normal = (pts[face[1]] - pts[face[0]]).cross(pts[face[2]] - pts[face[0]]).normalized()
		if normal.y < 0:
			normal = -normal
		for i in face:
			st.set_normal(normal)
			st.add_vertex(pts[i])
	return st.commit()


func arch_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(12):
		var a = PI * k / 12 + .006
		var b = PI * (k + 1) / 12 - .006
		var pts = []
		for z in [-.36, .36]:
			for pair in [[a, 1.], [b, 1.], [b, 1.36], [a, 1.36]]:
				pts.append(Vector3(cos(pair[0]) * pair[1], sin(pair[0]) * pair[1], z))
		for face in [
			[0, 1, 2, 3], [7, 6, 5, 4], [4, 5, 1, 0], [3, 2, 6, 7], [0, 3, 7, 4], [1, 5, 6, 2]
		]:
			var normal = (
				(pts[face[1]] - pts[face[0]]).cross(pts[face[2]] - pts[face[0]]).normalized()
			)
			for j in [0, 1, 2, 0, 2, 3]:
				st.set_normal(normal)
				st.add_vertex(pts[face[j]])
	return st.commit()


func put(shape: String, col: String, pos: Vector3, sz: Vector3, rot = Vector3.ZERO):
	var key = shape + ":" + col
	if not batches.has(key):
		batches[key] = []
	batches[key].append(Transform3D(Basis.from_euler(rot) * Basis.from_scale(sz), pos))


func block(p: Vector3, s: Vector3, c: String):
	put("box", c, p + Vector3.UP * s.y * .5, s)


func beam(a: Vector3, b: Vector3, r: float, col: String):
	var d = b - a
	var q = Quaternion(Vector3.UP, d.normalized())
	put("rod", col, (a + b) / 2, Vector3(r, d.length(), r), Basis(q).get_euler())


func arch(p: Vector3, r: float, h: float, turn = false, col = "#d6c094"):
	var d = Vector3.BACK if turn else Vector3.RIGHT
	for signum in [-1, 1]:
		var foot = p + d * r * 1.17 * signum
		block(foot, Vector3(.58 * r, h, .8 * r) if not turn else Vector3(.8 * r, h, .58 * r), col)
		block(foot + Vector3.UP * (h - .2), Vector3(.85 * r, .28, 1.0 * r), "#ae9773")
	put("arch", col, p + Vector3.UP * h, Vector3.ONE * r, Vector3(0, PI / 2 if turn else 0., 0))


func tree(p: Vector3, h: float, cypress = false):
	var bark = "#695843"
	var tint = ["#6a804e", "#73865b", "#526f4b"][rng.randi_range(0, 2)]
	if cypress:
		beam(p, p + Vector3.UP * h * .75, h * .09, bark)
		for i in range(3):
			put(
				"cone",
				tint,
				p + Vector3.UP * h * (.4 + i * .16),
				Vector3(h * (.28 - .045 * i), h * (.68 - .08 * i), h * (.27 - .043 * i)),
				Vector3(0, i * .65, .025)
			)
	else:
		beam(p, p + Vector3(.3, h * .52, .1), h * .14, bark)
		for k in range(5):
			var a = k * 1.26 + rng.randf_range(-.3, .3)
			var leaf = (
				p + Vector3(cos(a) * h * .34, h * (.65 + .21 * rng.randf()), sin(a) * h * .34)
			)
			beam(p + Vector3(.2, h * .36, .1), leaf, h * .065, bark)
			put("leaf", tint, leaf, Vector3(h * .8, h * .41, h * .72), Vector3(.11, a, .12))


func house(p: Vector3, w: float, d: float, h: float, col: String, solid = true):
	block(p - Vector3.UP * .45, Vector3(w + .35, h + .45, d + .3), col)
	block(p + Vector3.UP * .08, Vector3(w + .46, .32, d + .44), "#ab9171")
	block(p + Vector3.UP * (h - .12), Vector3(w + .65, .26, d + .55), "#bd9670")
	put("roof", "#9e5f47", p + Vector3.UP * (h + .12), Vector3(w + .75, w * .25, d + .75))
	var side = signf(center(-p.z) - p.x)
	if is_zero_approx(side):
		side = 1
	block(p + Vector3(side * (w * .5 + .01), 0, .35), Vector3(.065, h * .69, 1.45), "#584f43")
	for j in [-1, 1]:
		block(
			p + Vector3(side * (w * .5 + .035), h * .5, j * d * .32),
			Vector3(.09, .82, .83),
			"#686452"
		)
	if solid:
		obstacles.append(Vector4(p.x, p.z, w * .5, d * .5))


func shop(p: Vector3, sgn: float):
	var tint = ["#356d70", "#a05546", "#b08a44"][rng.randi_range(0, 2)]
	for x in [-2.4, 2.4]:
		for z in [-1.9, 1.9]:
			beam(p + Vector3(x, 0, z), p + Vector3(x, 3.5 + x * .08 * sgn, z), .16, "#78583d")
	put("sheet", tint, p + Vector3.UP * 3.45, Vector3(5.6, 1, 4.7), Vector3(0, 0, .085 * sgn))
	block(p, Vector3(3.9, .83, 1.3), "#9a714e")
	for j in range(4):
		put(
			"pot",
			["#b57552", "#cda977"][j % 2],
			p + Vector3(j * .8 - 1.25, .85, 0),
			Vector3.ONE * (.57 + j * .035)
		)


func props(kind: String, pos: Vector3, sz = 1., yaw = 0.):
	var l = load("res://art/props/" + kind + ".glb")
	if l:
		var inst = l.instantiate()
		inst.scale = Vector3.ONE * sz
		inst.rotation.y = yaw
		inst.position = pos
		add_child(inst)


func flush():
	for k in batches:
		var parts = k.split(":")
		var mesh = geometry(parts[0])
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = batches[k].size()
		for i in range(batches[k].size()):
			mm.set_instance_transform(i, batches[k][i])
		var view = MultiMeshInstance3D.new()
		view.multimesh = mm
		if parts[0] == "sheet":
			var cloth = ShaderMaterial.new()
			cloth.shader = LINEN
			cloth.set_shader_parameter("dye", Color(parts[1]))
			view.material_override = cloth
		else:
			view.material_override = material(parts[1])
		add_child(view)
	batches.clear()


func terrain():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base = Color(vistas[zone])
	var sand = Color("d4bc92")
	for z in range(-int(length) - 95, 76, 5):
		for x in range(-140, 140, 5):
			for o in [
				Vector2(0, 0),
				Vector2(5, 0),
				Vector2(5, 5),
				Vector2(0, 0),
				Vector2(5, 5),
				Vector2(0, 5)
			]:
				var xx = x + o.x
				var zz = z + o.y
				var d = absf(xx - center(-zz))
				var blend = 1.0 - smoothstep(3.5, 10.5, d)
				var n = sin(xx * 2.13 + zz * 1.7) * .035 + sin(xx * .074 + zz * .093) * .045
				var color = base.lerp(sand, blend * .93).lightened(maxf(0, n)).darkened(maxf(0, -n))
				st.set_color(color)
				st.set_normal(
					(
						Vector3(
							altitude(xx - .3, zz) - altitude(xx + .3, zz),
							.6,
							altitude(xx, zz - .3) - altitude(xx, zz + .3)
						)
						. normalized()
					)
				)
				st.add_vertex(Vector3(xx, altitude(xx, zz), zz))
	var m = ShaderMaterial.new()
	m.shader = preload("res://shaders/earth.gdshader")
	m.set_shader_parameter("district", float(zone))
	var ground = MeshInstance3D.new()
	ground.mesh = st.commit()
	ground.material_override = m
	add_child(ground)


func setup(index: int, beats: Array, quality: bool):
	zone = index
	high = quality
	rng.seed = 9130 + zone * 371
	length = beats.back().at[0] + 8
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sm = ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("547692") if zone != 4 else Color("575578")
	sm.sky_horizon_color = Color("efcba7") if zone in [0, 3, 4] else Color("c8d9cc")
	sm.ground_horizon_color = sm.sky_horizon_color
	sm.ground_bottom_color = Color("82918a")
	sm.sun_angle_max = 9
	var panorama = PanoramaSkyMaterial.new()
	panorama.panorama = preload("res://art/valley_sky.jpg")
	panorama.energy_multiplier = 0.84 if zone == 4 else 1.0
	sky.sky_material = panorama
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d7dfdc")
	env.ambient_light_energy = .77
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.12
	env.fog_enabled = true
	env.fog_light_color = sm.sky_horizon_color
	env.fog_density = .00265
	env.fog_sky_affect = .18
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("ffdfb3") if zone != 4 else Color("ffba87")
	sun.light_energy = 1.58
	sun.rotation_degrees = Vector3(-41 if zone != 4 else -19, -39, 0)
	sun.shadow_enabled = high
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 58
	add_child(sun)
	water_mat = ShaderMaterial.new()
	water_mat.shader = WATER
	terrain()
	district_art()
	# An actual encircling skyline, with multiple ranges at different scales/depths.
	for i in range(46):
		var a = TAU * i / 46.
		var rad = rng.randf_range(350, 476)
		var pp = Vector3(cos(a) * rad, 0, -length * .5 + sin(a) * rad)
		var hh = rng.randf_range(22, 50)
		var col = ["#929b98", "#9a9c93", "#8c969b"][i % 3]
		put(
			"rock",
			col,
			pp + Vector3.UP * hh * .2,
			Vector3(rng.randf_range(71, 133), hh * 1.65, rng.randf_range(65, 110)),
			Vector3(rng.randf_range(-.13, .13), a, .15)
		)
		put(
			"rock",
			"#abb0a3",
			pp * 1.27 + Vector3.UP * hh * .54,
			Vector3(123, hh * 1.85, 123),
			Vector3(.05, a, -.1)
		)
	for t in range(-10, int(length) + 15, 11):
		for signum in [-1, 1]:
			var lane = signum * rng.randf_range(18, 30)
			var p = loc(t, lane)
			if (zone in [0, 1, 2, 3, 4]) and rng.randf() < .5:
				house(
					p,
					rng.randf_range(5, 8),
					rng.randf_range(5, 9),
					rng.randf_range(3.6, 6.3),
					["#dcc7a3", "#d3bd9a", "#c5ad8e"][rng.randi_range(0, 2)]
				)
			else:
				tree(p, rng.randf_range(4, 7), rng.randf() < .4)
			if zone in [1, 2] and (t + 10) % 22 == 0:
				shop(loc(t + 4, signum * 15.6), signum)
			for i in range(3):
				var f = loc(t + rng.randf_range(-5, 5), signum * rng.randf_range(36, 105))
				tree(f, rng.randf_range(4, 9), rng.randf() < .65)
			for i in range(10):
				var g = loc(t + rng.randf_range(-5, 6), signum * rng.randf_range(9, 54))
				put(
					"leaf",
					["#918e5a", "#9b9c69", "#aaa16c"][i % 3],
					g + Vector3.UP * .09,
					Vector3(.53, .37, .46) * rng.randf_range(.6, 2.)
				)
		if t % 2 == 0:
			var rock = loc(t, rng.randf_range(-5, 5))
			put("rock", "#bfac8b", rock, Vector3(1.1, .08, .75), Vector3(0, t, 0))
	for t in range(-25, int(length) + 38, 12):
		var ap = loc(t, zone * 1.5 + 44)
		arch(ap, 4.6, 5.4, true, "#c4b89e")
		block(ap + Vector3.UP * 11.2, Vector3(3.7, .9, 12.5), "#c3b399")
		if zone in [3, 4, 5]:
			for signum in [-1, 1]:
				var cp = loc(t, signum * 12.3)
				put("shaft", "#ddcba4", cp, Vector3(1.65, 4.4, 1.65))
				block(cp + Vector3.UP * 4.4, Vector3(1.7, .42, 8.), "#c7ae84")
		if zone == 6:
			arch(loc(t, 16.3), 2.7, 2.7, true, "#aa9e8d")
	for i in range(28):
		var d = rng.randf_range(0, length)
		var p = loc(d, rng.randf_range(-6, 6))
		put(
			"rock",
			"#d9c5a4",
			p,
			Vector3(rng.randf_range(.5, 2), .075, rng.randf_range(.45, 1.2)),
			Vector3(0, rng.randf_range(-1, 1), 0)
		)
	for b in beats:
		var model = str(b.model)
		var p = point(b.at)
		if model in PEOPLE:
			if not people.has(model):
				var person = Actor.new()
				add_child(person)
				person.make(model)
				person.position = p
				person.rotation.y = rng.randf_range(-2, 2)
				people[model] = person
				actors.append(person)
		else:
			landmark(model, p)
		sites[int(b.id)] = p
	for i in range(4):
		var p = loc((i + 1) * length / 5., -13 if i % 2 else 13)
		if zone in [0, 1, 3, 4]:
			props(
				["table_long_decorated_A", "shelf_large", "bed_decorated", "crates_stacked"][i],
				p,
				.82,
				i * .8
			)
		else:
			tree(p, 4.3, i % 2 == 0)
	if zone in [2, 6]:
		water_strip()
	flush()
	way = Node3D.new()
	add_child(way)
	ring = MeshInstance3D.new()
	var tor = TorusMesh.new()
	tor.inner_radius = .82
	tor.outer_radius = .91
	tor.rings = 36
	tor.ring_segments = 6
	ring.mesh = tor
	ring.material_override = material("#e6bb70", true)
	way.add_child(ring)


func water_strip():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for d in range(-12, int(length) + 18, 4):
		for v in [[0, 0], [1, 0], [1, 1], [0, 0], [1, 1], [0, 1]]:
			var p = loc(d + v[1] * 4, 34 + v[0] * 8)
			p.y = altitude(center(d) + 34, -d) + .22
			st.set_normal(Vector3.UP)
			st.add_vertex(p)
	var w = MeshInstance3D.new()
	w.mesh = st.commit()
	w.material_override = water_mat
	add_child(w)


func basin(p: Vector3, w = 1.0):
	put("pot", "#bda888", p, Vector3(2.4, .79, 2.4) * w)
	var water = MeshInstance3D.new()
	var c = CylinderMesh.new()
	c.top_radius = .74 * w
	c.bottom_radius = .74 * w
	c.height = .06
	c.radial_segments = 27
	water.mesh = c
	water.material_override = water_mat
	water.position = p + Vector3.UP * .85 * w
	add_child(water)


func landmark(kind: String, p: Vector3):
	match kind:
		"bowl", "lamp":
			props("table_medium_tablecloth", p, .63)
			put("pot", "#b27b53", p + Vector3.UP * .65, Vector3(.51, .35, .51))
			props("candle_triple", p + Vector3(.38, .64, .1), .53)
		"fish", "mark", "trace":
			put("rock", "#bc805b", p + Vector3.UP * .2, Vector3(1.3, .42, .67))
			put(
				"cone",
				"#bf8762",
				p + Vector3(.6, .24, 0),
				Vector3(.52, .62, .52),
				Vector3(0, 0, 1.58)
			)
		"wall":
			block(p + Vector3(-3.5, 0, 0), Vector3(4.8, 1.14, .67), "#baab8b")
			block(p, Vector3(2.15, .68, .66), "#c9ae85")
			block(p + Vector3(3.5, 0, 0), Vector3(4.8, 1.14, .67), "#baab8b")
		"basin", "portal", "well":
			basin(p, 1.55)
			arch(p + Vector3(0, 0, -1.7), 1.72, 2.4)
			tree(p + Vector3(-3.7, 0, 1.3), 5.3)
		"desk":
			props("table_long_decorated_A", p, .78, PI / 2)
			props("chair", p + Vector3(0, 0, -1.5), .76)
			block(p + Vector3(0, .8, .1), Vector3(.79, .08, .52), "#c18a65")
		"gate", "vista", "stone":
			arch(p, 2.7, 2.45)
			put("shaft", "#bc9574", p + Vector3(3.5, 0, 2), Vector3(1.2, 1.6, 1.2))
		"pillar", "bell":
			put("shaft", "#dec79d", p, Vector3(2.65, 3.3, 2.65))
			props("banner_patternB_blue", p + Vector3(0, 0, .36), .84)
		"stall":
			shop(p, 1)
			props("barrel_small_stack", p + Vector3(2.4, 0, 1), .79)
		"bed":
			props("bed_decorated", p, .85)
			props("shelf_small_candles", p + Vector3(1.8, 0, -1), .8)
		"chest":
			props("chest", p, .95)
		"pipe", "wheel":
			basin(p, 1.35)
			arch(p + Vector3(0, 0, -.85), 1.18, 1.35, false, "#b29d7d")
			put(
				"rod",
				"#ac7957",
				p + Vector3(0, .75, 1),
				Vector3(.9, 2.2, .9),
				Vector3(PI / 2, 0, 0)
			)
		"disc", "basket":
			for s in [-1, 1]:
				put("shaft", "#c1a17e", p + Vector3(s * 2.2, 0, 0), Vector3(.66, 2.55, .66))
			beam(p + Vector3(-2.3, 2.53, 0), p + Vector3(2.3, 2.53, 0), .23, "#805f43")
			put("pot", "#ae865a", p + Vector3(1.5, 0, .55), Vector3(.8, .57, .8))


func stage(b: Dictionary):
	target_pos = point(b.at)
	way.position = target_pos + Vector3.UP * .08
	if people.has(b.model):
		people[b.model].show()
		people[b.model].position = target_pos


func frame(delta: float, player: Vector3, walking_guide = false):
	clock += delta
	if ring:
		ring.scale = Vector3.ONE * (1.0 + sin(clock * 2) * .045)
	for actor in actors:
		if walking_guide and actor.title == "Tamar":
			continue
		if actor.position.distance_squared_to(player) < 42:
			actor.face(player)
		actor.motion(0, Vector3.ZERO, delta)


func district_art():
	# Bespoke silhouettes anchor the teaching route; all ornament below shares draw batches.
	match zone:
		0:
			for d in range(0, 75, 7):
				var p = loc(d, -13.7)
				arch(p, 2.15, 1.6, true, "#d7c5a5")
				block(p + Vector3.UP * 4.5, Vector3(3.5, .4, 7.1), "#b39071")
			for i in range(4):
				props("bed_decorated", loc(7 + i * 6.4, 11.8), .85, PI * .5)
			for i in range(3):
				var p = loc(10, 2) + Vector3(-.24 + i * .16, .88, .02)
				put("leaf", "#747345", p, Vector3(.15, .077, .10))
			for d in [30, 68, 99]:
				arch(loc(d, 0), 3.1, 2.3)
				props("banner_patternA_red", loc(d, -3.4), .85)
		1:
			for d in range(28, 142, 17):
				var p = loc(d, 0)
				put(
					"sheet",
					["#98603d", "#3f767e", "#9e4e48"][int(d / 17) % 3],
					p + Vector3.UP * 5.4,
					Vector3(9, 1, 4),
					Vector3(.08, 0, .09)
				)
				for x in [-5, 5]:
					beam(p + Vector3(x, 0, 0), p + Vector3(x, 5.9, 0), .22, "#81603f")
			for i in range(6):
				props("barrel_large_decorated", loc(22 + i * 17, 11.0), .7 + i % 3 * .1)
		2:
			for i in range(3):
				var p = loc(32 + i * 5.5, -8)
				put("shaft", "#dcc6a3", p, Vector3(2.2, 4.5 + i * .3, 2.2))
				props(
					"banner_patternB_blue" if i == 1 else "banner_patternA_red",
					p + Vector3(0, .7, .23),
					1.15
				)
			for i in range(8):
				put(
					"pot",
					"#bd7f58",
					loc(93 + i * 2.8, 12 + (i % 2) * 2),
					Vector3.ONE * (1. + i % 3 * .47)
				)
			for i in range(14):
				var p = loc(145 + i * 5, 30)
				tree(p, 4.5)
				put("leaf", "#b65343", p + Vector3(.45, 3.2, .23), Vector3(.34, .35, .36))
		3, 4:
			for row in range(3):
				var p = loc(20 + row * 89, 0)
				arch(p, 3.2, 3.4)
				block(p + Vector3.UP * 7.55, Vector3(10, .48, 2.2), "#caaa81")
				props("banner_patternB_blue", p + Vector3(-3.9, 1.4, .41), 1.13)
			for i in range(5):
				props("shelf_large", loc(60 + i * 4.6, 13.3), .8, PI * .5)
				props("chair", loc(105 + i * 4.2, -11.2), .76)
			for i in range(12):
				put("pot", "#b37b53", loc(35 + i * 4, 10.4), Vector3(.6, .75, .6))
		5:
			for d in [27, 116, 170]:
				var p = loc(d, -3)
				for i in range(13):
					var a = PI * .08 + i * PI * .84 / 12
					for k in range(3):
						var pt = (
							p
							+ Vector3(
								cos(a) * (12 + k * 1.4), .28 * (k + 1), -sin(a) * (12 + k * 1.4)
							)
						)
						put(
							"box",
							"#d5bd97",
							pt,
							Vector3(.95, .45 * (k + 1), 2.5 + k * .22),
							Vector3(0, a, 0)
						)
				for i in range(8):
					var a = i * TAU / 8
					var pt = p + Vector3(cos(a) * 4, .03, sin(a) * 4)
					put("rock", "#9d805f", pt, Vector3(1.15, .12, .58), Vector3(0, -a, 0))
		6:
			for d in range(30, 201, 10):
				var p = loc(d, 0)
				arch(p, 4.05, 2.7)
				block(p + Vector3.UP * 7.92, Vector3(10.5, .55, 2.1), "#ada28c")
				for x in [-8.5, 8.5]:
					put(
						"rod",
						"#b17e53",
						loc(d, x) + Vector3.UP * .36,
						Vector3(1.05, 9.6, 1.05),
						Vector3(PI / 2, 0, 0)
					)
	for i in range(25):
		var p = loc(rng.randf_range(1, length), rng.randf_range(14, 21) * (-1 if i % 2 else 1))
		put(
			"pot",
			["#ad7251", "#c58c63", "#b5a17c"][i % 3],
			p,
			Vector3.ONE * rng.randf_range(.6, 1.45)
		)
		put("rod", "#785941", p + Vector3.UP * .12, Vector3(.8, .11, .8))

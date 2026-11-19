extends Node3D
## Deterministic art direction: authored landmarks on a winding path, pooled static geometry.
const Actor = preload("res://scripts/actor.gd")
const WATER = preload("res://shaders/river.gdshader")
const LINEN = preload("res://shaders/linen.gdshader")
const Surfaces = preload("res://scripts/surfaces.gd")
const PEOPLE = ["Lyra", "Matilda", "Aldric", "Dorian", "Magnus", "Ariadne", "Edda", "Valer"]
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
var directed: Array = []
var env: Environment
var sun: DirectionalLight3D
var way: Node3D
var ring: MeshInstance3D
var target_pos = Vector3.ZERO
var wheels = []
var twigs = []
var reversed = false
var water_mat: ShaderMaterial
var cloth_mat: ShaderMaterial
var clock = 0.0
var high = true
var vistas = ["#a89b77", "#bd976f", "#8eab88", "#baac8a", "#bc9c8e", "#93ae86", "#8ba29b"]


func center(d: float) -> float:
	return sin(d * .022 + zone * .77) * 10 + sin(d * .05 + zone) * 2.6


func natural_height(x: float, z: float) -> float:
	var d = -z
	var edge = absf(x - center(d))
	var h = sin(d * .026 + zone) * 1.75 + sin(x * .055 + d * .018) * .7
	if zone == 2:
		h += 10.0 * exp(-maxf(d, 0) * .023)
	if zone == 6:
		h -= 1.05 * sin(d * .019)
	return h + maxf(edge - 31, 0) * (.105 + .065 * sin(d * .05))


func altitude(x: float, z: float) -> float:
	var h = natural_height(x,z)
	if zone == 4:
		for meal in [[139.,-7.],[178.,6.]]:
			var origin = Vector2(center(meal[0])+meal[1],-meal[0])
			var span = Vector2(x,z)-origin
			var edge = maxf(absf(span.x)-6.,absf(span.y)-5.)
			if edge < 4.: return lerpf(natural_height(origin.x,origin.y),h,smoothstep(0.,4.,edge))
	return h


func walk_height(x: float, z: float) -> float:
	return altitude(x, z)


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


func put(shape: String, col: String, pos: Vector3, sz: Vector3, rot = Vector3.ZERO):
	var key = shape + ":" + col
	if shape in ["set_pine", "set_oak", "set_fern"]:
		key += ":%d,%d" % [floori(pos.x/32.),floori(pos.z/32.)]
	if not batches.has(key):
		batches[key] = []
	batches[key].append(Transform3D(Basis.from_euler(rot) * Basis.from_scale(sz), pos))


func block(p: Vector3, s: Vector3, c: String):
	put("box", c, p + Vector3.UP * s.y * .5, s)


func beam(a: Vector3, b: Vector3, r: float, col: String):
	var d = b - a
	var q = Quaternion(Vector3.UP, d.normalized())
	put("rod", col, (a + b) / 2, Vector3(r, d.length(), r), Basis(q).get_euler())


func tree(p: Vector3, h: float, pine = false):
	scenery("pine" if pine else "oak", p, h, rng.randf_range(-PI, PI))


func occluder(at: Vector3, size_: Vector3):
	if DisplayServer.get_name() == "headless" or not get_viewport().use_occlusion_culling: return
	var o = OccluderInstance3D.new()
	var bounds = BoxOccluder3D.new(); bounds.size = size_
	o.occluder = bounds; o.position = at; add_child(o)


func house(p: Vector3, _w: float, _d: float, h: float, _col: String, solid = true):
	var turn = PI * .5 if p.x < center(-p.z) else -PI * .5
	var bounds = scenery("lodge_shell" if rng.randf() < .5 else "inn_shell", p, h * 1.35, turn)
	if solid:
		obstacles.append(Vector4(p.x, p.z, bounds.z * .5, bounds.x * .5))
		occluder(p + Vector3.UP * h*.36, Vector3(bounds.z*.67,h*.72,bounds.x*.65))


func set_mesh(id: String) -> Mesh:
	var key = "set_" + id
	if not shapes.has(key):
		var src = load("res://art/set/" + id + ".gltf").instantiate()
		var m = src if src is MeshInstance3D else src.find_children("*", "MeshInstance3D", true, false)[0]
		shapes[key] = m.mesh
		if id in ["lodge_shell","inn_shell","cap_tower","bay_cl_arch","bay_hl_win","lane_wall","market_stall_a"]:
			var architecture: Mesh = m.mesh.duplicate()
			for i in range(architecture.get_surface_count()):
				var mat = architecture.surface_get_material(i)
				if not mat is StandardMaterial3D: continue
				match str(mat.resource_name):
					"MC_Stone": architecture.surface_set_material(i,Surfaces.get_material("lime",1.72))
					"MC_Timber": architecture.surface_set_material(i,Surfaces.get_material("boards",1.38))
					"MC_Glass":
						var pane = mat.duplicate(); pane.albedo_color = Color("556265"); pane.roughness = .63
						architecture.surface_set_material(i,pane)
					_:
						var tile = mat.duplicate(); tile.albedo_color *= Color("9b8271"); tile.roughness = .86
						architecture.surface_set_material(i,tile)
			shapes[key] = architecture
		if id in ["oak", "pine"]:
			var mesh: Mesh = m.mesh.duplicate()
			var foliage = ShaderMaterial.new()
			foliage.shader = preload("res://shaders/canopy.gdshader")
			foliage.set_shader_parameter("foliage", load("res://art/set/%s_leaf.png" % id))
			mesh.surface_set_material(1, foliage)
			mesh.surface_set_material(0, Surfaces.get_material("bark", 1.7))
			shapes[key] = mesh
		src.free()
	return shapes[key]


func scenery(id: String, p: Vector3, height: float, turn = 0.) -> Vector3:
	var bb = set_mesh(id).get_aabb()
	if id == "cap_tower":
		# This module is only the tiled cap, not an entire tower.
		var span = height * .29; var cap_scale = (span + .88) / bb.size.x
		var eaves = height - bb.size.y * cap_scale; var sill = eaves-1.66
		block(p-Vector3.UP*.35,Vector3(span,sill+.35,span),"wet_stone")
		block(p+Vector3.UP*sill,Vector3(span+.23,.16,span+.23),"plaster")
		for x in [-1.,1.]:
			for z in [-1.,1.]: block(p+Vector3(x*(span*.5-.14),sill,z*(span*.5-.14)),Vector3(.27,1.66,.27),"sawn")
		for z in [-1.,1.]:
			block(p+Vector3(0,sill+.65,z*(span*.5-.14)),Vector3(span,.12,.15),"sawn")
			block(p+Vector3(0,eaves-.18,z*(span*.5-.14)),Vector3(span,.18,.21),"sawn")
		furnish(id,p+Vector3.UP*eaves,cap_scale,turn)
		return Vector3(span,height,span)
	var shell = id in ["lodge_shell","inn_shell"]
	# Shell y=0 is the doorstep. Below it the artist modelled footing posts;
	# lifting their lowest tips to the ground leaves entire inns on stilts.
	var factor = height / maxf(.001, bb.end.y if shell else bb.size.y)
	var base = p - Vector3.UP * (.12 if shell else bb.position.y*factor)
	furnish(id, base, factor, turn)
	return bb.size * factor


func furnish(id: String, p: Vector3, factor = 1., turn = 0.):
	set_mesh(id)
	put("set_" + id, "atlas", p, Vector3.ONE * factor, Vector3(0, turn, 0))


func shop(p: Vector3, sgn: float):
	furnish("market_stall_a", p, 1.07, PI*.5 if sgn > 0. else -PI*.5)
	furnish("jar_storage",p + Vector3(1.72,0,-.22),.85,.25)
	furnish("sack_tied",p + Vector3(1.64,0,.65),.88,-.43)


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
		if parts[0] == "set_fern":
			view.visibility_range_end = 72. if high else 42.
			view.visibility_range_end_margin = 5.
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if parts[1] == "atlas":
			pass  # the mesh already owns its shared, textured material
		elif parts[1] == "plaster":
			view.material_override = Surfaces.get_material("lime",1.52)
		elif parts[1] == "sawn":
			view.material_override = Surfaces.get_material("boards",1.22)
		elif parts[1] == "wet_stone":
			view.material_override = Surfaces.get_material("stone", 1.35)
		elif parts[0] == "sheet":
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
	# A continuous rectangular grid: the brook's 2 m banks cannot be sampled
	# by the 5 m district grid. Refine both axes here, without seam T-junctions.
	var xs = []; var zs = []
	for x in range(-140,141):
		if x % 5 == 0 or (zone == 2 and abs(x) <= 42 and x % 2 == 0): xs.append(x)
	for z in range(-int(length)-98,106 if zone == 2 else 76):
		if z % 5 == 0 or (zone == 2 and z >= 24 and z <= 44): zs.append(z)
	for row in range(zs.size()-1):
		for col in range(xs.size()-1):
			for ij in [[0,0],[1,0],[1,1],[0,0],[1,1],[0,1]]:
				var x = xs[col+ij[0]]; var z = zs[row+ij[1]]
				st.set_normal(Vector3(altitude(x-.3,z)-altitude(x+.3,z),.6,altitude(x,z-.3)-altitude(x,z+.3)).normalized())
				st.set_uv(Vector2(x,z)*.45)
				st.add_vertex(Vector3(x,altitude(x,z),z))
	st.index()
	st.generate_tangents()
	var m = ShaderMaterial.new()
	m.shader = preload("res://shaders/earth.gdshader")
	m.set_shader_parameter("district", float(zone))
	var names = {"loam": "loam_color", "flags": "cobble_color", "soil_normal": "loam_normal", "flags_normal": "cobble_normal", "soil_orm": "loam_orm", "flags_orm": "cobble_orm"}
	for param in names:
		m.set_shader_parameter(param, load("res://art/pbr/%s.jpg" % names[param]))
	var ground = MeshInstance3D.new()
	ground.mesh = st.commit()
	ground.material_override = m
	add_child(ground)


# Distant geography from the lookout. The horizon is not falsely marked as a
# navigable district; the nar trees, not this wall, bound the shared settlement.
func highlands():
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var origin = Vector3(0,0,-length*.44)
	var rings: Array = []
	var sectors = 216
	var radii = [133.,174.,224.,263.,294.,354.,403.,451.,487.,531.,610.]
	var peaks = [-9.,12.,59.,35.,28.,61.,112.,77.,55.,110.,86.]
	for k in range(radii.size()):
		var row = []
		for j in range(sectors):
			var a = TAU*j/sectors
			var r = radii[k] + 14.*sin(a*7. + k*.39)
			var fold = .47+.24*sin(a*5.+k*.45)+.17*cos(a*11.-k*.57)+.09*sin(a*23.)
			var height = peaks[k] * (fold + .065*sin(a*33.-k*.47)+.022*cos(a*58.+k*.17))
			row.append(origin + Vector3(sin(a)*r*1.14,height,cos(a)*(r+length*.48+45.)))
		rings.append(row)
	for k in range(rings.size()-1):
		for j in range(sectors):
			var n = (j+1)%sectors
			for pair in [[k,j],[k+1,j],[k+1,n],[k,j],[k+1,n],[k,n]]:
				st.add_vertex(rings[pair[0]][pair[1]])
	var rock = ShaderMaterial.new(); rock.shader = preload("res://shaders/highlands.gdshader")
	rock.set_shader_parameter("slope_detail", preload("res://art/pbr/stone_color.jpg"))
	rock.set_shader_parameter("distance_tint",Color("c6b8ad") if zone == 4 else Color("adbab7"))
	st.generate_normals(); st.index(); var mesh = MeshInstance3D.new(); mesh.mesh = st.commit()
	mesh.material_override = rock; mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mesh)
	st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(81,160):
		var a: Vector3 = rings[10][j]; var b: Vector3 = rings[10][j+1]
		var top_a = a + Vector3.UP*16.; var top_b = b + Vector3.UP*16.
		for v in [a,top_b,b,a,top_a,top_b]: st.add_vertex(v)
	st.generate_normals(); mesh = MeshInstance3D.new(); mesh.mesh = st.commit()
	mesh.material_override = material("#667774"); mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mesh)


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
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c6d7e0")
	env.ambient_light_energy = .40
	env.ambient_light_sky_contribution = 0.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = .95
	env.fog_enabled = true
	env.fog_light_color = sm.sky_horizon_color
	env.fog_density = .00265
	env.fog_sky_affect = .18
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("ffe3c7") if zone != 4 else Color("ffbf9a")
	sun.light_energy = .48
	sun.light_specular = .32
	sun.rotation_degrees = Vector3(-41 if zone != 4 else -19, -39, 0)
	sun.shadow_enabled = high
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 58
	add_child(sun)
	water_mat = ShaderMaterial.new()
	water_mat.shader = WATER
	water_mat.set_shader_parameter("capillary",preload("res://art/pbr/brook_ripples.png"))
	if RenderingServer.get_current_rendering_method() == "forward_plus" and high:
		env.ssao_enabled = true
		env.glow_enabled = true
		env.volumetric_fog_enabled = zone == 2
		env.volumetric_fog_density = .008
	terrain()
	if zone >= 2: highlands()
	district_art()
	for t in range(-10, int(length) + 15, 11):
		for signum in [-1, 1]:
			var lane = signum * rng.randf_range(15.3, 25)
			var p = loc(t, lane)
			if (zone in [1, 2, 3, 4]) and (zone != 2 or t > 32) and rng.randf() < .5:
				house(
					p,
					rng.randf_range(5, 8),
					rng.randf_range(5, 9),
					rng.randf_range(3.6, 6.3),
					["#dcc7a3", "#d3bd9a", "#c5ad8e"][rng.randi_range(0, 2)]
				)
			else:
				tree(p, rng.randf_range(4, 7), rng.randf() < .4)
			if (zone == 1 or (zone == 2 and t >= 36)) and (t + 10) % 22 == 0:
				shop(loc(t + 4, signum * 15.6), signum)
			for i in range(3):
				var f = loc(t + rng.randf_range(-5, 5), signum * rng.randf_range(36, 105))
				scenery(
					"oak" if i % 2 else "pine", f, rng.randf_range(4, 9), rng.randf_range(0, TAU)
				)
			for i in range(7):
				var g = loc(t + rng.randf_range(-5, 6), signum * rng.randf_range(8, 40))
				furnish("fern", g, rng.randf_range(.6, 1.45), rng.randf_range(0, TAU))
		if t % 2 == 0:
			var rock = loc(t, rng.randf_range(-5, 5))
			put("rock", "wet_stone", rock, Vector3(.49, .07, .35), Vector3(0, t, 0))
	# The school has a human-scale cloister, not a row of ceremonial arches across the road.
	if zone in [3,4,5]:
		for courtyard in [22.,87.,148.]:
			for bay in range(6):
				var p = loc(courtyard+bay*2.82,12.)
				furnish("bay_cl_arch" if bay % 3 != 1 else "bay_hl_win",p,.70,-PI*.5)
	elif zone == 6:
		for bank_d in [46.,124.,198.]:
			for bay in range(6): furnish("lane_wall",loc(bank_d + bay*2.7,15.7),.68,-PI*.5)
	for i in range(28):
		var d = rng.randf_range(0, length)
		var p = loc(d, rng.randf_range(-6, 6))
		put(
			"rock",
			"wet_stone",
			p,
			Vector3(rng.randf_range(.25, .76), .075, rng.randf_range(.24, .65)),
			Vector3(0, rng.randf_range(-1, 1), 0)
		)
	for b in beats:
		var model = str(b.model)
		var p = point(b.at)
		if zone == 4 and model in ["Valer","Aldric"]: refectory(p,model == "Aldric")
		if zone == 4 and model == "Aldric":
			furnish("table_trestle",p+Vector3(1.44,0,-.07),.84)
			furnish("bench",p+Vector3(2.69,0,-.03),.83,PI*.5)
			furnish("candle_cluster",p+Vector3(1.88,.70,.04),.58)
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
			furnish(
				["table_laid", "shelf_tall", "bed", "crate_stack"][i],
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
		"bowl":
			furnish("table_trestle", p, .73)
			put("pot", "#ab7854", p + Vector3.UP * .73, Vector3(.6, .15, .6))
			for j in range(3):
				put(
					"leaf",
					"#575631" if j < 2 else "#443935",
					p + Vector3((j - 1) * .13, .89, .13 if j == 1 else 0.),
					Vector3(.14, .09, .11)
				)
			furnish("armchair", p + Vector3(-1.22, 0, 0), .8, PI / 2)
			furnish("armchair", p + Vector3(.9, 0, -1.2), .75, -.7)
		"lamp":
			furnish("table_trestle", p, .63)
			put("pot", "#b27b53", p + Vector3.UP * .65, Vector3(.51, .35, .51))
			furnish("candle_cluster", p + Vector3(.38, .64, .1), .53)
		"fish":
			put("rock", "#bc805b", p + Vector3.UP * .2, Vector3(1.3, .42, .67))
			put(
				"cone",
				"#bf8762",
				p + Vector3(.6, .24, 0),
				Vector3(.52, .62, .52),
				Vector3(0, 0, 1.58)
			)
		"log":
			furnish("log", p + Vector3(2.5, 0, 0), 1.3, .34)
		"shelter":
			scenery("lodge_shell", p + Vector3(5.5, 0, -1), 5.8)
			furnish("candle_cluster", p + Vector3(.8, 0, .5))
		"wall":
			block(p + Vector3(-3.5, 0, 0), Vector3(4.8, 1.14, .67), "#baab8b")
			block(p, Vector3(2.15, .68, .66), "#c9ae85")
			block(p + Vector3(3.5, 0, 0), Vector3(4.8, 1.14, .67), "#baab8b")
		"basin", "portal", "well":
			if kind == "well":
				furnish("court_fountain",p,.56)
			else:
				basin(p,.88)
			tree(p + Vector3(-3.7, 0, 1.3), 5.3)
		"desk":
			furnish("table_laid", p, .78, PI / 2)
			furnish("armchair", p + Vector3(0, 0, -1.5), .76)
			block(p + Vector3(0, .8, .1), Vector3(.79, .08, .52), "#c18a65")
		"gate", "stone":
			furnish("lane_wall",p+Vector3(2.8,0,-1.15),.62,.12)
		"vista":
			furnish("bench_stone",p+Vector3(-1.65,0,.4),.90,.17)
		"pillar", "bell":
			put("shaft", "#dec79d", p, Vector3(2.65, 3.3, 2.65))
			furnish("banner_sheaf", p + Vector3(0, 0, .36), .84)
		"stall":
			shop(p, 1)
			furnish("cask_stack", p + Vector3(2.4, 0, 1), .79)
		"bed":
			furnish("bed", p, .85)
			furnish("bedside", p + Vector3(1.8, 0, -1), .8)
		"chest":
			furnish("chest", p, .95)
		"wheel":
			mill(p)
		"pipe":
			basin(p, 1.35)
			furnish("lane_wall",p + Vector3(0,0,-1.75),.47)
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
	if reversed:
		for w in wheels:
			w.rotation.z -= delta * .85
		for t in twigs:
			t[0].show()
			t[0].position = (
				t[1] + Vector3(.62 + sin(clock * 1.5) * .13, .26, fposmod(clock * .65, 6.) - 3.)
			)
	if ring:
		ring.scale = Vector3.ONE * (1.0 + sin(clock * 2) * .045)
	for actor in actors:
		if actor in directed or (walking_guide and actor.title == "Aldric"):
			continue
		if actor.position.distance_squared_to(player) < 42:
			actor.face(player)
		actor.motion(0, Vector3.ZERO, delta)


# An open-front refectory and a separate serving bay on the lamp terrace.
# The player's approach remains open. Walls, the hatch, the tables and the
# serving hand all use the same finished floor level on this sloping site.
func refectory(p: Vector3, serving: bool):
	var floor_size = Vector3(11.,.14,8.4)
	block(p-Vector3.UP*.13,floor_size,"wet_stone")
	for x in [-5.25,5.25]:
		block(p+Vector3(x,0,-1.63),Vector3(.42,2.8,4.9),"wet_stone")
		obstacles.append(Vector4(p.x+x,p.z-1.63,.21,2.45))
		for z in [1.32,3.9]: block(p+Vector3(x,0,z),Vector3(.23,3.48,.26),"sawn")
	# Serving window in the return wall, or a closed wall behind the benches.
	for run_ in [[-5.4,.55],[2.97,5.4]] if serving else [[-5.4,5.4]]:
		var x = (run_[0]+run_[1])*.5; var w = run_[1]-run_[0]
		block(p+Vector3(x,0,-4.05),Vector3(w,3.5,.48),"plaster")
		obstacles.append(Vector4(p.x+x,p.z-4.05,w*.5,.24))
	if serving:
		block(p+Vector3(1.76,0,-4.05),Vector3(2.42,1.04,.48),"wet_stone")
		block(p+Vector3(1.76,1.04,-4.05),Vector3(2.72,.12,.84),"sawn")
		block(p+Vector3(1.76,2.40,-4.05),Vector3(2.42,1.1,.48),"plaster")
		obstacles.append(Vector4(p.x+1.76,p.z-4.05,1.21,.24))
		block(p+Vector3(1.4,0,-6.15),Vector3(5.4,3.35,.35),"wet_stone")
		furnish("shelf_tall",p+Vector3(1.4,0,-5.48),1.,-.08)
		furnish("pot",p+Vector3(1.35,1.15,-3.99),.50,.21)
		furnish("jar_storage",p+Vector3(4.1,0,-3.19),.86)
	else:
		furnish("table_laid",p+Vector3(1.3,0,-.4),.87)
		furnish("bench",p+Vector3(2.35,0,-.4),.91,PI*.5)
	for z in [-3.5,-.6,2.3]:
		block(p+Vector3(0,3.4,z),Vector3(11.35,.24,.22),"sawn")
	# Broad shed roof; daylight enters through the front and side clerestories.
	put("box","sawn",p+Vector3(0,3.83,-.25),Vector3(11.8,.23,9.65),Vector3(-.055,0,0))
	var lamp_at = p+Vector3(-2.2,2.65,.39)
	furnish("lamp_lantern",lamp_at,.67)
	var light = OmniLight3D.new(); add_child(light); light.position = lamp_at+Vector3.DOWN*.23
	light.omni_range = 7.; light.light_energy = 1.65; light.light_color = Color("ffd0a0")


func district_art():
	if zone == 1:
		for i in range(7):
			scenery(
				"market_stall_a", loc(12 + i * 19, -11 if i % 2 else 11), 3.25, PI / 2 if i % 2 else -PI / 2
			)
	elif zone in [2, 3, 4, 5]:
		scenery("inn_shell", loc(95, -64), 11., .4)
		scenery("cap_tower", loc(77, -51), 15., -.7)
		scenery("lodge_shell", loc(66, 32), 11., -.75)
	else:
		scenery("cap_tower", loc(66, -32), 13., PI / 2)
		scenery("lodge_shell", loc(144, 44), 12., -.67)

	# Bespoke silhouettes anchor the teaching route; all ornament below shares draw batches.
	match zone:
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
				furnish("cask", loc(22 + i * 17, 11.0), .7 + i % 3 * .1)
		2:
			for i in range(3):
				var p = loc(32 + i * 5.5, -8)
				put("shaft", "#dcc6a3", p, Vector3(2.2, 4.5 + i * .3, 2.2))
				furnish(
					"banner_sheaf",
					p + Vector3(0, .7, .23),
					1.15
				)
			# The fired store jar is man-sized; test pots, kiln fuel and
			# the sorting table form a work spot, not an avenue of giants.
			scenery("jar_storage",loc(101.4,12.8),1.74,.2)
			for pair in [[98.2,11.5],[98.8,12.2],[99.4,11.7],[102.7,13.]]:
				furnish("pot",point(pair),rng.randf_range(.61,1.13),rng.randf_range(-PI,PI))
			furnish("table_trestle",loc(99.3,9.9),.86,-.72)
			furnish("cask_stack",loc(102.3,15.),.78,.3)
			for i in range(14):
				var p = loc(145 + i * 5, 30)
				tree(p, 4.5)
				put("leaf", "#b65343", p + Vector3(.45, 3.2, .23), Vector3(.34, .35, .36))
		3, 4:
			for row in range(3):
				var p = loc(20 + row * 89, 0)
				furnish("bench_stone",p+Vector3(-3.1,0,.4),1.,.12)
				var mast = p+Vector3(-4.7,0,.15)
				beam(mast,mast+Vector3.UP*3.15,.11,"sawn")
				furnish("banner_sheaf", mast-Vector3(0,0,.04), .97)
			for i in range(5):
				furnish("shelf_tall", loc(60 + i * 4.6, 13.3), .8, PI * .5)
				furnish("armchair", loc(105 + i * 4.2, -11.2), .76)
			for d in [38.,83.,137.]:
				furnish("table_laid",loc(d,8.6),.89,-.23)
				furnish("jar_storage",loc(d+1.2,9.7),.76,-.25)
				furnish("pot",loc(d-.9,9.4),.69,.13)
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
			for d in [37, 83, 140, 186]:
				var p = loc(d, 0)
				furnish("log",p+Vector3(7.1,0,.93),1.35,.32)
				var rack = loc(d,9.7)
				for post in [-1.5,1.5]:
					beam(rack+Vector3(0,-.13,post),rack+Vector3(0,.88,post),.18,"sawn")
				beam(rack+Vector3(0,.71,-1.65),rack+Vector3(0,.79,1.65),.16,"sawn")
	for i in range(25):
		var p = loc(rng.randf_range(1, length), rng.randf_range(14, 21) * (-1 if i % 2 else 1))
		if zone != 2 or -p.z > 45.: furnish("pot" if i % 3 else "jar_storage",p,rng.randf_range(.62,1.38),i*.79)


func person_on_set(who: String, where: Vector3):
	if not people.has(who):
		var a = Actor.new()
		add_child(a)
		a.make(who)
		people[who] = a
		actors.append(a)
	var actor = people[who]
	actor.position = where
	actor.show()
	return actor


func ensemble(pages: Array, at: Vector3, player: Vector3):
	var voices = []
	for line in pages:
		var who = str(line[0])
		if who == "Lyander" or (who == "Lyra" and zone > 0) or (who == "Matilda" and zone > 0):
			continue
		if who not in PEOPLE and who not in ["Boyacı", "Çömlekçi", "Değirmenci", "Mektupçu"]:
			continue
		if voices.has(who):
			continue
		voices.append(who)
		if (
			people.has(who)
			and people[who].visible
			and people[who].position.distance_to(player) < 5.7
		):
			continue
		var d = at - player
		d.y = 0
		d = d.normalized() if d.length_squared() > .02 else Vector3.FORWARD
		var p = (
			player
			+ d * (2.6 + voices.size() * .22)
			+ Vector3(d.z, 0, -d.x) * (1.35 if voices.size() % 2 else -1.65)
		)
		p.y = altitude(p.x, p.z)
		var a = person_on_set(who, p)
		a.face(player)
		a.rotation.y = a.heading


func object_at(kind: String, p: Vector3):
	landmark(kind, p)
	flush()


func window_water(p: Vector3) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(3.25, 4.6)
	n.mesh = q
	n.position = p + Vector3(0, 2.35, -1.5)
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/threshold.gdshader")
	n.material_override = mat
	add_child(n)
	return n


func mill(p: Vector3):
	var crank = Node3D.new()
	crank.position = p + Vector3(0, 1.3, -.4)
	add_child(crank)
	wheels.append(crank)
	var r = MeshInstance3D.new()
	var t = TorusMesh.new()
	t.inner_radius = 1.12
	t.outer_radius = 1.23
	t.rings = 40
	t.ring_segments = 6
	r.mesh = t
	r.material_override = Surfaces.get_material("boards",.86)
	r.rotation.x = PI / 2
	crank.add_child(r)
	for i in range(8):
		var a = i * TAU / 8.
		var bar = MeshInstance3D.new()
		bar.mesh = geometry("box")
		bar.scale = Vector3(.09, 1.12, .13)
		bar.rotation.z = -a
		bar.position = Vector3(sin(a), cos(a), 0) * .55
		bar.material_override = Surfaces.get_material("boards",.91)
		crank.add_child(bar)
		var vane = MeshInstance3D.new()
		vane.mesh = geometry("box")
		vane.scale = Vector3(.39, .2, .45)
		vane.position = bar.position * 2.09
		vane.rotation.z = -a
		vane.material_override = Surfaces.get_material("boards",.91)
		crank.add_child(vane)
	# Axle and trestles carry the wheel over a masonry race.
	for dz in [-.86,.81]:
		var pivot = crank.position + Vector3(0,0,dz)
		for sgn in [-1.,1.]: beam(pivot+Vector3(sgn*.92,-1.28,0),pivot,.16,"sawn")
	beam(crank.position+Vector3(0,0,-1.02),crank.position+Vector3(0,0,.97),.255,"sawn")
	var trough = MeshInstance3D.new()
	var q = PlaneMesh.new()
	q.size = Vector2(2.6, 8.6)
	trough.mesh = q
	trough.material_override = water_mat
	trough.position = p + Vector3.UP * .18
	add_child(trough)
	for x in [-1.44, 1.44]:
		block(p + Vector3(x, 0, 0), Vector3(.30, .44, 8.7), "wet_stone")
	var twig = MeshInstance3D.new()
	twig.mesh = geometry("rod")
	twig.material_override = material("#725039")
	twig.scale = Vector3(.10, .62, .1)
	twig.rotation.z = 1.36
	add_child(twig)
	twigs.append([twig, p])
	twig.hide()

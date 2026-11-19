extends "res://scripts/world.gd"
## One continuous set: the wet hillside opens onto the first occupied hearth,
## then the potters' street. The brook has a bed, two traversable routes and a current.
const START_DEPTH = -76.
const RILL = -34.
const SURFACE = 10.15
const LOG_X = -5.2
const FORD_X = 5.8
const FORD = "stones"
const LOG = "log"
var scene_kind = ""
var crossed_by = ""
var water: MeshInstance3D
var hearth: OmniLight3D
var locals: Array = []
var water_clock = 0.
var last_fog = -1.


func offset(x: float) -> float:
	return sin((x - center(RILL)) * .14) * .94


func channel(p: Vector3) -> float:
	return -p.z - (RILL + offset(p.x))


func bank(x: float, along: float) -> Vector3:
	var xx = center(RILL) + x
	var z = -(RILL + offset(xx) + along)
	return Vector3(xx, walk_height(xx, z), z)


func altitude(x: float, z: float) -> float:
	var dist = absf(channel(Vector3(x, 0, z)))
	var land = super.altitude(x, z)
	if dist > 10.: return land
	var riverbed = SURFACE - .84 + 1.14 * smoothstep(2.8, 4.7, dist)
	return lerpf(riverbed, land, smoothstep(5.3, 10., dist))


func walk_height(x: float, z: float) -> float:
	var base = altitude(x, z)
	var dist = absf(channel(Vector3(x, 0, z)))
	if dist < 4.5:
		var lane = x - center(RILL)
		if absf(lane - LOG_X) < .92:
			return maxf(base, SURFACE + .46)
		if absf(lane - FORD_X) < 1.55:
			return maxf(base, SURFACE + .16)
	return base


func passable(p: Vector3) -> bool:
	if -p.z < -12.:
		if -p.z < START_DEPTH - 4. or absf(p.x - center(-p.z)) > 16.: return false
		# Can't walk around the stream at the edge of the loaded hillside.
		if channel(p) > -4.15 and scene_kind in ["forest_shoe", "forest_bank"]: return false
		for rect in obstacles:
			if absf(p.x - rect.x) < rect.z + .26 and absf(p.z - rect.y) < rect.w + .26: return false
		return true
	return super.passable(p)


func crossing_lane(p: Vector3) -> String:
	return LOG if p.x < center(RILL) else FORD


func high_water() -> bool:
	return sin(water_clock * .96) > .47


# Empty = stable. Wrong footing returns the player to the near bank, never to town.
func footing(p: Vector3, low: bool, speed: float, jumping: bool) -> String:
	var d = channel(p)
	if absf(d) >= 3.75: return ""
	var x = p.x - center(RILL)
	if absf(x - LOG_X) < .90:
		return "" if low or speed < 1.65 else "Islak gövdede doğrulunca ayağın kaydı. Eğilerek geçebilirsin."
	if absf(x - FORD_X) < 1.35:
		# The raised centre stone is a refuge mid-crossing. A new surge only
		# matters at the last gap, which can be jumped or crossed as the water falls.
		return "Su son taşın üstünü örttü. Köpük çekilsin ya da dar aralıktan atla." if d > 1.6 and d < 2.75 and high_water() and not jumping else ""
	return "Çakıl ayağının altından boşaldı. Dalın uzandığı kıyıdan yeniden dene."


func setup(index: int, beats: Array, quality: bool):
	super.setup(index, beats, quality)
	for d in range(-83, 22, 3):
		for side in [-1., 1.]:
			for band in [0, 1]:
				var lane = side * (rng.randf_range(4.8, 11.7) if band == 0 else rng.randf_range(13.8, 28.))
				var p = loc(d + rng.randf_range(-1.1, 1.1), lane)
				if absf(channel(p)) < 7.: continue
				tree(p, rng.randf_range(8.6, 14.5), rng.randf() < .65)
				obstacles.append(Vector4(p.x,p.z,.22,.22))
			for j in range(4):
				var p = loc(d + j * .62, side * rng.randf_range(2.1, 16.))
				if absf(channel(p)) > 4.8: furnish("fern", p, rng.randf_range(2.2, 4.4), rng.randf_range(0, TAU))
	# Loosen the bank line with waterworn stones, runners and fallen brush.
	for step_ in range(50):
		var lane = rng.randf_range(-27.,28.); var side = -1. if step_%2 else 1.
		var p = bank(lane,side*rng.randf_range(3.8,5.7))
		if abs(lane-LOG_X)<1.4 or abs(lane-FORD_X)<1.6: continue
		var radius = rng.randf_range(.22,.68)
		put("rock","wet_stone",p,Vector3(radius,.48*radius,radius*.83),Vector3(0,rng.randf_range(0,TAU),.14))
		if step_%3==0:
			furnish("fern",p+Vector3(0,.06,-side*.60),rng.randf_range(1.6,2.8),lane)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-50, 51, 2):
		for o in [[0,-4.2], [2,4.2], [2,-4.2], [0,-4.2], [0,4.2], [2,4.2]]:
			var p = bank(x + o[0], o[1]); p.y = SURFACE
			st.set_normal(Vector3.UP); st.add_vertex(p)
	water = MeshInstance3D.new()
	water.mesh = st.commit()
	water.material_override = water_mat
	add_child(water)
	var log_p = bank(LOG_X, 0.); log_p.y = SURFACE - .36
	put("set_log", "atlas", log_p, Vector3(2.05,1.20,3.85), Vector3.ZERO)
	# Offset each stone so this reads as exposed, irregular rock, not a bridge.
	for j in range(7):
		var p = bank(FORD_X + sin(j * 1.8) * .33, -3.85 + j * 1.28)
		p.y = SURFACE - .19
		put("rock", "wet_stone", p, Vector3(2.3,.80,1.83), Vector3(.07,j*.84,.06))
	furnish("log", loc(-64, -2.8), 1.15, -1.05)
	var pile = loc(11.8,-3.2)
	for j in range(5):
		furnish("log",pile+Vector3((j%3)*.43-.4,.34 if j>2 else 0.,.13*sin(j)),.73,-PI*.48)
	furnish("sack_tied",pile+Vector3(.53,.73,.02),.54)
	furnish("fern",loc(-46.,4.) + Vector3(.62,0,0),3.3,-.3)
	furnish("fern",loc(-49.,-4.8),3.8,.8)
	hearth = OmniLight3D.new()
	hearth.position = loc(27.4, 5.8) + Vector3.UP * .70
	hearth.light_color = Color("ffad60"); hearth.omni_range = 6.
	add_child(hearth)
	furnish("pot", loc(27.7, 5.8), 1.05)
	furnish("bench", loc(28.25, 4.2), 1., .6)
	smoke_at(hearth.position + Vector3.UP * .22)
	for work in [["Su taşıyan", [71., 10.], [85., 6.], "jar_storage"], ["Yamak", [102., 12.], [95., 7.], "pot"], ["Hamurcu", [128., -9.], [138., -7.], "sack_tied"]]:
		var home = point(work[1]); var end = point(work[2])
		furnish("table_trestle", end + Vector3(0,0,-.9), .88, .2)
		locals.append({"who":work[0], "home":home, "end":end, "load":work[3], "actor":null, "clock":locals.size()*2.3, "carry":null})
	flush()


func smoke_at(p: Vector3):
	var ember = CPUParticles3D.new()
	ember.position = p; ember.amount = 22 if high else 12; ember.lifetime = 3.9
	ember.preprocess = 3.; ember.direction = Vector3.UP; ember.spread = 12.
	ember.initial_velocity_min = .73; ember.initial_velocity_max = 1.08
	ember.gravity = Vector3(.19,.16,-.08); ember.scale_amount_min = .65; ember.scale_amount_max = 1.35
	var q = QuadMesh.new(); q.size = Vector2(1.1,.90)
	var mat = ShaderMaterial.new(); mat.shader = preload("res://shaders/hearth_smoke.gdshader")
	q.material = mat; ember.mesh = q; ember.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ember)


func stage(b: Dictionary):
	super.stage(b)
	scene_kind = b.kind
	crossed_by = ""
	if b.kind.begins_with("forest_"):
		var at = point(b.at)
		if b.kind == "forest_cross": at = bank(LOG_X-1.65, -5.9)
		else: at = at + Vector3(-1.25,.02,-.45)
		at.y = altitude(at.x,at.z); person_on_set("Aldric", at)


func update_life(player: Vector3, dt: float):
	for w in locals:
		var near = player.distance_to(w.home) < 46.
		if w.actor == null and near:
			w.actor = Actor.new(); add_child(w.actor); w.actor.make(w.who)
			w.carry = MeshInstance3D.new(); w.carry.mesh = set_mesh(w.load)
			w.actor.add_child(w.carry); w.carry.scale = Vector3.ONE * .48; w.carry.position = Vector3(-.23,.88,.22)
		if w.actor == null: continue
		w.actor.visible = near
		w.actor.animator.active = near
		if not near: continue
		w.clock = fmod(w.clock + dt, 26.)
		var t = w.clock
		var outgoing = t < 13.
		var f = clampf((t - (2. if outgoing else 15.)) / 10.,0.,1.)
		var a: Vector3 = w.home if outgoing else w.end
		var b: Vector3 = w.end if outgoing else w.home
		var p = a.lerp(b, f); p.y = altitude(p.x, p.z)
		w.actor.position = p
		w.carry.visible = outgoing and t > 1.2 and t < 12.4
		if f > 0. and f < 1.:
			w.actor.motion(a.distance_to(b)/10., (b-a).normalized(), dt)
		else:
			w.actor.motion(0., Vector3.ZERO, dt)
			if w.actor.action_time <= 0.: w.actor.gesture("PickUp_Table", 1.7)


func frame(dt: float, player: Vector3, walking_guide = false):
	super.frame(dt,player,walking_guide)
	water_clock += dt
	water.position.y = sin(water_clock * .96) * .10
	hearth.light_energy = 1.35 + .19*sin(clock*7.) + .16*sin(clock*9.6)
	var opening = smoothstep(13.,65.,-player.z)
	if absf(last_fog - opening) > .012:
		last_fog = opening
		env.fog_density = lerpf(.019,.0034,opening)
		env.fog_light_color = Color("526861").lerp(Color("b9beb3"),opening)
		sun.light_energy = lerpf(.29,.48,opening)
		sun.light_color = Color("d4e0da").lerp(Color("ffe6c2"),opening)
		if env.volumetric_fog_enabled: env.volumetric_fog_density = lerpf(.025,.004,opening)
	update_life(player,dt)

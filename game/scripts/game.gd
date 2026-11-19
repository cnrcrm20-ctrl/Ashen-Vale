extends Node3D
const World = preload("res://scripts/world.gd")
const Haven = preload("res://scripts/haven.gd")
const Night = preload("res://scripts/kalkstein.gd")
const Direction = preload("res://scripts/direction.gd")
const Actor = preload("res://scripts/actor.gd")
const Interface = preload("res://scripts/interface.gd")
const Sound = preload("res://scripts/sound.gd")
const SLOT = "user://chapter-one-kalkstein.json"
const SETTINGS = "user://settings.cfg"
const SPELLS = ["Fitil", "Dipses", "Siper", "Yel Avucu"]
const ACTS = {"wick": 0, "water": 1, "guard": 2, "gust": 3}
const NOTES = [
	[
		[
			"Matilda'nın mührü",
			"Taştan oyulmuş mührün altında çatlak var. Mührün sağlam çıkması, içinde yazanın doğru olduğuna yetmez."
		],
		[
			"Bostan eşiği",
			"Lyander her geçtiğinde oynayan taşı eliyle düzeltiyor. Ev bazen seni tutan değil, topuğunun ezbere tanıdığı yer."
		],
		[
			"Çömlek balığı",
			"Yüzgeci bir kamış ucuyla çizilmiş. Gövdenin kırık kenarında Lyra'nın küçük parmak izi var."
		]
	],
	[
		[
			"Çivit tartısı",
			"İki kefeden birinin kordonu yeni örülmüş. Boyacı tezgâhı akşam bile sabun ve ceviz kabuğu kokuyor."
		],
		[
			"Tek çizmeli iz",
			"Sağda su, solda toz. İkisinden birini izlersen Aldric iki ayrı insan gibi görünür."
		],
		[
			"Kuru yalak",
			"Suyu olmayan taşın içinde bir başka gökyüzü duruyor. Eşikçiler her açıklığın yerini söylemez."
		]
	],
	[
		["Üç mühür", "Sarn, Meret, Ovaş. Ant taşına üçünün de işareti aynı yükseklikte oyulmuş."],
		[
			"Nar hattı",
			"Nar ağaçları bir duvar değil; güvenli yolun nerede bittiğini hatırlatan canlı bir sınır."
		],
		[
			"Küpler",
			"Bir ev boyundaki küp bir seferde pişmez. Çıraklar kat kat yükseltir; önceki günün kilini avuçla yoklar."
		]
	],
	[
		[
			"Gezgin ölçüsü",
			"Yıpranan ölçü yenisiyle yan yana saklanır. Bir şeyi eskidi diye atarsan ne kadar değiştiğini bilemezsin."
		],
		[
			"Altıncı tahta",
			"Ariadne ilk gece çarıklar için iki kişilik bir tahta buldu. Deftere yazılmayacak ilk okul kuralı."
		],
		["Kayıt çentiği", "Üç sütunun altı boş. Dorian ilk insan büyücünün adı için orada yer buldu."]
	],
	[
		[
			"Keten izi",
			"Fitil kısalınca yağı değil, önce isli ucu düşün. Usta öğle vakti bile eski kandili atmaz."
		],
		[
			"Sofradaki boşluk",
			"Edda bir kâseyi diğerlerinden sonra toplar. Hatırlamak her zaman yüksek sesle olmaz."
		],
		[
			"Akşam sayımı",
			"Ders bittiğinde kandil sayısı aday sayısına eşit olmalı. Kimse başkasının alevini başarı diye yazmaz."
		]
	],
	[
		["Sekiz çentik", "Her dalda bir koyu çentik: karanlığı tanımak, onu işlemek değildir."],
		[
			"Dafne'nin satırı",
			"Kuyudaki sıra uzuyor. Dafne sebep yazmamış; görmediğini yazmayı reddetmiş."
		],
		[
			"Yün disk",
			"Toz izi bir yara değil. Nerede erken davrandığını sabah yeniden gösterecek küçük bir ay."
		]
	],
	[
		[
			"Dünkü mühür",
			"Bu sabahın teslimi dün mühürlenmiş. Kayıtla ölçü henüz birbirini tutmuyor."
		],
		[
			"Tanık dalı",
			"Ariadne çarka dokunmak yerine incir sapını bıraktı. Su, eller çekilince de aynı yöne aktı."
		],
		[
			"Yol defteri",
			"Nar hattının ötesi boş bırakılmış. Sonraki çizgiyi evden değil yolun içinden çizecekler."
		]
	]
]
var data: Dictionary
var archive: Dictionary
var beats: Array
var zones: Array
var trips: Dictionary
var round_no = -1
var practice_disc
var movement_logged = false
var course_wave = 0.
var world
var direction
var hero
var ui
var audio
var camera: Camera3D
var canvas: CanvasLayer
var mode = "title"
var back_mode = "explore"
var active = false
var completed = false
var zone = -1
var index = 0
var beat: Dictionary = {}
var mask = 0
var learned: Array = []
var selected = 0
var records: Dictionary = {}
var findings: Array = []
var elapsed = 0.
var flags: Dictionary = {}
var autosave = 0.
var lines: Array = []
var line_no = 0
var after = "stage"
var ask: Dictionary = {}
var answer_action = ""
var active_question = ""
var focus_point = Vector3.ZERO
var options = {
	"high": true, "big": false, "volume": .75, "haptic": true, "dub": true, "guide": false
}
var move_vec = Vector2.ZERO
var touch_move = Vector2.ZERO
var touch_id = -1
var look_id = -1
var touch_origin = Vector2.ZERO
var velocity = Vector3.ZERO
var yaw = 0.
var pitch = .34
var run = false
var mouse_look = false
var last_step = 0.
var stick_clock = 0.
var last_nav = 0.
var pad_id = 0
var ribbon_time = 0.
var dash_time = 0.
var dash_dir = Vector3.ZERO
var vaulting = false
var vstart = Vector3.ZERO
var vend = Vector3.ZERO
var vt = 0.
var trail = false
var trail_d = 0.
var clues: Array = []
var clue_nodes: Array = []
var lore_nodes: Array = []
var lore_pos: Array = []
var feedback = ""
var feedback_t = 0.
var clock = 0.
var cooldown = 0.
var return_screen = "title"
var body_pos = Vector3.ZERO
var can_act = false
var current_target = Vector3.ZERO
var nearby_note = -1
var nearby_clue = -1
var ritual_mode = ""
var after_unlock = ""
var crossing = 0.
var cross_start = Vector3.ZERO
var camera_ready = false
var book_page = 0
var codex_page = 0
var last_goal_key = ""
var barks: Array = []
var bark_left = 0.
var spoken_left = 0.
var jumped = 0.
var gate_open = false
var portal_window: MeshInstance3D
var look_shake = 0.
var trigger_down = false


func read_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _ready():
	data = read_json("res://data/chapter.json")
	archive = read_json("res://data/archive.json")
	trips = read_json("res://data/excursions.json")
	beats = data.beats
	zones = data.zones
	var config = ConfigFile.new()
	if config.load(SETTINGS) == OK:
		for k in options:
			options[k] = config.get_value("game", k, options[k])
	apply_scale()
	audio = Sound.new()
	add_child(audio)
	audio.loudness(options.volume)
	audio.score("kalkstein")
	canvas = CanvasLayer.new()
	add_child(canvas)
	ui = Interface.new()
	canvas.add_child(ui)
	ui.big = options.big
	ui.command.connect(cmd)
	ui.option.connect(choose)
	ui.ritual_effect.connect(ritual_fx)
	ui.ritual_done.connect(pass_ritual)
	ui.board_sound.connect(func(id): audio.fx(id))
	get_viewport().size_changed.connect(fit_safe)
	ui.prepare_hud()
	camera = Camera3D.new()
	camera.fov = 62
	camera.far = 1400.
	camera.near = .12
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		camera.attributes = CameraAttributesPractical.new()
	add_child(camera)
	camera.current = true
	open_title()


func apply_scale():
	var vp = get_viewport()
	vp.mesh_lod_threshold = 2. if OS.has_feature("mobile") else 1.
	if OS.has_feature("mobile"):
		vp.scaling_3d_scale = .88 if options.high else .72
		vp.msaa_3d = Viewport.MSAA_DISABLED


func fit_safe():
	if OS.get_name() != "Android":
		return
	var safe = DisplayServer.get_display_safe_area()
	var raw = DisplayServer.window_get_size()
	var view = get_viewport().get_visible_rect().size
	if raw.x > 0 and raw.y > 0 and safe.size.x > 0:
		ui.offset_left = maxf(0, safe.position.x) * view.x / raw.x
		ui.offset_top = maxf(0, safe.position.y) * view.y / raw.y
		ui.offset_right = -maxf(0, raw.x - safe.end.x) * view.x / raw.x
		ui.offset_bottom = -maxf(0, raw.y - safe.end.y) * view.y / raw.y


func open_title():
	camera.environment = null
	silence()
	active = false
	if not is_instance_valid(world) or zone != 0:
		build_zone(0)
	world.stage(beats[0])
	hero.position = world.loc(1., .2)
	camera.position = world.loc(-2.15, 3.15) + Vector3.UP * 1.78
	camera.look_at(world.loc(7.4, -1.) + Vector3.UP * 1.15)
	camera.fov = 56.
	camera_ready = false
	mode = "title"
	print("AV_READY title")
	ui.title(FileAccess.file_exists(SLOT), slot_done())
	fit_safe()
	audio.score("kalkstein")


func slot_done() -> bool:
	if not FileAccess.file_exists(SLOT):
		return false
	var old = read_json(SLOT)
	return old is Dictionary and old.get("complete", false)


func settings_save():
	var c = ConfigFile.new()
	for k in options:
		c.set_value("game", k, options[k])
	c.save(SETTINGS)


func checkpoint():
	if not active or not is_instance_valid(hero):
		return
	var p = vstart if zone == 0 and vaulting else hero.position
	if zone == 2 and beat.kind == "forest_cross" and absf(world.channel(p)) < 4.65:
		p = world.bank(Haven.LOG_X if world.crossing_lane(p) == Haven.LOG else Haven.FORD_X,-5.3)
	var d = {
		"version": 2,
		"beat_key": beat_key(beat),
		"index": index,
		"zone": zone,
		"pos": [p.x, p.z],
		"yaw": yaw,
		"ducking": hero.crouched,
		"mask": mask,
		"learned": learned,
		"selected": selected,
		"records": records,
		"findings": findings,
		"flags": flags,
		"seconds": elapsed,
		"complete": completed
	}
	var f = FileAccess.open(SLOT + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.flush()
	f.close()
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(SLOT + ".tmp"), ProjectSettings.globalize_path(SLOT)
	)


func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		checkpoint()
		if is_instance_valid(audio): audio.hold_voice(true)
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(ui):
		back()


func beat_key(b: Dictionary) -> String:
	return "%s/%s/%s/%s" % [int(b.zone),b.kind,b.model,int(b.at[0])]


func start(restore: bool):
	var old = {}
	if restore and FileAccess.file_exists(SLOT):
		var raw = read_json(SLOT)
		if raw is Dictionary and raw.get("version", 0) == 2:
			old = raw
	index = clampi(int(old.get("index", 0)), 0, beats.size() - 1)
	if old.has("beat_key") and beat_key(beats[index]) != old.beat_key:
		for b in beats:
			if beat_key(b) == old.beat_key:
				index = int(b.id)
				break
	records = old.get("records", {})
	findings = old.get("findings", [])
	learned = []
	for spell in old.get("learned", []):
		if int(spell) in [0, 1, 2, 3] and not learned.has(int(spell)):
			learned.append(int(spell))
	flags = old.get("flags", {})
	selected = clampi(int(old.get("selected", 0)), 0, 3)
	mask = int(old.get("mask", 0))
	elapsed = float(old.get("seconds", 0))
	silence()
	completed = false
	active = true
	zone = -1
	run = false
	trail = false
	vaulting = false
	dash_time = 0
	feedback = ""
	clear_input()
	enter(index, true)
	hero.crouched = bool(old.get("ducking", false))
	if zone == 0:
		world.ducking = hero.crouched
	if old.has("pos") and int(old.get("zone", -1)) == zone:
		var saved = Vector3(old.pos[0], 0, old.pos[1])
		saved.y = world.walk_height(saved.x, saved.z)
		if world.passable(saved):
			hero.position = saved
		yaw = old.get("yaw", 0.)
		camera_ready = false
	if old.get("complete", false):
		completed = true
		cmd("end_back")
	checkpoint()


func clear_input():
	touch_id = -1
	look_id = -1
	touch_move = Vector2.ZERO
	mouse_look = false
	velocity = Vector3.ZERO
	if is_instance_valid(ui):
		ui.stick_pos(Vector2.ZERO)


func build_zone(z: int):
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	zone = z
	portal_window = null
	world = Night.new() if zone == 0 else (Haven.new() if zone == 2 else World.new())
	world.name = "District" + str(zone)
	add_child(world)
	var local: Array = []
	for b in beats:
		if int(b.zone) == zone:
			local.append(b)
	world.setup(zone, local, options.high)
	direction = Direction.new()
	world.add_child(direction)
	direction.world = world
	for trip in trips.values():
		if int(trip.zone) == zone:
			for row in trip.stops:
				if row.model not in World.PEOPLE:
					world.landmark(row.model, world.point(row.at))
	world.flush()
	hero = Actor.new()
	world.add_child(hero)
	hero.make("Lyander")
	hero.position = world.loc(1, .18) if zone == 0 else world.loc(Haven.START_DEPTH if zone == 2 else 0., 0.)
	hero.heading = PI
	hero.rotation.y = PI
	yaw = 0
	pitch = .33
	camera_ready = false
	clue_nodes = []
	lore_nodes = []
	lore_pos = []
	for i in range(3):
		var p = world.loc(world.length * (.19 + i * .28), -12 if i % 2 == 0 else 13)
		if zone == 0:
			p = world.point([[22.6, -3.25], [50.6, 2.4], [41., 2.4]][i])
		lore_pos.append(p)
		var n = findable(p, i, false)
		lore_nodes.append(n)
		n.visible = not findings.has("%s:%s" % [zone, i])
		if zone == 0:
			n.mesh = null  # the seal, loose stone and well are the discoverable props
	audio.ambience_at("rain" if zone == 0 else ("stream" if zone in [2, 6] else ""), world.bank(0,-1.) if zone == 2 else world.loc(37., 1.))
	audio.fire_at(world.lantern if zone == 0 else (world.hearth if zone == 2 else null))
	audio.score("kalkstein" if zone < 2 else ("vadi" if zone in [2, 6] else "olcu"))


func findable(p: Vector3, i: int, clue: bool) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	world.add_child(m)
	m.position = p
	if zone == 0: return m  # existing props are the inspectable objects here
	var props = [
		[], ["log","banner_sheaf","plate"], ["bench_stone","banner_sheaf","bench_stone"],
		["bed","bedside","table_laid"], ["pot","candle_cluster","jar_storage"],
		["bench_stone","plate","banner_sheaf"], ["jar_storage","pot","lane_wall"]
	]
	var id = props[zone][i] if clue else ["sack_tied","plate","pot"][i]
	m.mesh = world.set_mesh(id)
	m.scale = Vector3.ONE * (.72 if clue else .92)
	if zone == 1 and clue:
		if i == 0:
			m.mesh = world.geometry("rock"); m.scale = Vector3(.20,.024,.34)
			m.position.y += .025; m.material_override = world.material("#504d44")
		elif i == 2:
			m.material_override = world.water_mat; m.scale = Vector3(2.4,.92,2.4)
	return m


func enter(i: int, restore = false):
	if is_instance_valid(direction):
		if direction.remembering: camera_ready = false
		direction.reset()
	silence()
	jumped = 0.
	gate_open = false
	look_shake = 0.
	round_no = -1
	if is_instance_valid(practice_disc):
		practice_disc.queue_free()
	practice_disc = null
	index = i
	print("AV_BEAT ", i)
	beat = beats[index]
	var different = int(beat.zone) != zone
	if different:
		build_zone(int(beat.zone))
	if not restore:
		mask = 0
	for n in clue_nodes:
		if is_instance_valid(n):
			n.queue_free()
	clue_nodes = []
	clues = []
	trail = false
	vaulting = false
	if zone == 0 and world.route != str(flags.get("passage", "")):
		world.set_route(str(flags.get("passage", "")))
	world.stage(beat)
	if beat.kind == "gate" and flags.get("open_water", false):
		open_water()
	if is_instance_valid(hero.mark):
		hero.show_mark(zone >= 2 or beat.model == "mark" or flags.has("revealed"))
	if zone == 6:
		world.reversed = (
			(beat.model == "wheel" and beat.kind == "look") or flags.has("reverse_current")
		)
	if beat.model == "mark":
		flags["revealed"] = true
	if beat.kind == "search":
		for j in range(3):
			var p = world.loc(
				float(beat.at[0]) + [-6, 4, 9][j],
				clampf(float(beat.at[1]) + [5, -7, 5][j], -12, 12)
			)
			clues.append(p)
			var n = findable(p,j,true)
			clue_nodes.append(n)
			n.visible = (mask & (1 << j)) == 0
	if beat.kind in ["testguard", "testgust", "testwater"] and world.people.has("Ariadne"):
		world.people["Ariadne"].position = world.loc(beat.at[0] - 1, beat.at[1] + 2)
	if different and zone != 0:
		mode = "ribbon"
		ribbon_time = 3.65
		ui.ribbon(zones[zone].name, zones[zone].subtitle)
		audio.fx("seal", .65)
	else:
		explore()
	ui.set_goal(zones[zone].name, beat.title)
	if zone == 0 and beat.kind == "night_pass":
		ui.set_goal(zones[zone].name, "Mutfak kapısından kuyuya çık" if world.route == Night.KITCHEN else "Kilerde eğil, alçak eşiğin altından geç")
	barks = beat.get("entry", []).duplicate()
	bark_left = .18
	if restore and trips.has(beat.kind) and flags.has(stop_key()):
		set_round(int(flags[stop_key()]))
	last_goal_key = ""
	clear_input()


func explore():
	mode = "explore"
	print("AV_WALK")
	ui.gameplay()
	clear_input()
	world.way.visible = options.guide and zone != 0 and not beat.kind.begins_with("forest_")


func advance():
	silence()
	records[str(index)] = beat.title
	if index + 1 >= beats.size():
		completed = true
		checkpoint()
		mode = "end"
		(
			ui
			. basic(
				"Görünce çizeriz.",
				"BİRİNCİ BÖLÜM TAMAMLANDI",
				[["YOL DEFTERİ", "journal"], ["ANA MENÜ", "title"]],
				(
					"İki kayıt, kil balığın kuyruğu ve Lyra'nın mektubu seninle. İğdegediği yolu yarına kaldı.   •   %d dakika"
					% int(elapsed / 60)
				)
			)
		)
		audio.fx("seal")
		return
	enter(index + 1)
	checkpoint()


func message(t: String):
	feedback = t
	feedback_t = 3.8


func silence():
	barks.clear()
	bark_left = 0.
	spoken_left = 0.
	if is_instance_valid(audio):
		audio.quiet()
	if is_instance_valid(ui):
		ui.caption("")


func say(line: Array, point: Vector3) -> float:
	var speaker = hero if line[0] == "Lyander" else world.people.get(line[0])
	return audio.speak(line, speaker, point, options.dub)


func voices_tick(dt: float):
	var held = mode not in ["explore", "dialog"]
	audio.hold_voice(held)
	if held:
		return
	if mode == "dialog":
		if spoken_left > 0.:
			spoken_left -= dt
			if spoken_left <= 0.:
				next_line()
		return
	bark_left = maxf(0., bark_left - dt)
	if bark_left > 0.:
		return
	if barks.is_empty():
		ui.caption("")
		return
	var row = barks.pop_front()
	ui.caption("%s  ·  %s" % [row[0], row[1]])
	bark_left = maxf(say(row, hero.position), float(str(row[1]).length()) / 19.) + .30


func conversation(pages: Array, continuation: String, at: Vector3):
	silence()
	world.ensemble(pages, at, hero.position)
	lines = pages.duplicate(true)
	after = continuation
	line_no = 0
	focus_point = at
	mode = "dialog"
	clear_input()
	world.way.hide()
	hero.face(at)
	show_line()


func show_line():
	print("AV_LINE ", index, ":", line_no)
	var ln = lines[line_no]
	ui.dialogue(ln[0], ln[1], "%02d  /  %02d" % [line_no + 1, lines.size()])
	var previous = direction.remembering
	direction.on_line(beat, ln[0], ln[1], hero)
	if line_no == 0 or previous != direction.remembering or ln[0] != lines[line_no-1][0]:
		camera_ready = false
	var duration = say(ln, focus_point)
	spoken_left = duration + .36 if options.dub and duration > 0 else 0.
	var person = hero if ln[0] == "Lyander" else world.people.get(ln[0], null)
	if is_instance_valid(person):
		var clip = "Idle_Talking_Loop"
		if ln[0] == "Matilda": clip = "Idle_No_Loop"
		elif ln[0] == "İskele kâtibi": clip = "Idle_FoldArms_Loop"
		elif beat.kind == "night_fish" and ln[0] == "Lyra": clip = "PickUp_Table"
		person.gesture(clip, maxf(1.4, duration))


func next_line():
	silence()
	line_no += 1
	audio.fx("tap", .36)
	if line_no < lines.size():
		show_line()
		return
	match after:
		"round":
			set_round(round_no + 1)
		"stage":
			if beat.has("ask"):
				ask_user_game(beat.ask, "authored")
			else:
				stage_action()
		"clue":
			if mask == 7:
				conversation(beat.lines, "stage", world.point(beat.at))
			else:
				explore()
		"complete":
			advance()
		"ritual":
			open_ritual()
		"retry":
			ask_user_game(ask, active_question)
		"chosen":
			stage_action()
		_:
			explore()


func ask_user_game(q: Dictionary, which: String):
	ask = q
	active_question = which
	mode = "choice"
	ui.question(q.q, q.options)


func choose(n: int):
	if mode != "choice" or n < 0 or n >= ask.options.size():
		return
	var ok = int(ask.correct) < 0 or n == int(ask.correct)
	var response = str(ask.options[n][1])
	var sp = "Lyander"
	if ": " in response:
		var a = response.split(": ", true, 1)
		sp = a[0]
		response = a[1]
	audio.fx("seal" if ok else "miss", .6)
	if active_question == "spell" and ok:
		selected = int(ask.correct)
		conversation([[sp, response]], "ritual", world.point(beat.at))
		return
	if ok:
		flags["choice_" + str(index)] = str(ask.options[n][0])
		checkpoint()
	conversation([[sp, response]], "chosen" if ok else "retry", world.point(beat.at))


func stage_action():
	var k = str(beat.kind)
	if trips.has(k):
		set_round(0)
	elif k.begins_with("chart"):
		mode = "chart"
		clear_input()
		ui.chart(int(k.right(1)))
	elif k in ["wick", "water", "dodge", "guard", "gust"]:
		ritual_mode = k
		open_ritual()
	elif k.begins_with("test"):
		ritual_mode = k
		var need = int(ACTS[k.trim_prefix("test")])
		var opts = []
		for j in range(4):
			opts.append(
				[
					SPELLS[j],
					(
						"Ölçüyü burada deneyebilirim."
						if j == need
						else "Bu dal başka bir işe yarıyor. Çevreyi ve dersteki işareti hatırla."
					)
				]
			)
		ask_user_game(
			{"q": "Bu ölçü için hangi büyüyü hazırlarsın?", "correct": need, "options": opts},
			"spell"
		)
	elif k == "gate":
		open_water()
		flags["open_water"] = true
		checkpoint()
		explore()
		ui.set_goal("Su Eşiği", "Suyun öbür yanına adım at")
	elif k == "trail":
		explore()
		trail = true
		trail_d = float(beat.at[0])
		message("Islak izleri takip et. Eşikçi seni yalağın önünde yakalayacak.")
	elif k == "vault":
		explore()
		vaulting = true
		vt = 0.
		vstart = hero.position
		vend = world.loc(beat.at[0] + 3.0, beat.at[1])
		hero.gesture("Jump_Start", .85)
		audio.fx("step")
	else:
		advance()


func open_water():
	gate_open = true
	cross_start = hero.position
	var center_ = world.point(beat.at)
	if not is_instance_valid(portal_window):
		portal_window = world.window_water(center_)
	world.person_on_set("Aldric", center_ + Vector3(-1.9, 0, -.9)).gesture("Spellcasting", 1.3)
	audio.at("water", center_, .76)


func open_ritual():
	mode = "ritual"
	clear_input()
	focus_point = world.point(beat.at)
	ui.exercise(ritual_mode, index)


func ritual_fx(id: String, ok: bool):
	var key = id if id != "dodge" else "wind"
	audio.at(key if ok else "miss", hero.position + Vector3.UP)
	hero.gesture(
		(
			("Block" if id == "shield" else ("Dodge_Left" if id == "dodge" else "Spellcast_Shoot"))
			if ok
			else "Hit_A"
		),
		.65
	)
	burst(hero.position + Vector3.UP * .88, key, ok)
	if ok and options.haptic:
		Input.vibrate_handheld(28)
		Input.start_joy_vibration(pad_id, .18, .11, .10)


func pass_ritual():
	if mode != "ritual":
		return
	if ritual_mode == "testgust":
		flags["reverse_current"] = true
		world.reversed = true
	var k = ritual_mode.trim_prefix("test")
	if ACTS.has(k):
		var id = int(ACTS[k])
		if not learned.has(id):
			learned.append(id)
			message(SPELLS[id] + "  ·  Yol defterine işlendi")
		selected = id
	advance()


func burst(at: Vector3, key: String, ok = true):
	if not is_instance_valid(world):
		return
	var colors = {
		"ember": Color("ffb057"),
		"water": Color("7ce8de"),
		"shield": Color("c6e4ff"),
		"wind": Color("e4e9b0"),
		"seal": Color("f4cf8e")
	}
	var color: Color = colors.get(key, Color("c3c9b5")) if ok else Color("cd987e")
	var m = StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color, .88)
	for i in range(3):
		var n = MeshInstance3D.new()
		var t = TorusMesh.new()
		t.inner_radius = .44
		t.outer_radius = .48
		t.rings = 32
		t.ring_segments = 5
		n.mesh = t
		n.material_override = m
		world.add_child(n)
		n.position = at + Vector3.UP * .1 * i
		if key == "shield":
			n.rotation.x = PI / 2
			n.rotation.y = hero.rotation.y
		var tw = n.create_tween()
		tw.tween_interval(.065 * i)
		(
			tw
			. tween_property(n, "scale", Vector3.ONE * (2.3 + i * .45), .42)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)
		tw.tween_callback(n.queue_free)
	for i in range(8):
		var n = MeshInstance3D.new()
		n.mesh = world.geometry("rock")
		n.material_override = m
		world.add_child(n)
		n.position = at
		n.scale = Vector3.ONE * .085
		var a = i * TAU / 8
		var tw = n.create_tween().set_parallel(true)
		tw.tween_property(n, "position", at + Vector3(cos(a), .7 + sin(i), sin(a)) * 1.25, .47)
		tw.tween_property(n, "scale", Vector3.ONE * .001, .48)
		tw.chain().tween_callback(n.queue_free)


func terrain_target() -> Vector3:
	nearby_clue = -1
	if zone == 0:
		return world.destination(beat, hero.position)
	if beat.kind == "forest_cross":
		var x = Haven.LOG_X if world.crossing_lane(hero.position) == Haven.LOG else Haven.FORD_X
		return world.bank(x, 5.5)
	if gate_open:
		return world.point(beat.at) + Vector3(0, 0, -1.5)
	if round_no >= 0:
		return world.point(current_stop().at)
	if trail:
		return world.people["Aldric"].position
	if beat.kind == "search" and mask != 7:
		var best = INF
		for i in range(3):
			if mask & (1 << i):
				continue
			var dd = hero.position.distance_squared_to(clues[i])
			if dd < best:
				best = dd
				nearby_clue = i
		if nearby_clue >= 0:
			return clues[nearby_clue]
	return world.point(beat.at)


func interact():
	if mode != "explore" or vaulting:
		return
	current_target = terrain_target()
	var ds = hero.position.distance_to(current_target)
	if nearby_note >= 0 and (ds > 4.25 or trail):
		var i = nearby_note
		var key = "%d:%d" % [zone, i]
		findings.append(key)
		lore_nodes[i].hide()
		nearby_note = -1
		checkpoint()
		audio.fx("seal")
		conversation([[NOTES[zone][i][0], NOTES[zone][i][1]]], "back", lore_pos[i])
		return
	if trail:
		message("Aldric'in ıslak izlerinden ayrılma.")
		return
	if zone == 0:
		if ds > night_reach() or not night_access(current_target):
			return
		match beat.kind:
			"night_fork":
				var chosen = world.closest_route(hero.position)
				flags["passage"] = chosen
				flags["choice_" + str(index)] = "Tavaları düşürdüm; fener mutfağa döndü." if chosen == Night.KITCHEN else "Kiler anahtarını aldım; nöbetçi sofada kaldı."
				world.set_route(chosen, true)
				audio.at("clatter" if chosen == Night.KITCHEN else "tap", current_target)
				hero.gesture("Interact", .55)
				advance()
				return
			"night_pass", "night_out":
				advance()
				return
			"night_chase":
				start_vault()
				return
	if zone == 2 and beat.kind.begins_with("forest_"):
		if beat.kind == "forest_cross": return
		if beat.kind == "forest_bank" and ds > 2.6 and hero.position.distance_to(world.loc(-49.,-4.8)) < 2.5:
			message("Damlalar susunca su hâlâ duyuluyor. Öteki kıyıda yapraklar hep bir yana yatmış.")
			audio.at("tap", hero.position, .35)
			return
		if ds > 2.6: return
		if beat.kind == "forest_shoe" and not hero.crouched:
			message("Kayışı çekme. Eğil, çarığı kökün dibinden yana çevir.")
			return
		if beat.kind == "forest_ember" and -hero.position.z < 12. and not hero.crouched:
			message("Bu yüzü yağmur yemiş. Saçağın tarafından yokla ya da kütüğün altına eğil.")
			return
		hero.gesture("Interact", .85)
	if gate_open:
		return  # The last step is locomotion, never a second conversation or teleport.
	if ds > 4.45:
		message(beat.title)
		return
	if round_no >= 0:
		round_interact()
		return
	if beat.kind == "search" and mask != 7 and nearby_clue >= 0:
		var i = nearby_clue
		mask |= 1 << i
		clue_nodes[i].hide()
		hero.gesture("PickUp")
		checkpoint()
		conversation([[beat.clues[i][0], beat.clues[i][1]]], "clue", current_target)
		audio.fx("tap")
		return
	if beat.kind == "surge":
		var at = hero.mark_pose().origin if is_instance_valid(hero.mark) else hero.position + Vector3.UP
		burst(at, "water")
		audio.at("water", at)
		hero.gesture("Hit_Chest", .85)
		look_shake = .60
	var pages = beat.lines.duplicate(true)
	if beat.model == "shelter" and flags.has("brook"):
		pages.push_front(["Lyander", "Eğilirken cebimi tuttum. Balığın kuyruğuna bir şey olmamış." if flags.brook == Haven.LOG else "Taşın üstünde suyu beklerken cebim ıslandı. Bakayım… balık hâlâ burada."])
	conversation(pages, "stage", current_target)
	audio.fx("tap", .65)


func night_reach() -> float:
	return 2.45 if beat.kind == "night_chase" else 1.9


func night_access(p: Vector3) -> bool:
	if beat.kind == "night_chase": return absf(hero.position.x) < 1.65
	return not world.opaque(hero.position + Vector3.UP * 1.12, p + Vector3.UP * 1.12)


func start_vault():
	vaulting = true
	vt = 0.
	vstart = hero.position
	vend = world.loc(54.25, clampf(hero.position.x, -1., 1.))
	hero.crouched = false
	world.ducking = false
	hero.gesture("Jump_Start", .70)
	audio.at("step", vstart)


func crouch():
	if mode != "explore" or vaulting: return
	if zone == 0 and hero.crouched and world.route == Night.CELLAR and absf(-hero.position.z - 34.4) < .95:
		return
	hero.crouched = not hero.crouched
	if hero.crouched: run = false
	if zone == 0: world.ducking = hero.crouched


func jump():
	if mode != "explore" or jumped > 0. or vaulting or hero.crouched: return
	if beat.kind == "night_chase" and hero.position.distance_to(terrain_target()) < night_reach() and night_access(terrain_target()):
		start_vault()
		return
	jumped = .60
	hero.gesture("Jump_Start", .6)
	audio.at("step", hero.position, .35)


func cast():
	if mode != "explore" or learned.is_empty() or cooldown > 0:
		return
	if field_cast():
		return
	if str(beat.kind).begins_with("test") and hero.position.distance_to(terrain_target()) < 4.5:
		interact()
		return
	cooldown = .75
	var key = ["ember", "water", "shield", "wind"][selected]
	hero.gesture("Block" if selected == 2 else "Spellcast_Shoot", .70)
	burst(hero.position + Vector3.UP * 1.0, key)
	audio.at(key, hero.position + Vector3.UP)
	message(SPELLS[selected])


func cycle_spell(dir = 1):
	if learned.is_empty():
		return
	selected = int(learned[posmod(learned.find(selected) + dir, learned.size())])
	audio.fx("tap", .4)
	message(SPELLS[selected] + " hazır")


func dodge():
	if mode != "explore" or cooldown > 0 or vaulting:
		return
	if beat.kind == "vault" and hero.position.distance_to(terrain_target()) < 4.45:
		interact()
		return
	dash_dir = (
		velocity.normalized()
		if velocity.length() > .2
		else Vector3(sin(hero.heading), 0, cos(hero.heading))
	)
	dash_time = .37
	cooldown = .78
	hero.gesture("Dodge_Forward", .50)
	audio.fx("wind", .56)


func _physics_process(dt):
	if not active or not is_instance_valid(hero):
		return
	var delta = minf(dt, .05)
	clock += delta
	voices_tick(delta)
	cooldown = maxf(cooldown - delta, 0.)
	last_nav = maxf(0, last_nav - delta)
	if (
		mode
		not in [
			"pause", "settings", "journal", "reading", "codex", "credits", "title", "confirm", "end"
		]
	):
		elapsed += delta
		autosave += delta
	if autosave > 12.:
		autosave = 0.
		checkpoint()
	if mode == "crossing":
		crossing += delta
		var t = smoothstep(.14, 2.85, crossing)
		var target = world.point(beat.at) + Vector3(0, 0, -1.75)
		var dir = (target - cross_start).normalized()
		hero.position = cross_start.lerp(target, t) + Vector3.DOWN * .20 * t
		hero.motion(1.45, dir, delta)
		var focus = hero.position + Vector3.UP
		var rail = focus + Vector3(3.7 - t, 1.14, 4.3 - t * 1.3)
		camera.position = camera.position.lerp(rail, 1. - exp(-delta * 3.))
		camera.look_at(focus)
		world.frame(delta, hero.position)
		camera.fov = lerpf(camera.fov, 48., delta * 3.)
		if crossing >= 3.25:
			advance()
		return
	if mode == "ribbon":
		ribbon_time -= delta
		if ribbon_time <= 0:
			explore()
	if mode in ["explore", "ribbon", "dialog", "choice", "ritual"]:
		world.frame(delta, hero.position, trail)
		if mode == "dialog": direction.tick(delta)
	if mode == "explore":
		if vaulting:
			vt = minf(1, vt + delta * 1.32)
			hero.position = vstart.lerp(vend, vt) + Vector3.UP * sin(vt * PI) * 1.35
			if vt >= 1:
				vaulting = false
				hero.gesture("Jump_Land", .35)
				advance()
		else:
			walk(delta)
		field_frame(delta)
		if zone == 0 and not vaulting:
			if world.tick_patrol(delta, hero.position, velocity.length()):
				hero.position = world.retry_position()
				camera_ready = false
				clear_input()
				audio.at("miss", hero.position, .65)
				message("Duvarın gölgesine dön. Ortadaki alçak taşı aş." if beat.kind == "night_chase" else "Fener sana döndü. Sandıkların ardında ışığın geçmesini bekle.")
			world.step_clock += delta * (2.5 if beat.kind == "night_chase" else 1.25)
			if world.step_clock >= 1.:
				world.step_clock = 0.
				audio.foot("rock", world.guard.position, .58)
		if beat.kind == "forest_cross" and world.crossed_by != "" and world.channel(hero.position) > 4.25:
			flags.brook = world.crossed_by
			flags["choice_" + str(index)] = "Çayı devrik çamın üstünden geçtim." if flags.brook == Haven.LOG else "Çayı sığ taşlardan geçtim."
			advance()
			return
		if gate_open and velocity.length() > .08 and hero.position.distance_to(cross_start) > .30 and hero.position.distance_to(terrain_target()) < .95:
			gate_open = false; mode = "crossing"; crossing = 0.; cross_start = hero.position
			clear_input(); ui.hud.hide(); world.way.hide()
			return
		if trail:
			var guide = world.people["Aldric"]
			var old = guide.position
			var dist = hero.position.distance_to(old)
			if dist < 18:
				trail_d = minf(
					float(beats[index + 1].at[0]) - 3.2,
					trail_d + delta * (2.7 if dist < 6 else 2.0)
				)
			guide.position = world.loc(trail_d, sin(trail_d * .09) * 1.15)
			var f = guide.position - old
			guide.motion(f.length() / delta, f.normalized(), delta)
			if int(trail_d * 1.2) % 6 == 0 and f.length() > 0 and int(clock * 15) % 11 == 0:
				footprint(guide.position)
			if trail_d >= float(beats[index + 1].at[0]) - 3.21 and dist < 5:
				trail = false
				burst(guide.position + Vector3.UP, "water")
				guide.hide()
				advance()
		current_target = terrain_target()
		var distance = hero.position.distance_to(current_target)
		nearby_note = -1
		for i in range(lore_pos.size()):
			if lore_nodes[i].visible and hero.position.distance_to(lore_pos[i]) < (1.5 if zone == 0 else 3.5) and (zone != 0 or night_access(lore_pos[i])):
				nearby_note = i
				break
		can_act = (distance < 4.45 and not trail and not gate_open) or nearby_note >= 0
		if zone == 0:
			can_act = (distance < night_reach() and night_access(current_target)) or (nearby_note >= 0 and distance > 4.25)
		world.way.position = current_target + Vector3.UP * .07
		world.way.visible = options.guide and zone != 0 and not beat.kind.begins_with("forest_")
		var px = (
			camera.unproject_position(current_target + Vector3.UP * 1.8)
			if not camera.is_position_behind(current_target)
			else Vector2(get_viewport().get_visible_rect().size.x * .5, 10000)
		)
		var act = "Konuş" if beat.model in World.PEOPLE else "İncele"
		if round_no >= 0:
			act = "Ölçü ipucu" if int(current_stop().spell) >= 0 else "İncele"
		if beat.kind == "vault":
			act = "Duvarı aş"
		if nearby_note >= 0 and distance > 4.25:
			act = "Notu al"
		if beat.kind == "search" and nearby_clue >= 0:
			act = "İzi oku"
		if zone == 0:
			match beat.kind:
				"night_fork": act = "Tavaları düşür" if world.closest_route(hero.position) == Night.KITCHEN else "Anahtarı al"
				"night_hear": act = "Kulak ver"
				"night_fish": act = "Kuyruğu al"
				"night_chase": act = "Duvarı aş"
				"night_pass", "night_out": act = "Geç"
			if nearby_note >= 0 and distance > 4.25: act = "İncele"
		if beat.kind.begins_with("forest_"):
			can_act = distance < 2.6 and beat.kind != "forest_cross"
			match beat.kind:
				"forest_shoe": act = "Kayışı gevşet"
				"forest_bank":
					can_act = can_act or hero.position.distance_to(world.loc(-49.,-4.8)) < 2.5
					act = "Kulak ver"
				"forest_ember": act = "Yongayı yokla"
		ui.guidance(
			px,
			distance,
			can_act,
			act,
			SPELLS[selected] if learned.has(selected) else "",
			feedback if feedback_t > 0 else ("Aldric'i görüşte tut" if trail else "")
		)
		ui.marker.visible = ui.marker.visible and options.guide
		ui.scene_badge.text = (
			("KANIT  %d / 3" % ((mask & 1) + ((mask >> 1) & 1) + ((mask >> 2) & 1)))
			if beat.kind == "search"
			else ""
		)
		if beat.kind.begins_with("forest_"):
			ui.marker.hide()
			if beat.kind == "forest_cross": ui.scene_badge.text = "Köpük son taşı örtüyor" if world.high_water() else "Son taş göründü"
		if zone == 0:
			ui.marker.hide()
			if can_act and beat.kind == "night_wake" and last_goal_key != "lyra":
				last_goal_key = "lyra"
				print("AV_NEAR Lyra")
			if world.suspicion > .05:
				ui.scene_badge.text = "Sesini duydu" if world.heard else "Fener sana dönüyor"
			elif beat.kind == "night_chase":
				ui.scene_badge.text = "Ayak sesleri çok yakın" if world.chase_gap < 2.65 else "Bostana!"
		feedback_t -= delta
	elif mode in ["dialog", "choice", "ribbon", "ritual"]:
		hero.motion(0, Vector3.ZERO, delta)
	if mode in ["explore", "dialog", "choice", "ribbon", "ritual"]:
		follow(delta)


func footprint(p: Vector3):
	var n = MeshInstance3D.new()
	n.mesh = world.geometry("rock")
	n.material_override = world.material("#557f83")
	world.add_child(n)
	n.position = p + Vector3.UP * .04
	n.scale = Vector3(.19, .018, .34)
	var tw = n.create_tween()
	tw.tween_interval(5)
	tw.tween_property(n, "scale", Vector3.ZERO, .55)
	tw.tween_callback(n.queue_free)


func walk(dt):
	var axes = touch_move
	var pads = Input.get_connected_joypads()
	if not pads.is_empty():
		pad_id = pads[0]
		var ax = Vector2(
			Input.get_joy_axis(pad_id, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad_id, JOY_AXIS_LEFT_Y)
		)
		if ax.length() > .17:
			# A deliberate virtual-stick drag owns movement until it is released.
			# The other stick and buttons still work, in either combination.
			if touch_id == -1 or touch_move.length() < .12: axes = ax
			ui.pad = true
		var cam = Vector2(
			Input.get_joy_axis(pad_id, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(pad_id, JOY_AXIS_RIGHT_Y)
		)
		if cam.length() > .17:
			yaw -= cam.x * dt * 2.25
			pitch = clampf(pitch + cam.y * dt, 0.05, .83)
	var keys = Vector2(
		(
			int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
			- int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		),
		(
			int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
			- int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
		)
	)
	if keys.length() > 0:
		axes = keys.normalized()
	axes = axes.limit_length(1.)
	var facing = Vector3(sin(yaw), 0, cos(yaw))
	var right = Vector3(cos(yaw), 0, -sin(yaw))
	var wish = (
		(right * axes.x + facing * axes.y)
		* (1.56 if hero.crouched else (4.95 if run or Input.is_key_pressed(KEY_SHIFT) else 2.95))
	)
	velocity = velocity.move_toward(wish, dt * (12.5 if wish.length() > .1 else 17.0))
	var vel = velocity
	if dash_time > 0:
		dash_time -= dt
		vel = dash_dir * 6.4
	var old = hero.position
	var p = old
	var n = p + Vector3(vel.x * dt, 0, 0)
	if world.passable(n):
		p = n
	n = p + Vector3(0, 0, vel.z * dt)
	if world.passable(n):
		p = n
	if beat.kind == "forest_cross":
		var reason = world.footing(p,hero.crouched,vel.length(),jumped > .10)
		if reason != "":
			world.crossed_by = ""
			hero.position = world.bank(Haven.LOG_X if world.crossing_lane(p) == Haven.LOG else Haven.FORD_X, -5.1)
			audio.at("water",p,.67); hero.gesture("Hit_Chest",.45)
			clear_input(); camera_ready = false; message(reason)
			return
		if absf(world.channel(p)) < 3.75: world.crossed_by = world.crossing_lane(p)
		elif world.channel(p) < -4.25: world.crossed_by = ""
	p.y = world.walk_height(p.x, p.z)
	if jumped > 0.:
		jumped = maxf(0., jumped - dt)
		p.y += sin(PI * jumped / .60) * .82
	hero.position = p
	var v = p - old
	var speed = Vector2(v.x, v.z).length() / dt
	hero.motion(speed, Vector3(v.x, 0, v.z).normalized(), dt)
	if speed > .55 and not movement_logged:
		movement_logged = true
		print("AV_MOVED")
	last_step += speed * dt
	if last_step > 1.18:
		last_step = 0.
		var surface = "wood" if zone == 0 and -p.z < 11. else ("grass" if zone == 2 and -p.z < 40. else "rock")
		if beat.kind == "forest_cross" and absf(world.channel(p)) < 4.: surface = "wood" if world.crossing_lane(p) == Haven.LOG else "rock"
		audio.foot(surface, p, .31 if hero.crouched else (.74 if speed > 3.3 else .55))


func follow(dt):
	camera.environment = direction.echo_env if direction.remembering else null
	var h = hero.position
	var look = h + Vector3.UP * 1.24
	var camdir = Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var pos = look + camdir * 6.3
	var fov = 64.
	if zone == 0 and mode == "explore":
		look.y -= .35 if hero.crouched else 0.
		look += Vector3(cos(yaw), 0, -sin(yaw)) * .38
		pos = look + camdir * (3.7 if beat.kind == "night_chase" else 2.75)
		fov = 70. if beat.kind == "night_chase" else 61.
	if mode == "ribbon":
		look = h + Vector3(0, 1, -8.)
		pos = h + Vector3(8 + sin(ribbon_time) * 2, 6.5, 7.5)
		fov = 68.
	elif mode in ["dialog", "choice", "ritual"]:
		var target = focus_point
		var sp = str(lines[line_no][0]) if mode == "dialog" and line_no < lines.size() else ""
		if world.people.has(sp) and world.people[sp].position.distance_to(h) < 12:
			target = world.people[sp].position
		var mid = h.lerp(target, .48)
		var dir = target - h
		dir.y = 0
		if dir.length() < .4:
			dir = Vector3.FORWARD
		dir = dir.normalized()
		look = mid + Vector3.UP * (1.05 if mode != "ritual" else .9)
		pos = (
			look
			+ Vector3(dir.z, .36, -dir.x) * (4.2 + minf(1.4, target.distance_to(h) * .27))
			+ dir * .28
		)
		fov = 50.
	if mode == "dialog":
		var speaker = lines[line_no][0]
		var principal = hero if speaker == "Lyander" else world.people.get(speaker)
		if is_instance_valid(principal) and principal.visible and principal.position.distance_to(h) < 13.:
			var listener = hero
			if principal == hero:
				for ln in lines:
					if ln[0] != "Lyander" and world.people.has(ln[0]):
						listener = world.people[ln[0]]; break
			elif beat.kind == "night_hear":
				listener = world.people.Matilda if speaker == "İskele kâtibi" else world.people["İskele kâtibi"]
			if principal != listener:
				principal.face(listener.position)
				principal.meet_eyes(listener.gaze_point())
				listener.meet_eyes(principal.gaze_point())
			look = principal.gaze_point() - Vector3.UP * .11
			var shoulder = (listener.position - principal.position).slide(Vector3.UP).normalized()
			if shoulder.is_zero_approx(): shoulder = Vector3(sin(principal.rotation.y),0,cos(principal.rotation.y))
			var distance_ = 1.18 if zone == 0 else 1.62
			pos = look + shoulder * distance_ + Vector3(shoulder.z,.16,-shoulder.x)*.64
			fov = 38. if zone == 0 else 46.
	if camera.attributes is CameraAttributesPractical:
		camera.attributes.dof_blur_far_enabled = mode == "dialog" and options.high
		camera.attributes.dof_blur_far_distance = pos.distance_to(look) + .64
		camera.attributes.dof_blur_far_transition = 2.8
		camera.attributes.dof_blur_amount = .095
	if look_shake > 0:
		pos += Vector3(sin(clock * 44.), cos(clock * 36.), 0) * look_shake * .18
		look_shake -= dt
	var insert = direction.shot() if mode == "dialog" else []
	if not insert.is_empty():
		pos = insert[0]; look = insert[1]; fov = insert[2]
	if not direction.remembering: pos = world.camera_safe(look,pos)
	if not camera_ready:
		camera.position = pos
		camera.fov = fov
		camera_ready = true
	else:
		camera.position = camera.position.lerp(
			pos, 1. - exp(-dt * (4.2 if mode == "explore" else 2.55))
		)
	camera.fov = lerpf(camera.fov, fov, 1. - exp(-dt * 3.5))
	if camera.position.distance_to(look) > .04:
		camera.look_at(look, Vector3.UP)


func cmd(key: String):
	match key:
		"new":
			start(false)
		"continue":
			start(true)
		"confirm_new":
			mode = "confirm"
			ui.basic(
				"Yeni yolculuk?",
				"KİL LEVHA",
				[["KAYDI KORU", "title"], ["SIFIRLA VE BAŞLA", "new"]],
				"Mevcut bölüm ilerlemesi ve topladığın notlar yeni kaydın üstüne yazılacak."
			)
		"title":
			checkpoint()
			open_title()
		"close_ribbon":
			if mode == "ribbon": explore()
		"interact":
			interact()
		"cast":
			cast()
		"dodge":
			dodge()
		"cycle":
			cycle_spell()
		"crouch": crouch()
		"jump": jump()
		"sprint":
			if hero.crouched: crouch()
			run = not run
			message("Koşu" if run else "Yürüyüş")
		"next":
			if mode == "dialog":
				next_line()
		"pause":
			if mode in ["explore", "dialog"]: pause_game()
		"resume":
			resume_game()
		"settings":
			return_screen = "pause" if active else "title"
			show_settings()
		"quality":
			options.high = not options.high
			apply_scale()
			if is_instance_valid(world):
				world.sun.shadow_enabled = options.high
				if zone == 0: world.cone.shadow_enabled = options.high
		"type":
			options.big = not options.big
			ui.big = options.big
		"loud":
			options.volume = fmod(roundf(options.volume * 4) + 1., 5.) / 4.
			audio.loudness(options.volume)
		"vibration":
			options.haptic = not options.haptic
		"voice":
			options.dub = not options.dub
			if not options.dub:
				audio.quiet()
				spoken_left = 0.
		"guide":
			options.guide = not options.guide
		"settings_back":
			if return_screen == "pause":
				pause_game()
		"credits":
			mode = "credits"
			ui.reading(
				"Emeği geçenler",
				"ASHEN VALE · 3. ZEYTİN",
				FileAccess.get_file_as_string("res://licenses/Credits.txt"),
				"title"
			)
		"journal":
			journal()
		"notes":
			mode = "reading"
			var s = ""
			for f in findings:
				var ids = str(f).split(":")
				var line = NOTES[int(ids[0])][int(ids[1])]
				s += "◆  " + line[0] + "\n" + line[1] + "\n\n"
			(
				ui
				. reading(
					"Yol hatıraları",
					"BULUNAN NOTLAR · %d / 21" % findings.size(),
					(
						s
						if s != ""
						else "Yolda gözüne takılan mühürlere, yıpranmış eşyalara bak. Her hatıranın yeri bu sayfada kalır."
					),
					"journal"
				)
			)
		"log":
			mode = "reading"
			var s = ""
			for b in beats:
				if records.has(str(int(b.id))):
					s += "✓  " + str(b.title) + "\n"
					if flags.has("choice_" + str(int(b.id))):
						s += "       ↳ " + str(flags["choice_" + str(int(b.id))]) + "\n"
			ui.reading(
				"İki tanığın yolu",
				"GÖREVLER VE KARARLAR",
				s + "\n◇  " + ("Bölüm tamamlandı" if completed else beat.title),
				"journal"
			)
		"codex":
			show_codex()
		"book":
			show_book()
		"end_back":
			mode = "end"
			ui.basic(
				"Görünce çizeriz.",
				"BÖLÜM SONU",
				[["YOL DEFTERİ", "journal"], ["ANA MENÜ", "title"]]
			)
		"chart_solved":
			if mode == "chart":
				advance()
		"leave_ritual":
			explore()
			message("Dersi aynı yerde yeniden deneyebilirsin.")
		_:
			if key.begins_with("school:"):
				mode = "reading"
				var school = key.trim_prefix("school:")
				var s = ""
				for item in archive.spells:
					if item[1] == school:
						s += (
							"%02d   %s   ·   %s\n%s\n\n"
							% [
								int(item[0]),
								item[2],
								(
									"Öğrenildi"
									if SPELLS.find(item[2]) in learned
									else item[3] + " / kilitli"
								),
								item[4]
							]
						)
				ui.reading(school, "BÜYÜ SİCİLİ", s, "codex")
			elif key.begins_with("leaf:"):
				mode = "reading"
				var i = int(key.trim_prefix("leaf:"))
				ui.reading(
					archive.chapters[i].title,
					"3. ZEYTİN · ARŞİV",
					archive.chapters[i].text,
					"book"
				)
	if key in ["quality", "type", "loud", "vibration", "voice", "guide"]:
		settings_save()
		show_settings()
	if key == "settings_back" and return_screen != "pause":
		open_title()


func resume_game():
	if back_mode == "dialog" and line_no < lines.size():
		mode = "dialog"
		var ln = lines[line_no]
		ui.dialogue(ln[0], ln[1], "%02d  /  %02d" % [line_no + 1,lines.size()])
	else:
		explore()
	back_mode = "explore"
	audio.hold_voice(false)


func pause_game():
	if mode in ["explore","dialog"]: back_mode = mode
	audio.hold_voice(true)
	mode = "pause"
	clear_input()
	checkpoint()
	ui.basic(
		"Yolculuğa ara verildi",
		zones[zone].name,
		[
			["DEVAM ET", "resume"],
			["YOL DEFTERİ", "journal"],
			["SEÇENEKLER", "settings"],
			["KAYDET VE ANA MENÜ", "title"]
		],
		"Son kayıt:  " + beat.title
	)


func show_settings():
	mode = "settings"
	print("AV_MENU settings")
	ui.basic(
		"Seçenekler",
		"GÖRÜNTÜ · SES · ERİŞİLEBİLİRLİK",
		[
			["Gölge kalitesi:  " + ("Yüksek" if options.high else "Tasarruf"), "quality"],
			["Altyazı:  " + ("Büyük" if options.big else "Standart"), "type"],
			["Ses düzeyi:  %" + str(roundi(options.volume * 100)), "loud"],
			[
				"Kayıtlı Türkçe diyalog:  " + ("Açık" if options.dub else "Kapalı"),
				"voice"
			],
			["Titreşim:  " + ("Açık" if options.haptic else "Kapalı"), "vibration"],
			["Yol işareti:  " + ("Açık" if options.guide else "Kapalı"), "guide"],
			["‹   GERİ", "settings_back"]
		]
	)


func journal():
	mode = "journal"
	clear_input()
	ui.basic(
		"Yol Defteri",
		zones[zone].name + "    /    " + str(roundi(elapsed / 60)) + " DK",
		[
			["İzler ve kararlar     ·     " + str(records.size()), "log"],
			["Saha notları     ·     %d / 21" % findings.size(), "notes"],
			["Sekiz dal     ·     büyü sicili", "codex"],
			["Anlatı arşivi     ·     açılan sayfalar", "book"],
			["‹   Yolculuğa dön", "end_back" if completed else "resume"]
		]
	)


func show_codex():
	mode = "codex"
	var items = []
	var schools = []
	for item in archive.spells:
		if not schools.has(item[1]):
			schools.append(item[1])
			items.append([item[1], "school:" + str(item[1])])
	items.append(["‹   Defter", "journal"])
	ui.basic("Sekiz Dal", "34 BÜYÜ   ·   8 KARANLIK UYGULAMA", items)


func show_book():
	mode = "book"
	var pages = []
	for i in range(zone + 1):
		pages.append([archive.chapters[i].title, "leaf:" + str(i)])
	pages.append(["‹   Defter", "journal"])
	ui.basic("3. Zeytin", "ANLATI ARŞİVİ", pages)


func back():
	match mode:
		"crossing":
			advance()
		"title":
			get_tree().quit()
		"ribbon":
			explore()
		"explore":
			pause_game()
		"pause":
			resume_game()
		"dialog":
			pause_game()
		"choice":
			message("Bir yanıt seç.")
		"ritual", "chart":
			cmd("leave_ritual")
		"settings":
			cmd("settings_back")
		"journal":
			cmd("end_back" if completed else "resume")
		"codex", "book", "reading":
			journal()
		_:
			open_title()


func _input(event):
	if not is_instance_valid(ui):
		return
	var touch_down = event is InputEventScreenTouch and event.pressed
	var mouse_down = (event is InputEventMouseButton and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)
	if touch_down or mouse_down:
		ui.pointer_used(touch_down)
		if mode == "explore":
			var action = ui.action_at(event.position)
			if action != "":
				cmd(action)
				get_viewport().set_input_as_handled()
				return
	if event is InputEventJoypadButton:
		ui.pad = true
		pad_id = event.device
		if not event.pressed:
			if mode == "ritual" and event.button_index == JOY_BUTTON_A:
				ui.ritual.released()
				get_viewport().set_input_as_handled()
			return
		if event.button_index == JOY_BUTTON_START:
			if mode in ["explore", "dialog"]:
				pause_game()
				get_viewport().set_input_as_handled()
				return
		if mode == "explore":
			match event.button_index:
				JOY_BUTTON_A:
					interact()
				JOY_BUTTON_B:
					jump()
				JOY_BUTTON_LEFT_STICK:
					crouch()
				JOY_BUTTON_RIGHT_STICK:
					dodge()
				JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT:
					var spell = [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT].find(event.button_index)
					if spell in learned:
						selected = spell
						cast()
				JOY_BUTTON_X:
					run = not run
				JOY_BUTTON_Y:
					journal()
				JOY_BUTTON_LEFT_SHOULDER:
					cycle_spell(-1)
				JOY_BUTTON_RIGHT_SHOULDER:
					cycle_spell()
		elif mode == "chart":
			match event.button_index:
				JOY_BUTTON_A:
					ui.board.turn_tile()
				JOY_BUTTON_Y:
					ui.board.submit()
				JOY_BUTTON_B:
					back()
				JOY_BUTTON_DPAD_LEFT:
					ui.board.step(-1, 0)
				JOY_BUTTON_DPAD_RIGHT:
					ui.board.step(1, 0)
				JOY_BUTTON_DPAD_UP:
					ui.board.step(0, -1)
				JOY_BUTTON_DPAD_DOWN:
					ui.board.step(0, 1)
		elif mode == "ritual":
			match event.button_index:
				JOY_BUTTON_DPAD_LEFT:
					ui.ritual.adjust(-1)
				JOY_BUTTON_DPAD_RIGHT:
					ui.ritual.adjust(1)
				JOY_BUTTON_A:
					ui.ritual.press()
				JOY_BUTTON_B:
					back()
		elif event.button_index == JOY_BUTTON_A:
			ui.accept()
		elif event.button_index in [JOY_BUTTON_B, JOY_BUTTON_START]:
			back()
		elif event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT]:
			ui.nav(-1)
		elif event.button_index in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT]:
			ui.nav(1)
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadMotion:
		if mode == "explore" and event.axis == JOY_AXIS_TRIGGER_RIGHT:
			if event.axis_value > .55 and not trigger_down:
				trigger_down = true
				cast()
			elif event.axis_value < .25:
				trigger_down = false
		elif (
			mode not in ["explore", "ritual"]
			and event.axis == JOY_AXIS_LEFT_Y
			and absf(event.axis_value) > .67
			and Time.get_ticks_msec() * .001 > stick_clock
		):
			ui.nav(signi(int(signf(event.axis_value))))
			stick_clock = Time.get_ticks_msec() * .001 + .28
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_BACKSPACE] and event.pressed:
			back()
			get_viewport().set_input_as_handled()
			return
		if mode == "chart" and event.pressed:
			match event.keycode:
				KEY_LEFT:
					ui.board.step(-1, 0)
				KEY_RIGHT:
					ui.board.step(1, 0)
				KEY_UP:
					ui.board.step(0, -1)
				KEY_DOWN:
					ui.board.step(0, 1)
				KEY_SPACE:
					ui.board.turn_tile()
				KEY_ENTER:
					ui.board.submit()
			get_viewport().set_input_as_handled()
		elif mode == "ritual":
			if event.keycode in [KEY_SPACE, KEY_ENTER]:
				if event.pressed:
					ui.ritual.press()
				else:
					ui.ritual.released()
			elif event.pressed and event.keycode in [KEY_A, KEY_LEFT]:
				ui.ritual.adjust(-1)
			elif event.pressed and event.keycode in [KEY_D, KEY_RIGHT]:
				ui.ritual.adjust(1)
			get_viewport().set_input_as_handled()
		elif event.pressed and mode == "explore":
			match event.keycode:
				KEY_E, KEY_ENTER:
					interact()
				KEY_SPACE:
					jump()
				KEY_C: crouch()
				KEY_ALT: dodge()
				KEY_F:
					cast()
				KEY_Q:
					cycle_spell()
				KEY_TAB:
					journal()
		elif event.pressed and event.keycode in [KEY_ENTER, KEY_SPACE, KEY_E]:
			ui.accept()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if not event.pressed:
			if event.index == touch_id:
				touch_id = -1
				touch_move = Vector2.ZERO
				ui.stick_pos(touch_move)
			if event.index == look_id:
				look_id = -1


func _unhandled_input(event):
	if mode != "explore" or not is_instance_valid(ui):
		return
	var w = get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < w.x * .44 and touch_id == -1:
				touch_id = event.index
				touch_origin = event.position
				touch_move = Vector2.ZERO
			elif look_id == -1:
				look_id = event.index
		else:
			if event.index == touch_id:
				touch_id = -1
				touch_move = Vector2.ZERO
				ui.stick_pos(touch_move)
			if event.index == look_id:
				look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			touch_move = ((event.position - touch_origin) / 69.).limit_length(1)
			ui.stick_pos(touch_move)
		elif event.index == look_id:
			yaw -= event.relative.x * .005
			pitch = clampf(pitch - event.relative.y * .0035, .015, .86)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		mouse_look = event.pressed
	elif event is InputEventMouseMotion and mouse_look:
		yaw -= event.relative.x * .005
		pitch = clampf(pitch - event.relative.y * .0035, .015, .86)


func stop_key() -> String:
	return "round_" + str(index)


func current_stop() -> Dictionary:
	return trips[beat.kind].stops[round_no]


func set_round(n: int):
	round_no = n
	flags[stop_key()] = n
	if n >= trips[beat.kind].stops.size():
		advance()
		return
	var row = current_stop()
	var at = world.point(row.at)
	if row.model in World.PEOPLE:
		world.person_on_set(row.model, at)
	if beat.kind == "paired" and int(row.spell) == 2:
		practice_disc = MeshInstance3D.new()
		practice_disc.mesh = world.geometry("rod")
		practice_disc.material_override = world.material("#edc795", true)
		practice_disc.scale = Vector3(.58, .16, .58)
		world.add_child(practice_disc)
		course_wave = 0.
	ui.set_goal(
		zones[zone].name + "  ·  %d / %d" % [n + 1, trips[beat.kind].stops.size()], row.task
	)
	explore()
	checkpoint()


func round_interact():
	var row = current_stop()
	var need = int(row.spell)
	if need >= 0:
		message("L1/R1 veya ↻ ile seç; R2 veya büyü düğmesi ile uygula: " + SPELLS[need])
		return
	seal_round(row)


func seal_round(row: Dictionary):
	audio.fx("seal", .7)
	hero.gesture("Interact", .65)
	if is_instance_valid(practice_disc):
		practice_disc.queue_free()
		practice_disc = null
	conversation(row.lines, "round", world.point(row.at))


func field_cast() -> bool:
	if round_no < 0 or beat.kind != "paired":
		return false
	var row = current_stop()
	var p = world.point(row.at)
	var gap = hero.position.distance_to(p)
	if gap > 5.5:
		message("Ölçü noktasına yaklaş.")
		return true
	if selected != int(row.spell):
		audio.fx("miss", .5)
		message("Sicildeki sınırını hatırla. Bu dal şu işi yapamaz: " + row.task)
		return true
	if selected == 2 and course_wave < .62:
		audio.fx("miss", .65)
		message("Diski gözet. Kavis uzaktan değil, sana yaklaştığında dayanır.")
		return true
	var aim = Vector3(p.x - hero.position.x, 0, p.z - hero.position.z)
	if (
		selected == 3
		and aim.length() > 1.5
		and aim.normalized().dot(Vector3(sin(hero.heading), 0, cos(hero.heading))) < .52
	):
		message("Sepete dön. İtiş bedeninin baktığı yöne gider.")
		return true
	var key = ["ember", "water", "shield", "wind"][selected]
	var at = p + Vector3.UP * .95
	burst(at, key)
	audio.at(key,at)
	seal_round(row)
	hero.gesture("Block" if selected == 2 else "Spellcast_Shoot", .7)
	return true


func field_frame(dt: float):
	if round_no < 0:
		return
	if beat.kind == "paired" and is_instance_valid(practice_disc):
		var pos = world.point(current_stop().at) + Vector3.UP
		course_wave = fmod(course_wave + dt * .40, 1.)
		practice_disc.position = (
			pos.lerp(hero.position + Vector3.UP, course_wave)
			+ Vector3.UP * sin(course_wave * PI) * .7
		)
		practice_disc.rotation.y += dt * 5

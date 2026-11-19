extends Node
## All playback is local. A single foreground channel prevents skipped lines talking over each other.
var music: AudioStreamPlayer
var pool: Array = []
var spatial: Array = []
var dialogue: AudioStreamPlayer3D
var voice_anchor: Node3D
var last_take = ""
var voice_held = false
var resume_offset = 0.
var index = 0
var world_index = 0
var piece = ""
var volume = .72
var ambience: AudioStreamPlayer3D
var fire: AudioStreamPlayer3D
var fire_anchor: Node3D
var curves: Dictionary
var stride = 0
var foley = {}


func _ready():
	curves = JSON.parse_string(FileAccess.get_file_as_string("res://data/speech-curves.json"))
	music = AudioStreamPlayer.new()
	add_child(music)
	music.finished.connect(_loop)
	for i in range(5):
		var p = AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
		var emitter = AudioStreamPlayer3D.new()
		add_child(emitter)
		emitter.unit_size = 4.5
		emitter.max_distance = 30.
		spatial.append(emitter)
	dialogue = AudioStreamPlayer3D.new()
	add_child(dialogue)
	dialogue.unit_size = 7.
	dialogue.max_distance = 56.
	dialogue.panning_strength = .68
	dialogue.max_db = 1.0
	ambience = AudioStreamPlayer3D.new()
	add_child(ambience)
	ambience.unit_size = 9.
	ambience.max_distance = 65.
	ambience.finished.connect(func(): ambience.play())
	fire = AudioStreamPlayer3D.new()
	add_child(fire)
	fire.stream = preload("res://audio/embers.ogg")
	fire.unit_size = 2.; fire.max_distance = 14.
	fire.finished.connect(func():
		if is_instance_valid(fire_anchor): fire.play()
	)


func score(track: String):
	if track == piece:
		return
	piece = track
	music.stream = load("res://audio/%s.ogg" % track)
	music.volume_db = db(.48)
	music.play()


func _loop():
	if music.stream:
		music.play()


func db(gain: float) -> float:
	return linear_to_db(maxf(.0001, volume * gain))


func loudness(v: float):
	volume = clampf(v, 0., 1.)
	if dialogue:
		dialogue.volume_db = db(1.)
		ambience.volume_db = db(.29)
		fire.volume_db = db(.18)
		music.volume_db = db(.48)


func ambience_at(id: String, pos: Vector3):
	ambience.stop()
	if id == "":
		return
	ambience.stream = load("res://audio/%s.ogg" % id)
	ambience.position = pos
	ambience.volume_db = db(.29)
	ambience.play()


func fire_at(node: Node3D):
	fire.stop()
	fire_anchor = node
	if is_instance_valid(node):
		fire.global_position = node.global_position
		fire.volume_db = db(.18)
		fire.play()


func hold_voice(held: bool):
	# A 3D play request may still be queued for the next physics frame. Stopping
	# that request also handles pausing on the very frame a new line begins.
	if held and not voice_held and dialogue.playing:
		resume_offset = maxf(0., dialogue.get_playback_position())
		voice_held = true
		dialogue.stop()
	elif not held and voice_held:
		voice_held = false
		dialogue.play(resume_offset)


func quiet():
	voice_held = false
	resume_offset = 0.
	dialogue.stop()
	dialogue.stream_paused = false
	if is_instance_valid(voice_anchor): voice_anchor.articulate(0.,0.)
	voice_anchor = null
	last_take = ""


func speak(line: Array, anchor: Node3D, fallback: Vector3, enabled: bool) -> float:
	quiet()
	if line.size() < 3:
		return 0.  # Unrecorded roles have subtitles, never another actor's voice or device TTS.
	var clip: AudioStream = load("res://audio/voices/tr/%s.ogg" % line[2])
	if clip == null:
		return 0.
	if enabled:
		voice_anchor = anchor
		dialogue.global_position = fallback + Vector3.UP * 1.25
		track_voice()
		last_take = line[2]
		dialogue.stream = clip
		dialogue.volume_db = db(1.)
		dialogue.play()
	return clip.get_length()


func track_voice():
	if is_instance_valid(voice_anchor):
		dialogue.global_position = voice_anchor.gaze_point()
		if dialogue.playing and curves.takes.has(last_take):
			var t = maxf(0., dialogue.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())
			var frames: Array = curves.takes[last_take]
			var pos = minf(t * float(curves.fps),frames.size()-1)
			var a = int(frames[int(pos)]); var b = int(frames[mini(ceili(pos),frames.size()-1)])
			voice_anchor.articulate(lerpf(a & 255,b & 255,fmod(pos,1.))/255.,lerpf(a >> 8,b >> 8,fmod(pos,1.))/255.)
		else:
			voice_anchor.articulate(0.,0.)


func _process(dt):
	track_voice()
	if is_instance_valid(fire_anchor): fire.global_position = fire_anchor.global_position
	var gain = .20 if dialogue.playing and not dialogue.stream_paused else .48
	music.volume_db = lerpf(music.volume_db, db(gain), 1. - exp(-dt * 6.))


func fx(id: String, gain = 1.0):
	var p = pool[index % pool.size()]
	index += 1
	p.stream = load("res://audio/%s.wav" % id)
	p.volume_db = db(gain)
	p.pitch_scale = randf_range(.96, 1.035)
	p.play()


func foot(surface: String, pos: Vector3, gain: float):
	stride += 1
	at("feet/" + surface + str(1 + stride % 3), pos, gain)


func at(id: String, pos: Vector3, gain = 1.):
	var p: AudioStreamPlayer3D = spatial[world_index % spatial.size()]
	world_index += 1
	if not foley.has(id): foley[id] = load("res://audio/%s.wav" % id)
	p.stream = foley[id]
	p.global_position = pos
	p.volume_db = db(gain)
	p.pitch_scale = randf_range(.94, 1.04)
	p.play()

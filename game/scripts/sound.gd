extends Node
var music: AudioStreamPlayer
var pool: Array = []
var index = 0
var piece = ""
var volume = 0.72


func _ready():
	music = AudioStreamPlayer.new()
	add_child(music)
	music.finished.connect(_loop)
	for i in range(5):
		var p = AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)


func score(track: String):
	if track == piece:
		return
	piece = track
	music.stream = load("res://audio/%s.ogg" % track)
	music.volume_db = linear_to_db(maxf(.0001, volume * .59))
	music.play()


func _loop():
	if music.stream:
		music.play()


func loudness(v: float):
	volume = v
	if music:
		music.volume_db = linear_to_db(maxf(.0001, volume * .59))


func fx(id: String, scale = 1.0):
	var p = pool[index % pool.size()]
	index += 1
	p.stream = load("res://audio/%s.wav" % id)
	p.volume_db = linear_to_db(maxf(.0001, volume * scale))
	p.pitch_scale = randf_range(.96, 1.035)
	p.play()

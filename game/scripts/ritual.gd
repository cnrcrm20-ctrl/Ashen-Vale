extends Control
## Interactive field tablet. Controls are identical on touch, keyboard and DualShock.
signal effect(id: String, good: bool)
signal finished
var kind = "wick"
var phase = 0.0
var charge = 0.
var charging = false
var goal = 1
var success = 0
var rounds = 2
var result_time = 0.
var done = false
var hint = ""
var aim = 0.
var selection = 1
var sampled = [false, false, false]
var listening = 0.
var flight = -1.
var shot = 0.
var flight_ok = false
var hold_age = 0.
var field = false
var ink = Color("f3e7cd")
var muted = Color("c5cfbb")
var gold = Color("e8be79")
var teal = Color("74d2bd")
var red = Color("e6a38c")
var serif = preload("res://fonts/display.ttf")
var font = preload("res://fonts/sans.ttf")


func begin(mode: String, serial: int):
	field = mode.begins_with("test")
	kind = mode.trim_prefix("test")
	goal = (serial + 1) % 3
	rounds = 1 if field else (3 if kind in ["guard", "dodge"] else 2)
	if kind == "water":
		rounds = 1
	if field and kind == "water":
		goal = 2
	if kind == "gust":
		aim = -.28
		goal = serial % 2
	hint = instruction()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func instruction() -> String:
	match kind:
		"wick":
			return "Yağı görünen kandile odaklan. Ateşi başlat, altın aralıkta bırak."
		"water":
			return "Üç künkü ayrı ayrı dinle. İlerleyen halkaları nabızdan ayır."
		"guard":
			return "Disk altın halkanın içine girdiği anda Siper kur."
		"dodge":
			return "Püskülü izle. Disk yaklaşınca ağırlığını yana aktar."
		_:
			return "İzi sepetin ağzına hizala; göstergedeki aralıkta itişi bırak."


func caption() -> String:
	match kind:
		"wick":
			return "ATEŞİ BIRAK" if charging else "ATEŞİ ÇAĞIR"
		"water":
			return "YÖNÜ KAYDET" if sampled.all(func(v): return v) else "KÜNKÜ DİNLE"
		"guard":
			return "SİPER KUR"
		"dodge":
			return "YANA ATIL"
		_:
			return "İTİŞİ BIRAK" if charging else "YELİ TOPLA"


func adjust(signum: int):
	if done or result_time > 0 or charging or listening > 0 or flight >= 0:
		return
	if kind == "gust":
		aim = clampf(aim + signum * .12, -.96, .96)
	else:
		selection = posmod(selection + signum, 3)
	queue_redraw()


func press():
	if done or result_time > 0 or listening > 0 or flight >= 0:
		return
	match kind:
		"water":
			if sampled.all(func(v): return v):
				resolve(selection == goal, "water")
			else:
				listening = .85
				effect.emit("water", true)
		"guard", "dodge":
			var ok = phase > .68 and phase < .94
			resolve(ok, "shield" if kind == "guard" else "dodge")
		"wick", "gust":
			if not charging:
				charging = true
				charge = 0.
				hold_age = 0.
				hint = "Altın aralığı gözet. Basılı tutup bırakabilir ya da tekrar basabilirsin."
			else:
				release_cast()


func released():
	if charging and hold_age > .24:
		release_cast()


func release_cast():
	if not charging:
		return
	charging = false
	if kind == "wick":
		resolve(selection == goal and charge >= .43 and charge <= .79, "ember")
	else:
		var target = -.52 if goal == 0 else .52
		shot = aim + (charge - .62) * .72
		flight_ok = absf(shot - target) < .23 and charge > .35 and charge < .88
		flight = 0.
		effect.emit("wind", true)


func resolve(ok: bool, fx: String):
	effect.emit(fx, ok)
	result_time = .82
	phase = 0
	if ok:
		success += 1
		done = success >= rounds
		hint = "Ölçü doğrulandı." if done else "Doğru. Şimdi ikinci işareti oku."
		if not done:
			if kind == "wick":
				goal = (goal + 1) % 3
			if kind == "gust":
				goal = 1 - goal
	else:
		match kind:
			"water":
				hint = "Bu iz yer değiştirmiyor. Sürekli aynı yöne yürüyen halkayı ara."
				sampled = [false, false, false]
			"wick":
				hint = "Fitil kuruysa ateş tutmaz. Yağlı kabı seç ve altın aralıkta bırak."
			"gust":
				hint = "Diskin düştüğü izi gör. Yönü ve itişi biraz düzelt."
			_:
				hint = "Çok erken ya da geç. Püskül gerildikten sonra diski karşıla."


func _process(dt):
	if result_time > 0:
		result_time -= dt
		if result_time <= 0 and done:
			finished.emit()
			set_process(false)
	elif not done:
		if kind in ["guard", "dodge"]:
			phase = fmod(phase + dt * (.35 + .025 * success), 1.0)
		else:
			phase += dt
		if charging:
			hold_age += dt
			charge = (1. - cos(hold_age * 2.75)) * .5
		if listening > 0:
			listening -= dt
			if listening <= 0:
				sampled[selection] = true
				hint = (
					"Üç okumayı karşılaştır; akış olan künkü seç."
					if sampled.all(func(v): return v)
					else "İz levhaya işlendi. Öbür künkü de dinle."
				)
		if flight >= 0:
			flight += dt * 1.6
			if flight >= 1:
				flight = -1.
				resolve(flight_ok, "wind")
	queue_redraw()


func text(p: Vector2, t: String, sz: int, c: Color, wide = -1):
	draw_string(font, p, t, HORIZONTAL_ALIGNMENT_CENTER, wide, sz, c)


func _draw():
	var w = size.x
	var h = size.y
	var cy = h * .48
	if w < 20:
		return
	if kind in ["wick", "water"]:
		for i in range(3):
			var x = w * (.2 + i * .30)
			var c = gold if i == selection else muted.darkened(.45)
			draw_arc(Vector2(x, cy), 49, 0, TAU, 64, c, 2, true)
			if kind == "wick":
				draw_arc(Vector2(x, cy + 3), 30, 0, PI, 26, c, 4, true)
				draw_line(Vector2(x - 30, cy + 3), Vector2(x + 30, cy + 3), c, 2, true)
				if i == goal:
					draw_line(Vector2(x - 23, cy + 8), Vector2(x + 23, cy + 8), gold, 4, true)
				draw_line(Vector2(x, cy + 1), Vector2(x + 3, cy - 11), ink, 3, true)
				if charging and i == selection:
					draw_circle(Vector2(x, cy - 13 - charge * 9), 3 + charge * 9, gold)
			else:
				var scanned = sampled[i] or (listening > 0 and i == selection)
				for k in range(3):
					var pulse = fmod(phase * .72 + k * .33, 1.)
					var off = Vector2.RIGHT * pulse * 16 if scanned and i == goal else Vector2.ZERO
					draw_arc(
						Vector2(x, cy) + off,
						5 + (pulse * 29 if scanned else 8 * k),
						0,
						TAU,
						40,
						Color(teal, 1. - pulse * .6) if scanned else Color(muted, .25),
						2,
						true
					)
			text(
				Vector2(x - 72, cy + 80),
				["I", "II", "III"][i] + ("  •" if kind == "water" and sampled[i] else ""),
				19,
				c,
				144
			)
	if kind in ["wick", "gust"]:
		var left = w * .22
		var width = w * .56
		var y = h - 16
		draw_rect(Rect2(left, y, width, 5), Color(muted, .3))
		draw_rect(Rect2(left + width * .43, y - 2, width * .36, 9), Color(gold, .85))
		draw_circle(Vector2(left + width * charge, y + 2), 7, teal if charging else ink)
	if kind in ["guard", "dodge"]:
		var a = Vector2(w * .13, cy)
		var b = Vector2(w * .87, cy)
		draw_line(a, b, Color(muted, .37), 3)
		var catchpos = a.lerp(b, .81)
		draw_arc(catchpos, 40, 0, TAU, 60, gold, 3, true)
		draw_arc(catchpos, 30, 0, TAU, 60, Color(gold, .45), 1, true)
		var v = a.lerp(b, phase)
		draw_circle(v, 17, teal)
		draw_arc(v, 22, 0, TAU, 46, teal, 1, true)
		text(
			Vector2(w * .18, cy + 73),
			"PÜSKÜL                         YAKLAŞMA                         KARŞILA",
			16,
			muted,
			w * .64
		)
	if kind == "gust":
		var center = w * .5
		var span = w * .34
		var target = -.52 if goal == 0 else .52
		var tx = center + span * target
		var c = Vector2(center, cy + 42)
		var tip = Vector2(center + span * aim, cy - 33)
		draw_arc(Vector2(tx, cy - 42), 25, 0, PI, 32, gold, 4, true)
		draw_line(Vector2(tx - 25, cy - 42), Vector2(tx + 25, cy - 42), gold, 3, true)
		draw_dashed_line(c, tip, muted, 2, 8)
		draw_circle(tip, 5, teal)
		if flight >= 0:
			draw_circle(
				(
					c.lerp(Vector2(center + span * shot, cy - 40), flight)
					- Vector2.UP * -sin(flight * PI) * 34
				),
				11,
				ink
			)
		else:
			draw_circle(c, 11, ink)

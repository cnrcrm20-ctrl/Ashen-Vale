extends Control
signal command(key: String)
signal option(index: int)
signal ritual_effect(id: String, ok: bool)
signal board_sound(key: String)
var board
var board_hint: Label
signal ritual_done
const ART = preload("res://art/first_light.jpg")
const SERIF = preload("res://fonts/display.ttf")
const SANS = preload("res://fonts/sans.ttf")
const Ritual = preload("res://scripts/ritual.gd")
const CREAM = Color("f6ebd4")
const GOLD = Color("e5bf80")
const MUTED = Color("a8bdb5")
const DARK = Color("132525")
var page: Control
var hud: Control
var shot: Control
var objective: Label
var place: Label
var distance_label: Label
var prompt: Button
var movehint: Label
var cast_button: Button
var marker: Label
var joy: Control
var stick: Panel
var dial: Control
var choices: Array = []
var ritual
var rit_hint: Label
var rit_button: Button
var big = false
var pad = false
var scene_badge: Label
var scroll: ScrollContainer


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE


func cover(node: Control):
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func rect(node: Control, a, b, c, d, l = 0, t = 0, r = 0, bt = 0):
	node.anchor_left = a
	node.anchor_top = b
	node.anchor_right = c
	node.anchor_bottom = d
	node.offset_left = l
	node.offset_top = t
	node.offset_right = r
	node.offset_bottom = bt


func style(bg: Color, line: Color, radius: int = 9) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = line
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 13
	s.content_margin_right = 13
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	return s


func panel(parent: Control, bg: Color, line = Color.TRANSPARENT, radius = 8) -> Panel:
	var n = Panel.new()
	parent.add_child(n)
	n.mouse_filter = MOUSE_FILTER_IGNORE
	n.add_theme_stylebox_override("panel", style(bg, line, radius))
	return n


func layer(parent: Control) -> Control:
	var n = Control.new()
	parent.add_child(n)
	cover(n)
	n.mouse_filter = MOUSE_FILTER_IGNORE
	return n


func label(
	parent: Control, value: String, sz: int = 21, col: Color = CREAM, serif = false
) -> Label:
	var n = Label.new()
	parent.add_child(n)
	n.text = value
	n.mouse_filter = MOUSE_FILTER_IGNORE
	n.add_theme_font_override("font", SERIF if serif else SANS)
	n.add_theme_font_size_override("font_size", sz)
	n.add_theme_color_override("font_color", col)
	n.add_theme_color_override("font_shadow_color", Color(0, 0, 0, .36))
	n.add_theme_constant_override("shadow_offset_y", 1)
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return n


func button(parent: Control, value: String, cb: Callable, primary = false) -> Button:
	var b = Button.new()
	parent.add_child(b)
	b.text = value
	b.add_theme_font_override("font", SANS)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", DARK if primary else CREAM)
	b.add_theme_color_override("font_hover_color", DARK)
	b.add_theme_color_override("font_focus_color", DARK if primary else Color.WHITE)
	b.add_theme_stylebox_override(
		"normal",
		style(
			Color("e1ba7d") if primary else Color(.058, .128, .135, .90),
			Color(GOLD, .67 if primary else .38)
		)
	)
	b.add_theme_stylebox_override("hover", style(Color("ecd4a7"), GOLD))
	b.add_theme_stylebox_override("pressed", style(Color("c49b60"), GOLD))
	var focus = style(Color.TRANSPARENT, Color("fff0d4"))
	focus.set_border_width_all(3)
	b.add_theme_stylebox_override("focus", focus)
	b.pressed.connect(cb)
	return b


func bindcmd(key: String) -> Callable:
	return func(): command.emit(key)


func grad(parent: Control, colors: Array, vertical = false) -> TextureRect:
	var t = GradientTexture2D.new()
	var gr = Gradient.new()
	gr.colors = PackedColorArray(colors)
	t.gradient = gr
	t.fill_from = Vector2.ZERO
	t.fill_to = Vector2.DOWN if vertical else Vector2.RIGHT
	t.width = 256
	t.height = 128
	var v = TextureRect.new()
	v.texture = t
	v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(v)
	cover(v)
	return v


func wipe():
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	page = null
	ritual = null
	board = null
	scroll = null
	choices.clear()


func new_page():
	wipe()
	page = layer(self)
	page.mouse_filter = MOUSE_FILTER_STOP
	if is_instance_valid(hud):
		hud.hide()


func title(saved: bool, completed: bool):
	new_page()
	var im = TextureRect.new()
	im.texture = ART
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	im.mouse_filter = MOUSE_FILTER_IGNORE
	page.add_child(im)
	cover(im)
	grad(
		page,
		[
			Color(.025, .065, .07, .93),
			Color(.035, .09, .09, .70),
			Color(.07, .13, .13, .14),
			Color.TRANSPARENT
		]
	)
	grad(page, [Color.TRANSPARENT, Color.TRANSPARENT, Color(0.025, .06, .06, .48)], true)
	var p = label(page, "A S H E N    V A L E     /     K R O N İ K L E R", 17, GOLD)
	rect(p, .069, .102, .65, .16)
	p = label(page, "ASHEN VALE", 78, CREAM, true)
	rect(p, .065, .18, .76, .36)
	p = label(page, "BİRİNCİ BÖLÜM    ─    ÜÇÜNCÜ ZEYTİN", 20, GOLD)
	rect(p, .072, .355, .68, .41)
	p = label(page, "İki dünya arasında, bir çocuğun adı.", 25, CREAM, true)
	rect(p, .07, .423, .78, .49)
	var b = button(
		page,
		"YOLCULUĞA DEVAM   ›" if saved and not completed else "YOLCULUĞA BAŞLA   ›",
		bindcmd("continue" if saved and not completed else ("confirm_new" if completed else "new")),
		true
	)
	rect(b, .07, .57, .07, .57, 0, 0, 325, 61)
	b.grab_focus()
	choices.append(b)
	var opt = button(page, "SEÇENEKLER", bindcmd("settings"))
	rect(opt, .07, .57, .07, .57, 0, 74, 155, 125)
	choices.append(opt)
	opt = button(page, "OYUN HAKKINDA", bindcmd("credits"))
	rect(opt, .07, .57, .07, .57, 167, 74, 357, 125)
	choices.append(opt)
	if saved and not completed:
		opt = button(page, "YENİ KAYIT", bindcmd("confirm_new"))
		rect(opt, .07, .57, .07, .57, 0, 139, 155, 185)
		choices.append(opt)
	p = label(page, "I   /   VII       •       ÜÇOLUK'TAN VADİYE", 15, MUTED)
	rect(p, .07, .91, .75, .96)


func prepare_hud():
	if is_instance_valid(hud):
		hud.queue_free()
	hud = layer(self)
	move_child(hud, 0)
	var bar = panel(hud, Color(.035, .08, .083, .85), Color(GOLD, .34))
	rect(bar, 0, 0, 0, 0, 28, 23, 520, 103)
	place = label(bar, "", 15, GOLD)
	rect(place, 0, 0, 1, 0, 17, 5, -15, 29)
	objective = label(bar, "", 21, CREAM, true)
	rect(objective, 0, 0, 1, 1, 17, 27, -13, -6)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var btn = button(hud, "≡   DEFTER", bindcmd("journal"))
	rect(btn, 1, 0, 1, 0, -234, 23, -90, 75)
	btn.focus_mode = FOCUS_NONE
	btn = button(hud, "Ⅱ", bindcmd("pause"))
	rect(btn, 1, 0, 1, 0, -81, 23, -25, 75)
	btn.focus_mode = FOCUS_NONE
	marker = label(hud, "◇", 34, GOLD)
	marker.size = Vector2(42, 42)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label = label(hud, "", 17, CREAM)
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.size = Vector2(100, 33)
	dial = layer(hud)
	joy = panel(dial, Color(.04, .13, .13, .33), Color(CREAM, .42), 80)
	rect(joy, 0, 1, 0, 1, 40, -194, 193, -41)
	stick = panel(joy, Color(.81, .78, .64, .28), Color(CREAM, .68), 40)
	stick.size = Vector2(53, 53)
	stick.position = Vector2(50, 50)
	btn = button(dial, "Koş", bindcmd("sprint"))
	rect(btn, 0, 1, 0, 1, 202, -99, 283, -48)
	btn.focus_mode = FOCUS_NONE
	prompt = button(dial, "Etkileş", bindcmd("interact"), true)
	rect(prompt, 1, 1, 1, 1, -230, -113, -30, -49)
	prompt.focus_mode = FOCUS_NONE
	cast_button = button(dial, "Büyü", bindcmd("cast"))
	rect(cast_button, 1, 1, 1, 1, -230, -179, -106, -125)
	cast_button.focus_mode = FOCUS_NONE
	btn = button(dial, "↻", bindcmd("cycle"))
	rect(btn, 1, 1, 1, 1, -97, -179, -30, -125)
	btn.focus_mode = FOCUS_NONE
	btn = button(dial, "Atıl", bindcmd("dodge"))
	rect(btn, 1, 1, 1, 1, -330, -113, -241, -49)
	btn.focus_mode = FOCUS_NONE
	movehint = label(hud, "", 17, CREAM)
	rect(movehint, .23, 1, .77, 1, 0, -47, 0, -12)
	movehint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_badge = label(hud, "", 16, MUTED)
	rect(scene_badge, .39, 0, .68, 0, 0, 25, 0, 66)
	scene_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func gameplay():
	wipe()
	hud.show()
	dial.visible = not pad


func set_goal(area: String, task: String):
	place.text = area.to_upper()
	objective.text = task


func guidance(where: Vector2, meters: float, near: bool, act: String, sname: String, extra: String):
	if not is_instance_valid(hud) or not hud.visible:
		return
	var w = get_viewport_rect().size
	var p = where.clamp(Vector2(35, 120), w - Vector2(40, 156))
	marker.position = p - Vector2(21, 23)
	distance_label.position = p + Vector2(-50, 15)
	distance_label.text = "%d m" % roundi(meters)
	marker.visible = meters > 2
	distance_label.visible = meters > 2
	prompt.text = act if near else "Hedefe git"
	prompt.disabled = not near
	cast_button.text = sname if sname != "" else "Büyü yok"
	cast_button.disabled = sname == ""
	movehint.text = (
		extra
		if extra != ""
		else (
			"✕  " + act + "     ○  Atıl     R2  Büyü     L1/R1  Seç"
			if pad
			else "Sol: yürü    •    Sağda sürükle: bakış"
		)
	)
	dial.visible = not pad


func stick_pos(v: Vector2):
	if is_instance_valid(stick):
		stick.position = Vector2(50, 50) + v * 44


func ribbon(name_: String, sub: String):
	new_page()
	var a = panel(page, Color(.025, .065, .067, .76))
	rect(a, 0, .71, 1, 1)
	var l = label(a, sub.to_upper(), 18, GOLD)
	rect(l, .07, .13, .8, .36)
	l = label(a, name_, 45, CREAM, true)
	rect(l, .07, .33, .72, .85)
	var b = button(a, "İlerle   ›", bindcmd("close_ribbon"))
	rect(b, 1, .5, 1, .5, -207, -27, -43, 27)
	choices.append(b)
	b.grab_focus()


func dialogue(speaker: String, text: String, count: String):
	new_page()
	var g = grad(page, [Color.TRANSPARENT, Color.TRANSPARENT, Color(.025, .065, .065, .55)], true)
	g.mouse_filter = MOUSE_FILTER_IGNORE
	var p = panel(page, Color(.043, .10, .108, .97), Color(GOLD, .55), 12)
	rect(p, .065, 1, .935, 1, 0, -234, 0, -27)
	var l = label(p, "◆   " + speaker.to_upper(), 19, GOLD)
	rect(l, 0, 0, .72, 0, 25, 10, 0, 45)
	l = label(p, count, 16, MUTED)
	rect(l, .73, 0, 1, 0, 0, 10, -25, 43)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l = label(p, text, 29 if big else 26, CREAM, true)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rect(l, 0, 0, 1, 1, 25, 47, -25, -44)
	var b = button(p, "Devam   ›", bindcmd("next"))
	rect(b, 1, 1, 1, 1, -162, -48, -18, -6)
	choices.append(b)
	b.grab_focus()


func sheet(title_: String, subtitle: String):
	new_page()
	var shade = panel(page, Color(.025, .055, .06, .72))
	cover(shade)
	var p = panel(page, Color(.052, .115, .12, .98), Color(GOLD, .65), 16)
	rect(p, .14, .075, .86, .925)
	var q = label(p, subtitle.to_upper(), 16, GOLD)
	rect(q, .055, .045, .94, .10)
	q = label(p, title_, 36, CREAM, true)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rect(q, .055, .105, .95, .26)
	return p


func question(q: String, opts: Array):
	var p = sheet(q, "İLYAN'IN SÖZÜ     /     KARAR")
	var y = .31
	for i in range(opts.size()):
		var idx = i
		var b = button(p, opts[i][0], func(): option.emit(idx))
		rect(b, .065, y, .935, y + .135)
		choices.append(b)
		y += .17
	if choices.size():
		choices[0].grab_focus()


func basic(title_: String, sub: String, items: Array, body = ""):
	var p = sheet(title_, sub)
	var y = .285
	if body != "":
		var l = label(p, body, 21, CREAM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rect(l, .06, .265, .94, .43)
		y = .455
	var step = minf(.115, (.955 - y) / maxf(items.size(), 1))
	for item in items:
		var b = button(p, item[0], bindcmd(item[1]), choices.is_empty())
		rect(b, .12, y, .88, y + step * .85)
		y += step
		choices.append(b)
	if choices.size():
		choices[0].grab_focus()


func reading(title_: String, sub: String, body: String, back: String):
	var p = sheet(title_, sub)
	scroll = ScrollContainer.new()
	p.add_child(scroll)
	rect(scroll, .06, .275, .94, .83)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var txt = RichTextLabel.new()
	scroll.add_child(txt)
	txt.fit_content = true
	txt.scroll_active = false
	txt.size_flags_horizontal = SIZE_EXPAND_FILL
	txt.add_theme_font_override("normal_font", SERIF)
	txt.add_theme_font_size_override("normal_font_size", 26 if big else 22)
	txt.add_theme_color_override("default_color", CREAM)
	txt.add_theme_constant_override("line_separation", 7)
	txt.text = body
	var b = button(p, "‹   Geri", bindcmd(back))
	rect(b, .06, .86, .32, .95)
	choices.append(b)
	b.grab_focus()
	b = button(p, "↑", func(): scroll.scroll_vertical -= 230)
	rect(b, .67, .86, .79, .95)
	choices.append(b)
	b = button(p, "↓", func(): scroll.scroll_vertical += 230)
	rect(b, .81, .86, .94, .95)
	choices.append(b)


func exercise(mode: String, serial: int):
	new_page()
	var p = panel(page, Color(.035, .09, .10, .94), Color(GOLD, .55))
	rect(p, .10, .38, .90, .963)
	ritual = Ritual.new()
	p.add_child(ritual)
	rect(ritual, .08, .22, .92, .73)
	ritual.begin(mode, serial)
	ritual.effect.connect(func(id, ok): ritual_effect.emit(id, ok))
	ritual.finished.connect(func(): ritual_done.emit())
	var names = {
		"wick": "Fitil",
		"water": "Dipses",
		"guard": "Siper",
		"dodge": "Yana adım",
		"gust": "Yel Avucu"
	}
	var l = label(
		p, "ÖLÇÜ EVİ     /     " + ("SAHA SINAMASI" if ritual.field else "UYGULAMA"), 15, GOLD
	)
	rect(l, .035, .025, .66, .10)
	l = label(p, names[ritual.kind], 33, CREAM, true)
	rect(l, .035, .095, .45, .22)
	rit_hint = label(p, ritual.hint, 19, MUTED)
	rit_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rect(rit_hint, .4, .035, .97, .22)
	var left = button(p, "‹", func(): ritual.adjust(-1))
	rect(left, .16, .785, .265, .95)
	var right = button(p, "›", func(): ritual.adjust(1))
	rect(right, .735, .785, .84, .95)
	rit_button = button(p, ritual.caption(), func(): pass, true)
	rect(rit_button, .28, .785, .72, .95)
	rit_button.button_down.connect(ritual.press)
	rit_button.button_up.connect(ritual.released)
	if ritual.kind in ["guard", "dodge"]:
		left.hide()
		right.hide()
	var close = button(page, "‹   Derse dön", bindcmd("leave_ritual"))
	rect(close, 0, 0, 0, 0, 26, 24, 205, 76)


func _process(_dt):
	if is_instance_valid(board):
		board_hint.text = board.hint + ("    ✕ Döndür · △ Dene" if pad else "")
	if is_instance_valid(ritual):
		rit_hint.text = ritual.hint
		rit_button.text = ritual.caption() + "    ·    %d/%d" % [ritual.success, ritual.rounds]


func nav(step: int):
	if choices.is_empty():
		return
	var i = choices.find(get_viewport().gui_get_focus_owner())
	choices[posmod(i + step, choices.size())].grab_focus()


func accept():
	var f = get_viewport().gui_get_focus_owner()
	if f in choices and is_instance_valid(f):
		f.pressed.emit()
	elif choices.size():
		choices[0].pressed.emit()


func chart(which: int):
	var box = sheet(
		["Mektubun yolu", "Künklerin kesiti", "Görünce çizeriz"][which],
		"BALMUMU LEVHA    /    YOL ÇİZİMİ"
	)
	board = preload("res://scripts/route_board.gd").new()
	box.add_child(board)
	rect(board, .05, .31, .95, .75)
	board.setup(which)
	board.cue.connect(func(key): board_sound.emit(key))
	board.solved.connect(func(): command.emit("chart_solved"))
	var l = label(box, "I  " + board.names[1] + "     ◇     II  " + board.names[2], 17, GOLD)
	rect(l, .07, .24, .94, .31)
	board_hint = label(box, board.hint, 16, MUTED)
	board_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rect(board_hint, .07, .75, .93, .835)
	var b = button(box, "‹  Masadan kalk", bindcmd("leave_ritual"))
	rect(b, .06, .85, .30, .955)
	b = button(box, "Döndür  ↻", func(): board.turn_tile())
	rect(b, .335, .85, .62, .955)
	b = button(box, "Yolu dene  ›", func(): board.submit(), true)
	rect(b, .655, .85, .94, .955)

extends Control
## A tactile, topology-checked wax tablet. Rotating a tile changes its actual connections.
signal solved
signal cue(id: String)
var ground = Color("203432")
var ivory = Color("eedfc4")
var amber = Color("dfb375")
var aqua = Color("75c1ae")
var font = preload("res://fonts/sans.ttf")
var tiles = []
var turns = []
var route = []
var names = []
var marks = []
var reach = []
var cursor = 0
var width_ = 5
var height_ = 3
var hint = ""
var serial = 0
var finished = false
var once = false
const D = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const PLANS = [
	[[5, 6, 1, 2, 7, 12, 13, 8, 9], [1, 12], ["Mektupçu", "Ortak Avlu", "Astar", "Eşik"]],
	[
		[10, 11, 6, 1, 2, 3, 8, 7, 12, 13, 14],
		[1, 7],
		["Kaynak", "Birinci kap", "İkinci kap", "Oluk"]
	],
	[[0, 5, 6, 11, 12, 7, 8, 3, 4], [11, 8], ["Ölçü Evi", "Künk", "Üçdil", "Nar hattı"]]
]


func setup(which: int):
	serial = which
	route = PLANS[which][0]
	marks = PLANS[which][1]
	names = PLANS[which][2]
	for i in range(15):
		tiles.append([3, 5, 6, 9, 12][(i + which) % 5])
		turns.append((i * 7 + which * 3 + 1) % 4)
	for i in range(route.size()):
		var k = route[i]
		var a = 8 if i == 0 else dir_bit(k, route[i - 1])
		var b = 2 if i + 1 == route.size() else dir_bit(k, route[i + 1])
		tiles[k] = a | b
	turns[route[0]] = 0
	turns[route[-1]] = 0
	cursor = route[1]
	reflow()
	hint = "Açık uçları birleştir. Altın çentikli iki durağı da aynı yol üzerinde bırak."
	mouse_filter = MOUSE_FILTER_STOP


func dir_bit(a: int, b: int) -> int:
	return 1 << D.find(Vector2i(b % 5, int(b / 5)) - Vector2i(a % 5, int(a / 5)))


func edges(k: int) -> int:
	var t = turns[k] % 4
	return ((tiles[k] << t) | (tiles[k] >> (4 - t))) & 15


func reflow():
	reach = [route[0]]
	var at = 0
	while at < reach.size():
		var i = reach[at]
		at += 1
		var p = Vector2i(i % 5, int(i / 5))
		for d in range(4):
			var n = p + D[d]
			var j = n.y * 5 + n.x
			if (
				n.x >= 0
				and n.x < 5
				and n.y >= 0
				and n.y < 3
				and edges(i) & (1 << d)
				and edges(j) & (1 << ((d + 2) % 4))
				and not reach.has(j)
			):
				reach.append(j)
	queue_redraw()


func step(dx: int, dy: int):
	cursor = posmod(int(cursor / 5) + dy, 3) * 5 + posmod(cursor % 5 + dx, 5)
	queue_redraw()


func turn_tile():
	if finished:
		return
	if cursor == route[0] or cursor == route[-1]:
		hint = "Mühürlü uç sabit. Komşu parçanın yönünü değiştir."
		return
	turns[cursor] = (turns[cursor] + 1) % 4
	cue.emit("tap")
	reflow()
	hint = "Yeşil hat kaynağa bağlı. Koyu çizgiler henüz kuru."


func submit():
	if finished:
		return
	if reach.has(route[-1]) and reach.has(marks[0]) and reach.has(marks[1]):
		finished = true
		cue.emit("seal")
		solved.emit()
	else:
		hint = "Çizgi henüz tamamlanmadı. Ulaşılmayan ilk altın çentiği veya açık ucu ara."
		cue.emit("miss")


func cell() -> float:
	return minf((size.x - 148) / 5., size.y / 3.)


func origin() -> Vector2:
	return (size - Vector2(cell() * 5, cell() * 3)) * .5


func _gui_input(e):
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		var p = (e.position - origin()) / cell()
		var x = floori(p.x)
		var y = floori(p.y)
		if x >= 0 and x < 5 and y >= 0 and y < 3:
			cursor = y * 5 + x
			turn_tile()
			accept_event()


func _draw():
	if tiles.is_empty():
		return
	var c = cell()
	var p = origin()
	for i in range(15):
		var q = p + Vector2(i % 5, int(i / 5)) * c
		var mid = q + Vector2.ONE * c * .5
		draw_rect(
			Rect2(q + Vector2.ONE * 2, Vector2.ONE * (c - 4)),
			ground.lightened(.09 if i == cursor else .015)
		)
		if i == cursor:
			draw_rect(Rect2(q + Vector2.ONE * 2, Vector2.ONE * (c - 4)), amber, false, 3)
		for j in range(4):
			if edges(i) & (1 << j):
				draw_line(
					mid,
					mid + Vector2(D[j]) * c * .5,
					aqua if reach.has(i) else Color("7a8475"),
					maxf(4, c * .076),
					true
				)
		draw_circle(mid, c * .09, aqua if reach.has(i) else Color("7a8475"))
		if i in marks or i == route[0] or i == route[-1]:
			draw_arc(mid, c * .19, 0, TAU, 24, amber, 3, true)
			if i in marks:
				draw_string(
					font,
					q + Vector2(6, c * .21),
					str(marks.find(i) + 1),
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					14,
					amber
				)
	var sy = p.y + (int(route[0] / 5) + .5) * c
	var ey = p.y + (int(route[-1] / 5) + .5) * c
	draw_string(font, Vector2(0, sy + 6), names[0], HORIZONTAL_ALIGNMENT_RIGHT, p.x - 8, 16, ivory)
	draw_string(
		font, Vector2(p.x + c * 5 + 8, ey + 6), names[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ivory
	)

extends RefCounted
## Ready-to-tile scans; world projection preserves scale across wall lengths.
static var cache = {}


static func get_material(key: String, meters = 2.0) -> StandardMaterial3D:
	var id = key + str(meters)
	if cache.has(id):
		return cache[id]
	var p = "res://art/pbr/" + key
	var m = StandardMaterial3D.new()
	var tints = {"boards":"827263", "lime":"a49d8c", "masonry":"adaba0", "cobble":"b2aca2", "bark":"aeaa98", "stone":"928f85"}
	m.albedo_color = Color(tints.get(key,"ffffff"))
	m.metallic_specular = .24
	m.albedo_texture = load(p + "_color.jpg")
	m.normal_enabled = true
	m.normal_texture = load(p + "_normal.jpg")
	m.normal_scale = .44 if key in ["lime", "boards"] else .70
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / meters
	if ResourceLoader.exists(p + "_orm.jpg"):
		var orm = load(p + "_orm.jpg")
		m.ao_enabled = true
		m.ao_texture = orm
		m.roughness_texture = orm
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	cache[id] = m
	return m

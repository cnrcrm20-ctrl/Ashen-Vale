extends Node3D
## A live skeletal rig, not a sprite. Clips share a skin and are cross-faded.
const RIGS = {
	"İlyan": ["Rogue", 0.76],
	"Mina": ["Rogue", 0.62],
	"Hedi": ["Mage", 0.89],
	"Tamar": ["Rogue_Hooded", 0.95],
	"Ruva": ["Mage", 0.96],
	"Oris": ["Barbarian", 0.78],
	"Ekin": ["Rogue_Hooded", 0.75],
	"Sarpel": ["Knight", 0.79],
	"Ese": ["Mage", 0.82]
}
var animator: AnimationPlayer
var rig: Node3D
var title = ""
var action_time = 0.0
var last_clip = ""
var heading = 0.0
var voice_phase = 0.0
var mark: MeshInstance3D


func make(person: String):
	title = person
	var style = RIGS.get(person, ["Rogue", 0.84])
	rig = load("res://art/actors/%s.glb" % style[0]).instantiate()
	add_child(rig)
	rig.scale = Vector3.ONE * float(style[1])
	for m in rig.find_children("*", "MeshInstance3D", true, false):
		var n = str(m.name)
		if not (
			"_Body" in n
			or "_Head" in n
			or "_Leg" in n
			or "_Arm" in n
			or "_Cape" in n
			or "_Hat" in n
			or "_Helmet" in n
		):
			m.hide()
		if person in ["Ruva", "Hedi", "Ese"] and "_Hat" in n:
			m.hide()
		if person == "Sarpel" and "_Helmet" in n:
			m.hide()
	var players = rig.find_children("*", "AnimationPlayer", true, false)
	if players.size():
		animator = players[0]
		for clip in ["Idle", "Walking_A", "Running_A", "Sit_Chair_Idle", "Spellcasting"]:
			if animator.has_animation(clip):
				animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		play("Idle")
		animator.seek(fposmod(person.hash() * 0.01, 1.0), true)
	if person == "İlyan":
		var skins = rig.find_children("*", "Skeleton3D", true, false)
		if skins.size():
			var sk: Skeleton3D = skins[0]
			for i in range(sk.get_bone_count()):
				var bn = sk.get_bone_name(i).to_lower()
				if bn in ["hand.r", "hand_r", "handright", "hand_right", "wrist.r", "hand_r_0"]:
					var bone = BoneAttachment3D.new()
					sk.add_child(bone)
					bone.bone_name = sk.get_bone_name(i)
					mark = MeshInstance3D.new()
					var gem = SphereMesh.new()
					gem.radius = .037
					gem.height = .074
					mark.mesh = gem
					bone.add_child(mark)
					var mat = StandardMaterial3D.new()
					mat.albedo_color = Color("ffbf77")
					mat.emission_enabled = true
					mat.emission = Color("ee913f")
					mark.material_override = mat
					break


func play(clip: String, speed = 1.0, force = false):
	if animator == null or not animator.has_animation(clip):
		return
	if force or last_clip != clip:
		animator.speed_scale = speed
		animator.play(clip, 0.16, 1.0)
		last_clip = clip
	else:
		animator.speed_scale = speed


func gesture(clip: String, time = 0.8):
	action_time = time
	if animator:
		animator.speed_scale = 1.0
	play(clip, 1.0, true)


func motion(speed: float, direction: Vector3, delta: float):
	action_time = maxf(0.0, action_time - delta)
	if direction.length_squared() > 0.015:
		heading = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, heading, 1.0 - exp(-delta * 10.5))
	if action_time > 0:
		return
	if speed > 3.1:
		play("Running_A", clampf(speed / 4.9, 0.74, 1.25))
	elif speed > 0.12:
		play("Walking_A", clampf(speed / 2.2, 0.57, 1.5))
	else:
		play("Idle")


func face(point: Vector3):
	var d = point - global_position
	if d.length_squared() > .015:
		heading = atan2(d.x, d.z)

extends Node3D
## A live skeletal rig, not a sprite. Clips share a skin and are cross-faded.
const RIGS = {
	"Lyander": ["lyander", .84], "Lyra": ["lyra", .72], "Matilda": ["matilda", .96],
	"Aldric": ["aldric", 1.04], "Magnus": ["magnus", 1.0], "Dorian": ["clerk", .96],
	"Ariadne": ["ariadne", .84], "Valer": ["clerk", .85], "Edda": ["edda", .93], "Orfen": ["orfen", .95],
	"İskele kâtibi": ["clerk", 1.0], "Nöbetçi": ["guard", 1.0],
	"Boyacı": ["matilda", .92], "Çömlekçi": ["orfen", .98], "Değirmenci": ["aldric", .94],
	"Mektupçu": ["ariadne", .94], "Su taşıyan": ["matilda", .97], "Yamak": ["lyander", .80], "Hamurcu": ["matilda", .98]
}
const MOTION = preload("res://art/company/motion.glb")
const CLIPS = {
	"Idle": "Idle_Loop", "Walking_A": "Walk_Loop", "Running_A": "Sprint_Loop",
	"Use_Item": "Idle_Talking_Loop", "PickUp": "PickUp_Table", "Block": "Shield_OneShot",
	"Spellcasting": "Spell_Simple_Shoot", "Spellcast_Shoot": "Spell_Simple_Shoot",
	"Hit_A": "Hit_Chest", "Dodge_Left": "Roll", "Dodge_Forward": "Roll"
}
static var libraries: Dictionary = {}
static var wardrobe: Dictionary = {}
var animator: AnimationPlayer
var rig: Node3D
var title = ""
var action_time = 0.0
var last_clip = ""
var heading = 0.0
var crouched = false
var mark: Marker3D
var birth_skin: StandardMaterial3D
var face_meshes: Array[MeshInstance3D] = []
var skeleton: Skeleton3D
var head = -1
var sockets = {}
var eyeline = preload("res://scripts/eyeline.gd").new()
var gaze_left = 0.


func make(person: String):
	title = person
	var style = RIGS.get(person, ["lyander", .97])
	rig = load("res://art/company/%s.gltf" % style[0]).instantiate()
	add_child(rig)
	rig.scale = Vector3.ONE * float(style[1])
	# School pupils do not wear the outfit pack's ceremonial crown or adult beard.
	for m in rig.find_children("*", "MeshInstance3D", true, false):
		for surface in range(m.mesh.get_surface_count()):
			var mat = m.get_active_material(surface)
			if not mat is StandardMaterial3D: continue
			var name_ = str(mat.resource_name)
			if name_ == "Kalkstein_Forearm" and person == "Lyander":
				birth_skin = mat.duplicate(); birth_skin.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
				birth_skin.detail_albedo = preload("res://art/company/skins/forearm-ink.svg")
				m.set_surface_override_material(surface,birth_skin)
			var tint = ""
			if "Hair" in name_ or "Hair" in str(m.name) or "Eyebrows" in str(m.name):
				tint = {"Lyander":"98765b","Lyra":"ab7956","Ariadne":"604034","Matilda":"69594a","Magnus":"a59884","Orfen":"715441"}.get(person,"614838")
			elif "Peasant" in name_ and person == "Lyra": tint = "a4aa95"
			elif "Peasant" in name_ and person == "Lyander": tint = "a79784"
			elif "Ranger" in name_ and person == "Aldric": tint = "9a9b93"
			if tint != "":
				var k = "%d:%s" % [mat.get_instance_id(),tint]
				if not wardrobe.has(k):
					var m2 = mat.duplicate(); m2.albedo_color *= Color(tint)
					m2.metallic_specular = .23; wardrobe[k] = m2
				m.set_surface_override_material(surface,wardrobe[k])
		if ("Beard" in str(m.name) and person not in ["Aldric", "Magnus", "İskele kâtibi"]) or "Crown" in str(m.name):
			m.hide()
		if person == "Edda" and "_Belt" in str(m.name): m.hide()
		if m.find_blend_shape_by_name("SpeechJaw") >= 0:
			face_meshes.append(m)
		if person in ["Dorian", "İskele kâtibi", "Valer", "Mektupçu", "Ariadne"] and "_Acc_" in str(m.name): m.hide()
	skeleton = rig.find_children("*", "Skeleton3D", true, false)[0]
	head = skeleton.find_bone("Head")
	skeleton.add_child(eyeline); eyeline.bind(skeleton,head)
	var dest: NodePath = rig.get_path_to(skeleton)
	if not libraries.has(dest):
		var donor = MOTION.instantiate()
		var player: AnimationPlayer = donor.find_children("*", "AnimationPlayer", true, false)[0]
		var lib = AnimationLibrary.new()
		for key in player.get_animation_list():
			var clip: Animation = player.get_animation(key).duplicate()
			for i in range(clip.get_track_count() - 1, -1, -1):
				var path = clip.track_get_path(i)
				var bone_name = path.get_concatenated_subnames()
				if bone_name == &"" or skeleton.find_bone(bone_name) < 0:
					clip.remove_track(i)
				else:
					clip.track_set_path(i, NodePath(str(dest) + ":" + str(bone_name)))
			if str(key) in ["Crouch_Fwd", "Crouch_Idle", "Idle", "Idle_FoldArms", "Idle_Lantern", "Idle_No", "Idle_Talking", "Idle_Torch", "Jump", "Push", "Sitting_Talking", "Sprint", "Walk"]:
				clip.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation(key, clip)
		libraries[dest] = lib
		donor.free()
	animator = AnimationPlayer.new()
	rig.add_child(animator)
	animator.add_animation_library(&"", libraries[dest])
	play("Idle")
	animator.seek(fposmod(person.hash() * .013, 1.0), true)
	if person == "Lyander":
		mark = Marker3D.new(); socket("lowerarm_r").add_child(mark)
		mark.position = Vector3(0,.153,.041)


func show_mark(revealed: bool):
	if mark: mark.visible = revealed
	if birth_skin: birth_skin.detail_enabled = revealed


func mark_pose() -> Transform3D:
	var bind = skeleton.get_bone_global_pose(skeleton.find_bone("lowerarm_r"))
	return skeleton.global_transform * bind * mark.transform


func play(clip: String, speed = 1.0, force = false):
	clip = str(CLIPS.get(clip, clip)).trim_suffix("_Loop")
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
	gaze_left = maxf(0.,gaze_left-delta)
	if gaze_left == 0. and eyeline.active: eyeline.active = false
	if direction.length_squared() > 0.015:
		heading = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, heading, 1.0 - exp(-delta * 10.5))
	if action_time > 0:
		return
	if crouched:
		play("Crouch_Fwd_Loop" if speed > .12 else "Crouch_Idle_Loop")
	elif speed > 3.1:
		play("Running_A", clampf(speed / 4.9, 0.74, 1.25))
	elif speed > 0.12:
		play("Walking_A", clampf(speed / 2.2, 0.57, 1.5))
	else:
		play("Idle")


func face(point: Vector3):
	var d = point - global_position
	if d.length_squared() > .015:
		heading = atan2(d.x, d.z)


func meet_eyes(point: Vector3):
	eyeline.point = point; eyeline.active = true; gaze_left = .17


func gaze_point() -> Vector3:
	return skeleton.to_global(skeleton.get_bone_global_pose(head).origin) + Vector3.UP * .135 * rig.scale.y


func articulate(jaw: float, lips: float):
	for m in face_meshes:
		m.set_blend_shape_value(0, jaw)
		m.set_blend_shape_value(1, lips)


func socket(bone: String) -> BoneAttachment3D:
	if not sockets.has(bone):
		var joint = BoneAttachment3D.new(); skeleton.add_child(joint); joint.bone_name = bone
		sockets[bone] = joint
	return sockets[bone]

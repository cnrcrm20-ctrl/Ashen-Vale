extends SkeletonModifier3D
## A small look offset *after* the talking/idle animation. Different heights
## matter: a listener need not stare horizontally over a child's shoulder.
var head = -1
var bind_front = Vector3.MODEL_FRONT
var point = Vector3.ZERO


func bind(sk: Skeleton3D, index: int):
	head = index
	if index >= 0:
		bind_front = sk.get_bone_global_rest(head).basis.inverse() * Vector3.MODEL_FRONT
	influence = .72
	active = false


func _process_modification():
	var sk = get_skeleton()
	if not sk or not sk.is_inside_tree() or head < 0: return
	var pose = sk.get_bone_global_pose(head)
	var delta = sk.to_local(point) - pose.origin
	if delta.length_squared() < .025: return
	var wanted = delta.normalized()
	var front = (pose.basis * bind_front).normalized()
	var yaw = wrapf(atan2(wanted.x,wanted.z) - atan2(front.x,front.z), -PI,PI)
	var pitch = asin(clampf(wanted.y,-1.,1.)) - asin(clampf(front.y,-1.,1.))
	var side = front.cross(Vector3.UP).normalized()
	if side.length_squared() < .5: return
	pose.basis = Basis(Vector3.UP,clampf(yaw,-.48,.48)) * Basis(side,clampf(pitch,-.34,.47)) * pose.basis
	sk.set_bone_global_pose(head,pose)

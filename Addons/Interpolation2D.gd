extends Node2D

class_name Interpolation2D

export(NodePath) var target : NodePath setget set_target, get_target


var _m_Target : Node2D

var m_Pos_curr : Vector2 = Vector2()
var m_Pos_prev : Vector2 = Vector2()

var m_Angle_curr : float
var m_Angle_prev : float

var m_Scale_curr : Vector2 = Vector2()
var m_Scale_prev : Vector2 = Vector2()

const SF_ENABLED = 1 << 0
const SF_TRANSLATE = 1 << 1
const SF_ROTATE = 1 << 2
const SF_SCALE = 1 << 3
const SF_GLOBAL_IN = 1 << 4
const SF_GLOBAL_OUT = 1 << 5
const SF_DIRTY = 1 << 6
const SF_INVISIBLE = 1 << 7

export(int, FLAGS, "enabled", "translate", "rotate", "scale", "global in", "global out") var flags : int = SF_ENABLED | SF_TRANSLATE setget _set_flags, _get_flags

##########################################################################################
# USER FUNCS

# call this on e.g. starting a level, AFTER moving the target
# so we can update both the previous and current values
func teleport() :
	var temp_flags = flags
	_SetFlags(SF_TRANSLATE | SF_ROTATE | SF_SCALE)


	_RefreshTransform()
	m_Pos_prev = m_Pos_curr
	m_Angle_prev = m_Angle_curr
	m_Scale_prev = m_Scale_curr

# call frame upate to make sure all components of the node are set
	_process(0)

	# get back the old flags
	flags = temp_flags

func set_enabled(var bEnable : bool) :
	_ChangeFlags(SF_ENABLED, bEnable)
	_SetProcessing()

func is_enabled():
	return _TestFlags(SF_ENABLED)



##########################################################################################


func _ready():
	m_Angle_curr = 0
	m_Angle_prev = 0
	pass

func set_target(new_value) :
	target = new_value
	if is_inside_tree() :
		_FindTarget()


func get_target():
	return target

func _set_flags(new_value) :
	flags = new_value
# we may have enabled or disabled
	_SetProcessing()


func _get_flags():
	return flags

func _SetProcessing() :
	var bEnable = _TestFlags(SF_ENABLED)
	if _TestFlags(SF_INVISIBLE) :
		bEnable = false

	set_process(bEnable);
	set_physics_process(bEnable);
	pass

func _enter_tree() :
	# might have been moved
	_FindTarget()
	pass

func _notification(what) :
	match what:
		# invisible turns off processing
		NOTIFICATION_VISIBILITY_CHANGED:
			_ChangeFlags(SF_INVISIBLE, is_visible_in_tree() == false)
			_SetProcessing()




func _RefreshTransform():
	_ClearFlags(SF_DIRTY);

	if _HasTarget() == false:
		return

	if _TestFlags(SF_GLOBAL_IN) :
		if _TestFlags(SF_TRANSLATE) :
			m_Pos_prev = m_Pos_curr
			m_Pos_curr = _m_Target.get_global_position()

		if _TestFlags(SF_ROTATE) :
			m_Angle_prev = m_Angle_curr
			m_Angle_curr = _m_Target.get_global_rotation()

		if _TestFlags(SF_SCALE) :
			m_Scale_prev = m_Scale_curr
			m_Scale_curr = _m_Target.get_global_scale()
	else:
		if _TestFlags(SF_TRANSLATE) :
			m_Pos_prev = m_Pos_curr
			m_Pos_curr = _m_Target.get_position()

		if _TestFlags(SF_ROTATE) :
			m_Angle_prev = m_Angle_curr
			m_Angle_curr = _m_Target.get_rotation()

		if _TestFlags(SF_SCALE) :
			m_Scale_prev = m_Scale_curr
			m_Scale_curr = _m_Target.get_scale()



func _FindTarget():
	_m_Target = null
	if target.is_empty():
		return

	_m_Target = get_node(target)

	if _m_Target is Node2D:
		return

	_m_Target = null


func _HasTarget()->bool:
	if _m_Target == null:
		return false

	# has not been deleted?
	if is_instance_valid(_m_Target) :
		return true

	_m_Target = null
	return false


func _process(_delta):
	if _TestFlags(SF_DIRTY) :
		_RefreshTransform()


	var f = Engine.get_physics_interpolation_fraction()


	if _TestFlags(SF_GLOBAL_OUT) :
		# translate
		if _TestFlags(SF_TRANSLATE) :
			set_global_position(m_Pos_prev.linear_interpolate(m_Pos_curr, f))

		# rotate
		if _TestFlags(SF_ROTATE) :
			var r = _LerpAngle(m_Angle_prev, m_Angle_curr, f)
			set_global_rotation(r)

		if _TestFlags(SF_SCALE) :
			set_global_scale(m_Scale_prev.linear_interpolate(m_Scale_curr, f))
	else:
		# translate
		if _TestFlags(SF_TRANSLATE) :
			set_position(m_Pos_prev.linear_interpolate(m_Pos_curr, f))

		# rotate
		if _TestFlags(SF_ROTATE) :
			var r = _LerpAngle(m_Angle_prev, m_Angle_curr, f)
			set_rotation(r)

		if _TestFlags(SF_SCALE) :
			set_scale(m_Scale_prev.linear_interpolate(m_Scale_curr, f))


	pass

func _physics_process(_delta) :
	# take care of the special case where multiple physics ticks
	# occur before a frame .. the data must flow!
	if _TestFlags(SF_DIRTY) :
		_RefreshTransform()


	_SetFlags(SF_DIRTY)
	pass

func _LerpAngle(var from : float, var to : float, var weight : float)->float:
	return from + _ShortAngleDist(from, to) * weight

func _ShortAngleDist(var from : float, var to : float)->float:
	var max_angle : float = 2 * PI
	var diff : float = fmod(to-from, max_angle)
	return fmod(2.0 * diff, max_angle) - diff

func _SetFlags(var f) :
	flags |= f

func _ClearFlags(var f) :
	flags &= ~f


func _TestFlags(var f):
	return (flags & f) == f

func _ChangeFlags(var f, var bSet) :
	if bSet:
		_SetFlags(f)
	else:
		_ClearFlags(f)
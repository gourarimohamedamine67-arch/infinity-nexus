extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const TURN_SPEED = 10.0      # vitesse de rotation de Zlorp vers la direction du mouvement
const ANIM_BLEND = 0.2       # durée du fondu entre deux animations (secondes)

const IDLE_ANIM = "zlorp/idle"
const WALK_ANIM = "zlorp/walk"

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var spring_arm = $SpringArm3D
@onready var zlorp = $zlorp
@onready var anim_player: AnimationPlayer = $zlorp/AnimationPlayer

var camera_x_rotation = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# La caméra ne doit pas se cogner contre la capsule du joueur
	spring_arm.add_excluded_object(get_rid())
	_setup_animations()
	anim_player.play(IDLE_ANIM)

func _setup_animations():
	var lib = AnimationLibrary.new()

	# Idle : l'animation de base de Idle.fbx, en boucle
	var idle: Animation = anim_player.get_animation("Take 001").duplicate()
	idle.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation("idle", idle)

	# Walking : on la récupère depuis Walking.fbx (même squelette Mixamo)
	var walk_scene = load("res://assets/characters/Walking.fbx").instantiate()
	var walk: Animation = walk_scene.get_node("AnimationPlayer").get_animation("mixamo_com").duplicate()
	walk_scene.free()
	walk.loop_mode = Animation.LOOP_LINEAR
	_remove_root_motion(walk)
	lib.add_animation("walk", walk)

	anim_player.add_animation_library("zlorp", lib)

# L'anim Mixamo fait avancer les hanches (~1.8 m par cycle) : on bloque X/Z
# pour que Zlorp marche sur place, c'est le CharacterBody3D qui le déplace.
func _remove_root_motion(anim: Animation):
	var track = anim.find_track(NodePath("Skeleton3D:mixamorig1_Hips"), Animation.TYPE_POSITION_3D)
	if track == -1:
		return
	var start: Vector3 = anim.track_get_key_value(track, 0)
	for i in anim.track_get_key_count(track):
		var pos: Vector3 = anim.track_get_key_value(track, i)
		anim.track_set_key_value(track, i, Vector3(start.x, pos.y, start.z))

func _input(event):
	# Clic dans la fenêtre : on reprend la souris
	if event is InputEventMouseButton and event.pressed \
			and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# La caméra ne tourne que si la souris est capturée
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_x_rotation -= event.relative.y * MOUSE_SENSITIVITY
		camera_x_rotation = clamp(camera_x_rotation, -0.8, 0.4)
		spring_arm.rotation.x = camera_x_rotation

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		# Les modèles Mixamo regardent vers +Z : l'angle cible est atan2(x, z)
		var target_yaw = atan2(direction.x, direction.z)
		zlorp.global_rotation.y = lerp_angle(zlorp.global_rotation.y, target_yaw, TURN_SPEED * delta)
		_play(WALK_ANIM)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		_play(IDLE_ANIM)
	move_and_slide()

func _play(anim_name: String):
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name, ANIM_BLEND)

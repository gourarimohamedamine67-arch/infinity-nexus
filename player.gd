extends CharacterBody3D
## Joueur : déplacement (ZQSD/flèches), course (Shift), saut (Espace), caméra à la souris,
## et animations de Zlorp (idle, marche, course, saut) tirées des FBX Mixamo.

# --- Réglages ---
const SPEED = 5.0
const RUN_SPEED = 8.0        # vitesse en courant (Shift)
const RUN_ANIM_SPEED = 1.3   # l'anim Running est prévue pour ~2,6 m/s : on l'accélère un peu

# --- Vie et endurance ---
const MAX_HEALTH = 100.0
const MAX_STAMINA = 100.0
const SPRINT_COST = 20.0           # endurance par seconde de course
const STAMINA_REGEN = 18.0         # endurance récupérée par seconde
const STAMINA_REGEN_DELAY = 0.8    # pause avant de récupérer après un effort (s)
const EXHAUSTED_UNTIL = 25.0       # essoufflé à 0 : plus de course avant de remonter à 25
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const TURN_SPEED = 10.0      # vitesse de rotation de Zlorp vers la direction du mouvement
const ANIM_BLEND = 0.2       # durée du fondu entre deux animations (secondes)

# --- Animations (librairie "zlorp" construite au lancement) ---
const IDLE_ANIM = "zlorp/idle"
const WALK_ANIM = "zlorp/walk"
const RUN_ANIM = "zlorp/run"
const JUMP_ANIM = "zlorp/jump"
const HIPS_POS = "Skeleton3D:mixamorig1_Hips"

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

signal health_changed(value: float, max_value: float)
signal stamina_changed(value: float, max_value: float, exhausted: bool)
signal died

@onready var spring_arm = $SpringArm3D
@onready var zlorp = $zlorp
@onready var anim_player: AnimationPlayer = $zlorp/AnimationPlayer

var camera_x_rotation := 0.0   # inclinaison verticale de la caméra (radians)
var inventory := Inventory.new()   # porté par le joueur : persiste d'un monde à l'autre
var controls_enabled := true   # faux quand un menu est ouvert (inventaire…)
var health := MAX_HEALTH
var stamina := MAX_STAMINA
var exhausted := false             # endurance tombée à 0 : la course est bloquée
var stamina_regen_wait := 0.0
var jumping := false
var jump_start_time := 0.0     # moment de l'anim où Zlorp est le plus accroupi (impulsion)
var jump_anim_speed := 1.0     # vitesse pour caler le sommet de l'anim sur le sommet du saut

func _ready():
	add_to_group("player")  # les portails reconnaissent le joueur par ce groupe
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# La caméra ne doit pas se cogner contre la capsule du joueur
	spring_arm.add_excluded_object(get_rid())
	_setup_animations()
	anim_player.play(IDLE_ANIM)

# --- Préparation des animations ---

## Copie les anims Mixamo dans une librairie "zlorp", en boucle et sans root motion.
func _setup_animations():
	var lib = AnimationLibrary.new()

	# Idle : dans Idle.fbx, "Take 001" est la T-pose (1 clé = pose de repos).
	# La vraie anim d'idle est "mixamo_com".
	var idle: Animation = anim_player.get_animation("mixamo_com").duplicate()
	idle.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation("idle", idle)

	var walk = _load_mixamo_anim("res://assets/characters/Walking.fbx")
	walk.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation("walk", walk)

	var run = _load_mixamo_anim("res://assets/characters/Running.fbx")
	run.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation("run", run)

	var jump = _load_mixamo_anim("res://assets/characters/Jumping.fbx")
	jump.loop_mode = Animation.LOOP_NONE
	lib.add_animation("jump", jump)
	_compute_jump_timing(jump)

	anim_player.add_animation_library("zlorp", lib)

# Récupère l'anim "mixamo_com" d'un FBX Mixamo (même squelette que Zlorp)
# et supprime son root motion.
func _load_mixamo_anim(path: String) -> Animation:
	var scene = load(path).instantiate()
	var anim: Animation = scene.get_node("AnimationPlayer").get_animation("mixamo_com").duplicate()
	scene.free()
	_remove_root_motion(anim)
	return anim

# Les anims Mixamo déplacent les hanches (ex. Walking : ~1.8 m par cycle) : on bloque X/Z
# pour que Zlorp reste sur place, c'est le CharacterBody3D qui le déplace.
func _remove_root_motion(anim: Animation):
	var track = anim.find_track(NodePath(HIPS_POS), Animation.TYPE_POSITION_3D)
	if track == -1:
		return
	var start: Vector3 = anim.track_get_key_value(track, 0)
	for i in anim.track_get_key_count(track):
		var pos: Vector3 = anim.track_get_key_value(track, i)
		anim.track_set_key_value(track, i, Vector3(start.x, pos.y, start.z))

# Jumping.fbx dure 2.37 s (accroupi -> saut -> réception) alors que le saut physique
# dure ~0.9 s. On démarre l'anim au point le plus bas avant le sommet, et on règle
# la vitesse pour que le sommet de l'anim coïncide avec le sommet du saut.
func _compute_jump_timing(anim: Animation):
	var track = anim.find_track(NodePath(HIPS_POS), Animation.TYPE_POSITION_3D)
	if track == -1:
		return
	var peak_i = 0
	for i in anim.track_get_key_count(track):
		if anim.track_get_key_value(track, i).y > anim.track_get_key_value(track, peak_i).y:
			peak_i = i
	var low_i = 0
	for i in peak_i:
		if anim.track_get_key_value(track, i).y < anim.track_get_key_value(track, low_i).y:
			low_i = i
	jump_start_time = anim.track_get_key_time(track, low_i)
	var anim_rise = anim.track_get_key_time(track, peak_i) - jump_start_time
	var physics_rise = JUMP_VELOCITY / gravity
	if anim_rise > 0.0:
		jump_anim_speed = anim_rise / physics_rise

# --- Contrôles ---

# Les menus (hud.gd) reçoivent les événements en premier : un clic ou Échap qu'ils
# utilisent n'arrive jamais ici. Règles de la souris :
#   - menu ouvert : souris libre, le joueur ne réagit à rien ;
#   - souris libérée (Échap) sans menu : un clic la reprend, SANS frapper ;
#   - souris capturée sans menu : le clic gauche est l'action « attack » (frapper, étape 4).

func _hud_menu_open() -> bool:
	var hud = get_tree().get_first_node_in_group("hud")
	return hud != null and hud.is_menu_open()

func _unhandled_input(event):
	if _hud_menu_open():
		return
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed \
			and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)   # ce clic sert seulement à reprendre la souris
		get_viewport().set_input_as_handled()

func _input(event):
	# La caméra ne tourne que si la souris est capturée (donc jamais avec un menu ouvert)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_x_rotation -= event.relative.y * MOUSE_SENSITIVITY
		camera_x_rotation = clamp(camera_x_rotation, -0.8, 0.4)
		spring_arm.rotation.x = camera_x_rotation

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif jumping and velocity.y <= 0.0:
		jumping = false  # réception au sol
	if controls_enabled and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumping = true
		anim_player.play(JUMP_ANIM, 0.1, jump_anim_speed)
		anim_player.seek(jump_start_time, true)
	var input_dir = Vector2.ZERO
	if controls_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var running = direction != Vector3.ZERO and Input.is_action_pressed("sprint") and not exhausted
	_update_stamina(delta, running)
	if direction:
		var speed = RUN_SPEED if running else SPEED
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Les modèles Mixamo regardent vers +Z : l'angle cible est atan2(x, z)
		var target_yaw = atan2(direction.x, direction.z)
		zlorp.global_rotation.y = lerp_angle(zlorp.global_rotation.y, target_yaw, TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if not jumping:
		if running:
			_play(RUN_ANIM, RUN_ANIM_SPEED)
		elif direction:
			_play(WALK_ANIM)
		else:
			_play(IDLE_ANIM)
	move_and_slide()

## Tourne caméra et Zlorp vers la direction dir (horizontale), ex. à la sortie d'un portail.
func face(dir: Vector3):
	rotation.y = atan2(-dir.x, -dir.z)           # l'avant du Player (caméra) est -Z
	zlorp.global_rotation.y = atan2(dir.x, dir.z)  # l'avant de Zlorp est +Z
	camera_x_rotation = 0.0
	spring_arm.rotation.x = 0.0

func _play(anim_name: String, speed: float = 1.0):
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name, ANIM_BLEND, speed)

# --- Vie et endurance ---

## Consomme de l'endurance pour un effort ponctuel (coup, récolte…). Faux si pas assez.
func spend_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	_set_stamina(stamina - amount)
	stamina_regen_wait = STAMINA_REGEN_DELAY
	return true

func take_damage(amount: float):
	if health <= 0.0:
		return
	health = max(health - amount, 0.0)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0.0:
		died.emit()   # la mort (sac, retour à la base) arrive à l'étape 13

func heal(amount: float):
	health = min(health + amount, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)

func _update_stamina(delta: float, running: bool):
	if running:
		_set_stamina(stamina - SPRINT_COST * delta)
		stamina_regen_wait = STAMINA_REGEN_DELAY
	elif stamina_regen_wait > 0.0:
		stamina_regen_wait -= delta
	elif stamina < MAX_STAMINA:
		_set_stamina(stamina + STAMINA_REGEN * delta)

func _set_stamina(value: float):
	stamina = clamp(value, 0.0, MAX_STAMINA)
	if stamina <= 0.0:
		exhausted = true
	elif exhausted and stamina >= EXHAUSTED_UNTIL:
		exhausted = false
	stamina_changed.emit(stamina, MAX_STAMINA, exhausted)

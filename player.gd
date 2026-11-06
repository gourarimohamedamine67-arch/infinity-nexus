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

# --- Coup (récolte ; le combat viendra à l'étape 11) ---
# Attack_Downward (Mixamo) : armé au plus haut à 0,65 s, impact au plus bas à 0,90 s.
const SWING_ANIM_START = 0.15      # on saute le début de l'anim (position de repos)
const SWING_ANIM_END = 1.4         # et la fin (retour au calme), qui ralentirait le jeu
const SWING_ANIM_IMPACT = 0.90
const SWING_ANIM_SPEED = 1.4       # -> impact 0,54 s après le clic, coup complet en 0,9 s
const SWING_COST = 8.0             # endurance par coup
const HAND_DAMAGE = 1              # dégâts à main nue
const TOOL_DAMAGE_PER_POWER = 3    # pioche (puissance 1) = 3 dégâts
const HIT_REACH = 1.3              # distance du centre du coup devant Zlorp (m)
const HIT_RADIUS = 0.9

# --- Animations (librairie "zlorp" construite au lancement) ---
const IDLE_ANIM = "zlorp/idle"
const WALK_ANIM = "zlorp/walk"
const RUN_ANIM = "zlorp/run"
const JUMP_ANIM = "zlorp/jump"
const SWING_ANIM = "zlorp/swing"
const HIPS_POS = "Skeleton3D:mixamorig1_Hips"
const Items = preload("res://items.gd")
const Recipes = preload("res://recipes.gd")
const Placeables = preload("res://placeables.gd")
const Sounds = preload("res://sounds.gd")
const PLACE_DISTANCE = 2.2         # un objet posé l'est à 2,2 m devant Zlorp (étape 7 : aperçu + grille)

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
var swinging := false
var swing_time := 0.0          # temps écoulé depuis le début du coup (s)
var swing_hit_done := false
var hand_slot: BoneAttachment3D   # main droite de Zlorp : l'objet tenu y est accroché
var held_model: Node3D
var discovered := {}           # objets déjà trouvés au moins une fois (débloquent les recettes)

func _ready():
	add_to_group("player")  # les portails reconnaissent le joueur par ce groupe
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# La caméra ne doit pas se cogner contre la capsule du joueur
	spring_arm.add_excluded_object(get_rid())
	_setup_animations()
	anim_player.play(IDLE_ANIM)
	# Objet tenu en main droite : suit la case sélectionnée de la barre rapide
	hand_slot = BoneAttachment3D.new()
	hand_slot.name = "RightHand"
	hand_slot.bone_name = "mixamorig1_RightHand"
	zlorp.get_node("Skeleton3D").add_child(hand_slot)
	inventory.changed.connect(_update_held_item)
	inventory.item_added.connect(_on_item_added)
	inventory.selected_changed.connect(func(_i): _update_held_item())

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

	var swing = _load_mixamo_anim("res://assets/characters/Attack_Downward.fbx")
	swing.loop_mode = Animation.LOOP_NONE
	lib.add_animation("swing", swing)

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
	elif event.is_action_pressed("attack") and controls_enabled:
		_start_swing()
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
	if swinging:
		_update_swing(delta)
	var input_dir = Vector2.ZERO
	if controls_enabled and not swinging:   # on ne se déplace pas pendant un coup
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
	if swinging:
		pass   # l'anim du coup est déjà lancée
	elif not jumping:
		if running:
			_play(RUN_ANIM, RUN_ANIM_SPEED)
		elif direction:
			_play(WALK_ANIM)
		else:
			_play(IDLE_ANIM)
	move_and_slide()

# --- Coup et récolte ---

func _start_swing():
	if swinging or jumping or not is_on_floor():
		return
	var selected = inventory.selected_item()
	if selected and selected.kind == ItemData.Kind.PLACEABLE:
		_place_selected(selected)   # objet à poser : le clic le pose au lieu de frapper
		return
	if not spend_stamina(SWING_COST):
		_hud_message("Trop fatigué pour frapper", Color(1, 0.6, 0.3))
		return
	swinging = true
	swing_time = 0.0
	swing_hit_done = false
	# Zlorp se tourne vers là où regarde la caméra : on vise avec la souris
	var aim = -global_basis.z
	zlorp.global_rotation.y = atan2(aim.x, aim.z)
	anim_player.play(SWING_ANIM, 0.1, SWING_ANIM_SPEED)
	anim_player.seek(SWING_ANIM_START, true)

func _update_swing(delta: float):
	swing_time += delta
	var impact_at = (SWING_ANIM_IMPACT - SWING_ANIM_START) / SWING_ANIM_SPEED
	var end_at = (SWING_ANIM_END - SWING_ANIM_START) / SWING_ANIM_SPEED
	if not swing_hit_done and swing_time >= impact_at:
		swing_hit_done = true
		_resolve_hit()
	if swing_time >= end_at:
		swinging = false

## Au moment de l'impact : cherche l'objet du décor le plus proche devant Zlorp et le frappe.
func _resolve_hit():
	var forward = zlorp.global_basis.z   # l'avant de Zlorp est +Z
	var center = global_position + forward * HIT_REACH + Vector3.UP * 0.9
	var target = _find_decor_target(center)
	if target == null:
		return
	var world = get_tree().get_first_node_in_group("world")
	if world == null:
		return
	var tool = inventory.selected_item()
	var power = tool.tool_power if tool else 0
	var damage = power * TOOL_DAMAGE_PER_POWER if power > 0 else HAND_DAMAGE
	var result = world.hit_decor(target, damage, power)
	if result.refused:
		_hud_message("Il faut une pioche pour extraire ça", Color(1, 0.6, 0.3))
	elif result.broken:
		var item = Items.get_item(result.item)
		var left = inventory.add(result.item, result.count)
		var got = result.count - left
		if got > 0:
			_hud_message("+%d %s" % [got, item.display_name], item.icon_color.lightened(0.3))
		if left > 0:
			_hud_message("Inventaire plein : %d %s perdu(s)" % [left, item.display_name], Color(1, 0.4, 0.4))

func _find_decor_target(center: Vector3) -> CollisionShape3D:
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = HIT_RADIUS
	query.shape = sphere
	query.transform = Transform3D(Basis(), center)
	query.exclude = [get_rid()]
	var best: CollisionShape3D = null
	var best_dist := INF
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 16):
		var body = hit.collider
		if not (body is StaticBody3D) or body.name != "DecorBody":
			continue
		var col = body.shape_owner_get_owner(body.shape_find_owner(hit.shape))
		if col is CollisionShape3D and col.has_meta("item") and not col.is_queued_for_deletion():
			var d = col.global_position.distance_to(center)
			if d < best_dist:
				best_dist = d
				best = col
	return best

## Affiche l'objet de la case sélectionnée dans la main droite de Zlorp (outils seulement).
func _update_held_item():
	var item = inventory.selected_item()
	var wanted: PackedScene = null
	if item and item.model and item.kind == ItemData.Kind.TOOL:
		wanted = item.model
	if held_model and held_model.get_meta("scene", null) == wanted:
		return
	if held_model:
		held_model.queue_free()
		held_model = null
	if wanted:
		held_model = wanted.instantiate()
		held_model.set_meta("scene", wanted)
		held_model.scale = Vector3.ONE * item.model_scale
		hand_slot.add_child(held_model)

# --- Fabrication ---

## Nouvel objet trouvé : il peut débloquer des recettes.
func _on_item_added(id: StringName, _count: int):
	if discovered.has(id):
		return
	var before = Recipes.known(discovered).size()
	discovered[id] = true
	var unlocked = Recipes.known(discovered).size() - before
	var item = Items.get_item(id)
	if unlocked > 0:
		_hud_message("Nouvel ingrédient : %s · %d nouvelle(s) recette(s) (Tab)" % [item.display_name, unlocked], Color(0.7, 1.0, 0.7))

func is_near_workbench() -> bool:
	return Placeables.near_workbench(get_tree(), global_position)

## Fabrique une recette si possible. Renvoie vrai si c'est fait.
func craft(recipe: RecipeData) -> bool:
	if not Recipes.can_craft(recipe, inventory, is_near_workbench()):
		return false
	if not inventory.has_room_for(recipe.result, recipe.result_count):
		_hud_message("Inventaire plein", Color(1, 0.4, 0.4))
		return false
	for id in recipe.ingredients:
		inventory.remove(id, recipe.ingredients[id])
	inventory.add(recipe.result, recipe.result_count)
	var item = Items.get_item(recipe.result)
	_hud_message("Fabriqué : %s" % item.display_name, Color(0.7, 1.0, 0.7))
	var world = get_tree().get_first_node_in_group("world")
	if world:
		Sounds.play_at(world, global_position, "impactWood_light")
	return true

## Pose l'objet sélectionné devant Zlorp (version simple ; l'étape 7 ajoute aperçu, rotation et grille).
func _place_selected(item: ItemData):
	var world = get_tree().get_first_node_in_group("world")
	if world == null:
		return
	var aim = -global_basis.z
	aim.y = 0
	aim = aim.normalized()
	var spot = global_position + aim * PLACE_DISTANCE
	var ground = get_tree().get_first_node_in_group("terrain")
	if ground:
		spot.y = ground.get_global_height(spot.x, spot.z)
	var node = Placeables.create(item)
	world.add_child(node)
	node.global_position = spot
	node.global_rotation.y = atan2(-aim.x, -aim.z)   # l'objet fait face à Zlorp
	inventory.remove(item.id, 1)
	Sounds.play_at(world, spot, "impactPlank_medium")
	_hud_message("%s posé" % item.display_name)

func _hud_message(text: String, color: Color = Color.WHITE):
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_message(text, color)

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

extends Node3D
## Scène racine du jeu. Le Player et l'écran de fondu ne sont jamais détruits :
## seuls les mondes (chargés dans $World) changent.

const WORLD_SCENE: PackedScene = preload("res://world.tscn")
const FADE_TIME = 0.5
const ARRIVAL_COOLDOWN = 1.0   ## secondes pendant lesquelles un portail ne peut pas re-téléporter
const ORIGIN_WORLD: WorldData = preload("res://worlds/origin.tres")
const FALL_LIMIT = 15.0        ## sous le sol de plus de 15 m (bord du monde) -> retour au point d'arrivée
const Sfx = preload("res://sfx.gd")
const Families = preload("res://families.gd")

@onready var world_root: Node3D = $World
@onready var player: CharacterBody3D = $Player
@onready var fade_rect: ColorRect = $Fade/ColorRect

var current_world: Node3D = null
var traveling := false
var last_arrival_ms := -100000
var arrival_spot := Vector2.ZERO
var known_worlds := {}   ## graine -> WorldData déjà visités (base des sauvegardes, phase 4)
var portal_sound: AudioStreamPlayer

func _ready():
	add_to_group("game")     # les portails nous trouvent par ce groupe
	portal_sound = AudioStreamPlayer.new()
	portal_sound.stream = Sfx.portal_whoosh()  # son généré par le code, aucun fichier
	portal_sound.volume_db = -4.0
	add_child(portal_sound)
	fade_rect.color.a = 1.0  # on démarre au noir...
	enter_world(0)
	fade_in()                # ...puis on révèle le monde

## Charge le monde de graine seed_value et pose le joueur devant son portail.
## return_seed : monde d'où l'on vient (le portail d'arrivée y ramènera).
func enter_world(seed_value: int, return_seed: int = -1):
	if current_world:
		world_root.remove_child(current_world)  # sort du groupe "terrain" tout de suite
		current_world.queue_free()
	current_world = WORLD_SCENE.instantiate()
	current_world.setup(get_world_data(seed_value), return_seed)
	world_root.add_child(current_world)
	var arrival: Array = current_world.get_arrival(return_seed >= 0)
	arrival_spot = arrival[0]
	place_player(arrival_spot)
	player.face(arrival[1])
	last_arrival_ms = Time.get_ticks_msec()
	var d: WorldData = current_world.data
	print("Arrivée : %s, famille %s, danger %d" % [d.display_name, Families.name_of(d.family), d.danger])

## Appelé par un portail quand le joueur entre dedans.
func travel_through(portal: Node3D):
	if traveling or Time.get_ticks_msec() - last_arrival_ms < ARRIVAL_COOLDOWN * 1000:
		return
	traveling = true
	player.set_physics_process(false)   # le joueur ne bouge plus pendant le fondu
	portal_sound.play()
	await fade_out()
	enter_world(portal.destination_seed, current_world.data.world_seed)
	player.set_physics_process(true)
	await fade_in()
	traveling = false

## Graine 0 = monde d'origine (worlds/origin.tres), sinon monde généré depuis la graine.
func get_world_data(seed_value: int) -> WorldData:
	if not known_worlds.has(seed_value):
		known_worlds[seed_value] = ORIGIN_WORLD if seed_value == 0 else WorldData.generate(seed_value)
	return known_worlds[seed_value]

func _physics_process(_delta):
	# Filet de sécurité (normalement inutile grâce aux crêtes et murs du terrain) : si le joueur tombe hors du monde, on le repose au point d'arrivée
	if not traveling and player.global_position.y < get_ground_height(arrival_spot.x, arrival_spot.y) - FALL_LIMIT:
		place_player(arrival_spot)

## Pose le joueur au sol en (x, z), immobile.
func place_player(spawn: Vector2):
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(spawn.x, get_ground_height(spawn.x, spawn.y) + 0.05, spawn.y)

## Hauteur du sol du monde actuel en coordonnées globales.
func get_ground_height(x: float, z: float) -> float:
	var terrain = get_tree().get_first_node_in_group("terrain")
	if terrain == null:
		return 0.0
	return terrain.get_global_height(x, z)

# --- Fondu au noir (usage : await fade_out()) ---

## Assombrit l'écran jusqu'au noir.
func fade_out() -> Signal:
	return _fade_to(1.0)

## Révèle l'écran depuis le noir.
func fade_in() -> Signal:
	return _fade_to(0.0)

func _fade_to(alpha: float) -> Signal:
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", alpha, FADE_TIME)
	return tween.finished

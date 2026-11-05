extends Node3D
## Scène racine du jeu. Le Player et l'écran de fondu ne sont jamais détruits :
## seuls les mondes (chargés dans $World) changent.

const WORLD_SCENE: PackedScene = preload("res://world.tscn")
const FADE_TIME = 0.5
const ARRIVAL_COOLDOWN = 1.0   ## secondes pendant lesquelles un portail ne peut pas re-téléporter

@onready var world_root: Node3D = $World
@onready var player: CharacterBody3D = $Player
@onready var fade_rect: ColorRect = $Fade/ColorRect

var current_world: Node3D = null
var traveling := false
var last_arrival_ms := -100000

func _ready():
	add_to_group("game")     # les portails nous trouvent par ce groupe
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
	current_world.setup(seed_value, return_seed)
	world_root.add_child(current_world)
	var arrival: Array = current_world.get_arrival(return_seed >= 0)
	place_player(arrival[0])
	player.face(arrival[1])
	last_arrival_ms = Time.get_ticks_msec()

## Appelé par un portail quand le joueur entre dedans.
func travel_through(portal: Node3D):
	if traveling or Time.get_ticks_msec() - last_arrival_ms < ARRIVAL_COOLDOWN * 1000:
		return
	traveling = true
	player.set_physics_process(false)   # le joueur ne bouge plus pendant le fondu
	await fade_out()
	enter_world(portal.destination_seed, current_world.world_seed)
	player.set_physics_process(true)
	await fade_in()
	traveling = false

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

func fade_out() -> Signal:
	return _fade_to(1.0)

func fade_in() -> Signal:
	return _fade_to(0.0)

# Usage : await fade_out()
func _fade_to(alpha: float) -> Signal:
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", alpha, FADE_TIME)
	return tween.finished

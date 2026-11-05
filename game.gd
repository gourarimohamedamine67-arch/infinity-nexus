extends Node3D
## Scène racine du jeu. Le Player et l'écran de fondu ne sont jamais détruits :
## seuls les mondes (chargés dans $World) changent.

const START_WORLD: PackedScene = preload("res://world.tscn")
const FADE_TIME = 0.5

@onready var world_root: Node3D = $World
@onready var player: CharacterBody3D = $Player
@onready var fade_rect: ColorRect = $Fade/ColorRect

var current_world: Node3D = null

func _ready():
	fade_rect.color.a = 1.0  # on démarre au noir...
	load_world(START_WORLD, Vector2.ZERO)
	fade_in()                # ...puis on révèle le monde

## Remplace le monde actuel et pose le joueur au sol en (spawn.x, spawn.y).
func load_world(scene: PackedScene, spawn: Vector2):
	if current_world:
		world_root.remove_child(current_world)  # sort du groupe "terrain" tout de suite
		current_world.queue_free()
	current_world = scene.instantiate()
	world_root.add_child(current_world)
	place_player(spawn)

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

extends Node3D
## Portail Nexus : quand le joueur entre dans la zone, game.gd le téléporte.

@export var destination_seed := 1    ## graine du monde de destination
@export var snap_to_ground := true   ## se pose tout seul sur le terrain au lancement
@export var sink := 0.1              ## enfonce légèrement la base dans le sol (m)

@onready var light: OmniLight3D = $OmniLight3D
@onready var base_energy: float = light.light_energy

var time := 0.0

func _ready():
	$TriggerZone.body_entered.connect(_on_body_entered)
	if snap_to_ground:
		# différé : le terrain doit avoir fini son _ready
		call_deferred("_snap_to_ground")

func _snap_to_ground():
	var terrain = get_tree().get_first_node_in_group("terrain")
	if terrain:
		global_position.y = terrain.get_global_height(global_position.x, global_position.z) - sink

func _on_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.travel_through(self)

func _process(delta):
	# lumière qui « respire »
	time += delta
	light.light_energy = base_energy * (1.0 + 0.25 * sin(time * 2.5))

extends Node3D
## Un monde : terrain + ciel + lumière + portail.
## setup() doit être appelé AVANT add_child() pour que le terrain ne soit généré qu'une fois.

@onready var terrain = $Terrain
@onready var portal = $Portal

var world_seed := 0

## seed : graine de ce monde. return_seed : graine du monde d'où l'on vient (-1 = aucun).
func setup(seed_value: int, return_seed: int = -1):
	world_seed = seed_value
	$Terrain.world_seed = seed_value
	# Le portail ramène d'où l'on vient ; sinon il ouvre vers un nouveau monde.
	$Portal.destination_seed = return_seed if return_seed >= 0 else seed_value + 1
	if seed_value != 0:
		_apply_procedural_colors(seed_value)
	# (graine 0 = monde d'origine : on garde les couleurs faites à la main dans world.tscn)

func _apply_procedural_colors(seed_value: int):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var hue = rng.randf()
	# L'Environment est partagé entre toutes les instances de world.tscn : on le copie
	var env: Environment = $WorldEnvironment.environment.duplicate(true)
	$WorldEnvironment.environment = env
	var sky_mat: ProceduralSkyMaterial = env.sky.sky_material
	sky_mat.sky_top_color = Color.from_hsv(hue, 0.7, 0.12)
	sky_mat.sky_horizon_color = Color.from_hsv(fmod(hue + 0.08, 1.0), 0.7, 0.22)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	$Terrain.color_low = Color.from_hsv(hue, 0.6, 0.25)
	$Terrain.color_high = Color.from_hsv(fmod(hue + 0.1, 1.0), 0.45, 0.65)
	$Terrain.amplitude = rng.randf_range(3.0, 10.0)
	$Terrain.frequency = rng.randf_range(0.012, 0.035)

## Point d'arrivée devant le portail. Renvoie [position xz, direction du regard].
## - par un portail : 3 m devant, dos au portail (on vient d'en sortir)
## - au lancement du jeu : 10 m devant, face au portail (pour le voir)
func get_arrival(by_portal: bool) -> Array:
	var front: Vector3 = portal.global_basis.z.normalized()  # le portail regarde vers +Z
	var distance = 3.0 if by_portal else 10.0
	var spot: Vector3 = portal.global_position + front * distance
	var look = front if by_portal else -front
	return [Vector2(spot.x, spot.z), look]

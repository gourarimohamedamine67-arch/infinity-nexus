extends Node3D
## Un monde : terrain + ciel + soleil + portail, configuré par une WorldData.
## setup() doit être appelé AVANT add_child() pour que le terrain ne soit généré qu'une fois.

@onready var portal = $Portal

var data: WorldData

## data : description du monde. return_seed : graine du monde d'où l'on vient (-1 = aucun).
func setup(world_data: WorldData, return_seed: int = -1):
	data = world_data
	var terrain = $Terrain
	terrain.world_seed = data.world_seed
	terrain.amplitude = data.amplitude
	terrain.frequency = data.frequency
	terrain.octaves = data.octaves
	terrain.color_low = data.color_low
	terrain.color_high = data.color_high

	# L'Environment est partagé entre toutes les instances de world.tscn : on le copie
	var env: Environment = $WorldEnvironment.environment.duplicate(true)
	$WorldEnvironment.environment = env
	var sky_mat: ProceduralSkyMaterial = env.sky.sky_material
	sky_mat.sky_top_color = data.sky_top
	sky_mat.sky_horizon_color = data.sky_horizon
	sky_mat.ground_horizon_color = data.sky_horizon
	sky_mat.ground_bottom_color = data.ground_bottom
	env.fog_enabled = data.fog_density > 0.0
	env.fog_light_color = data.fog_color
	env.fog_density = data.fog_density
	env.fog_sky_affect = 0.3

	var sun: DirectionalLight3D = $DirectionalLight3D
	sun.rotation_degrees = Vector3(data.sun_pitch_deg, data.sun_yaw_deg, 0)
	sun.light_color = data.sun_color
	sun.light_energy = data.sun_energy

	# Le portail ramène d'où l'on vient ; sinon il ouvre vers un nouveau monde.
	$Portal.destination_seed = return_seed if return_seed >= 0 else data.world_seed + 1

## Point d'arrivée devant le portail. Renvoie [position xz, direction du regard].
## - par un portail : 3 m devant, dos au portail (on vient d'en sortir)
## - au lancement du jeu : 10 m devant, face au portail (pour le voir)
func get_arrival(by_portal: bool) -> Array:
	var front: Vector3 = portal.global_basis.z.normalized()  # le portail regarde vers +Z
	var distance = 3.0 if by_portal else 10.0
	var spot: Vector3 = portal.global_position + front * distance
	var look = front if by_portal else -front
	return [Vector2(spot.x, spot.z), look]

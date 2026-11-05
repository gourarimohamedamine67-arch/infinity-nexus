extends GPUParticles3D
## Météo en particules (pluie ou neige) qui suit le joueur.
## Les particules restent dans le monde (local_coords = false) : seul l'émetteur se déplace.
## Usage : var w = preload("res://weather.gd").new(); w.setup(kind, tint); add_child(w)

enum Kind { NONE, RAIN, SNOW, MIST }

const HEIGHT_ABOVE_PLAYER = 14.0

var kind: int = Kind.NONE

## kind : Kind.RAIN ou Kind.SNOW. tint : couleur du monde, mélangée au blanc.
func setup(weather_kind: int, tint: Color):
	kind = weather_kind
	name = "Weather"
	local_coords = false
	visibility_aabb = AABB(Vector3(-25, -35, -25), Vector3(50, 45, 50))
	var process = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.direction = Vector3(0, -1, 0)
	var drop_mat = StandardMaterial3D.new()
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var quad = QuadMesh.new()

	if kind == Kind.RAIN:
		amount = 1500
		lifetime = 1.0
		process.emission_box_extents = Vector3(20, 0.5, 20)
		process.spread = 3.0
		process.initial_velocity_min = 20.0
		process.initial_velocity_max = 26.0
		process.gravity = Vector3(0, -9.8, 0)
		quad.size = Vector2(0.025, 0.6)                          # gouttes allongées
		drop_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y  # toujours verticales
		drop_mat.albedo_color = Color(1, 1, 1).lerp(tint, 0.3)
		drop_mat.albedo_color.a = 0.35
	else:
		amount = 900
		lifetime = 7.0
		process.emission_box_extents = Vector3(22, 0.5, 22)
		process.spread = 25.0
		process.initial_velocity_min = 0.8
		process.initial_velocity_max = 1.5
		process.gravity = Vector3(0, -0.6, 0)
		process.turbulence_enabled = true                        # flocons qui virevoltent
		process.turbulence_noise_strength = 0.6
		process.turbulence_noise_scale = 4.0
		quad.size = Vector2(0.1, 0.1)
		drop_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		drop_mat.albedo_color = Color(1, 1, 1).lerp(tint, 0.15)
		drop_mat.albedo_color.a = 0.9

	preprocess = lifetime  # le ciel est déjà plein de gouttes/flocons à l'arrivée
	process_material = process
	quad.material = drop_mat
	draw_pass_1 = quad

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		global_position = player.global_position + Vector3(0, HEIGHT_ABOVE_PLAYER, 0)

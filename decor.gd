extends RefCounted
## Décor procédural d'un monde : rochers et cristaux, placés à partir de la graine.
## Affichage : un MultiMeshInstance3D par type (2 appels de dessin quel que soit le nombre).
## Collision : un seul StaticBody3D avec des cylindres (pas de mise à l'échelle, Jolt n'aime pas).
## Usage : preload("res://decor.gd").scatter(world, data, terrain)

const CLEAR_RADIUS = 7.0                 ## aucun objet à moins de 7 m du chemin départ -> portail
const CLEAR_FROM = Vector2(0, 0)         ## point d'apparition au lancement
const CLEAR_TO = Vector2(0, -10)         ## portail
const MIN_COLLIDING_HEIGHT = 0.35        ## rochers plus bas : on marche par-dessus (pas de collision)

static func scatter(world: Node3D, data: WorldData, terrain: Node3D):
	var rng = RandomNumberGenerator.new()
	rng.seed = data.world_seed * 7919 + 1   # suite aléatoire propre au décor
	var half: float = terrain.get_playable_half_size() - 2.0
	var body = StaticBody3D.new()
	body.name = "DecorBody"
	world.add_child(body)
	_scatter_rocks(world, body, data, terrain, rng, half)
	_scatter_crystals(world, body, data, terrain, rng, half)

# --- Rochers : sphères basse définition aplaties, à moitié enterrées ---
static func _scatter_rocks(world, body, data, terrain, rng, half):
	var mesh = SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 4
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true   # couleur par instance
	mat.roughness = 1.0
	mesh.material = mat

	var transforms = []
	var colors = []
	var tries = 0
	while transforms.size() < data.rock_count and tries < data.rock_count * 10:
		tries += 1
		var pos = Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		if _too_close_to_path(pos):
			continue
		var s = rng.randf_range(0.4, 1.8)
		var scale = Vector3(s * rng.randf_range(0.8, 1.4), s * rng.randf_range(0.5, 0.9), s * rng.randf_range(0.8, 1.4))
		var ground = terrain.get_global_height(pos.x, pos.y)
		var center = Vector3(pos.x, ground + scale.y * 0.6, pos.y)   # 40 % enterré
		var basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(scale)
		transforms.append(Transform3D(basis, center))
		colors.append(data.rock_color.darkened(rng.randf_range(0.0, 0.25)))
		# Collision : cylindre de la taille du rocher (seulement s'il dépasse assez du sol)
		if scale.y * 1.6 > MIN_COLLIDING_HEIGHT:
			var shape = CylinderShape3D.new()
			shape.radius = min(scale.x, scale.z) * 0.85
			shape.height = scale.y * 2.0
			_add_collision(body, shape, Transform3D(Basis(), center))

	_add_multimesh(world, "Rocks", mesh, transforms, colors)

# --- Cristaux : prismes hexagonaux pointus et lumineux, en grappes ---
static func _scatter_crystals(world, body, data, terrain, rng, half):
	var height = 1.6
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.22
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.3
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = data.crystal_color
	mat.emission_energy_multiplier = 0.9   # brillent la nuit
	mesh.material = mat

	var transforms = []
	var colors = []
	var tries = 0
	while transforms.size() < data.crystal_count and tries < 200:
		tries += 1
		var center2d = Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		if _too_close_to_path(center2d):
			continue
		var cluster_size = rng.randi_range(3, 6)
		for i in cluster_size:
			if transforms.size() >= data.crystal_count:
				break
			var pos = center2d + Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2))
			var s = rng.randf_range(0.6, 2.2)
			# Inclinaison aléatoire jusqu'à 25° autour d'un axe horizontal
			var tilt_axis = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
			var rot = Basis(tilt_axis, deg_to_rad(rng.randf_range(0.0, 25.0))) * Basis(Vector3.UP, rng.randf() * TAU)
			var base = Vector3(pos.x, terrain.get_global_height(pos.x, pos.y) - 0.1, pos.y)
			var center = base + rot.y * (height * s * 0.5)   # le mesh est centré : on le remonte
			transforms.append(Transform3D(rot.scaled(Vector3(s, s, s)), center))
			colors.append(data.crystal_color.lightened(rng.randf_range(0.0, 0.3)))
			if s > 0.9:
				var shape = CylinderShape3D.new()
				shape.radius = 0.2 * s
				shape.height = height * s * 0.9
				_add_collision(body, shape, Transform3D(rot, center))

	_add_multimesh(world, "Crystals", mesh, transforms, colors)

static func _too_close_to_path(p: Vector2) -> bool:
	# Distance du point au segment départ -> portail
	var seg = CLEAR_TO - CLEAR_FROM
	var t = clamp((p - CLEAR_FROM).dot(seg) / seg.length_squared(), 0.0, 1.0)
	return p.distance_to(CLEAR_FROM + seg * t) < CLEAR_RADIUS

static func _add_collision(body: StaticBody3D, shape: Shape3D, xform: Transform3D):
	var col = CollisionShape3D.new()
	col.shape = shape
	col.transform = xform
	body.add_child(col)

static func _add_multimesh(world: Node3D, node_name: String, mesh: Mesh, transforms: Array, colors: Array):
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi = MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	world.add_child(mmi)

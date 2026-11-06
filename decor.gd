extends RefCounted
## Décor procédural d'un monde : rochers, cristaux de quartz et cristaux rares de la famille.
## Affichage : un MultiMeshInstance3D par type (1 appel de dessin quel que soit le nombre).
## Collision : un seul StaticBody3D « DecorBody » avec des cylindres (jamais mis à l'échelle).
## Chaque forme de collision porte des métadonnées pour la récolte :
##   "decor_node" (nom du MultiMesh), "decor_index" (numéro d'instance), "item" (objet donné).
## Usage : preload("res://decor.gd").scatter(world, data, terrain)

const Families = preload("res://families.gd")

const CLEAR_RADIUS = 7.0                 ## aucun objet à moins de 7 m du chemin départ -> portail
const CLEAR_FROM = Vector2(0, 0)         ## point d'apparition au lancement
const CLEAR_TO = Vector2(0, -10)         ## portail
const MIN_COLLIDING_HEIGHT = 0.35        ## rochers plus bas : on marche par-dessus (pas de collision)
const CRYSTAL_HEIGHT = 1.6

static func scatter(world: Node3D, data: WorldData, terrain: Node3D):
	var rng = RandomNumberGenerator.new()
	rng.seed = data.world_seed * 7919 + 1   # suite aléatoire propre au décor
	var half: float = terrain.get_playable_half_size() - 2.0
	var body = StaticBody3D.new()
	body.name = "DecorBody"
	world.add_child(body)
	_scatter_rocks(world, body, data, terrain, rng, half)
	# Quartz : commun, pâle, présent partout
	_scatter_crystals(world, body, terrain, rng, half, "Quartz", data.crystal_count,
		data.crystal_color, &"quartz", 0.6, 1.0)
	# Cristaux rares : couleur de la famille, plus gros et plus lumineux
	if data.rare_crystal_count > 0:
		var rare_rng = RandomNumberGenerator.new()
		rare_rng.seed = data.world_seed * 104729 + 7   # n'influence pas le placement du reste
		_scatter_crystals(world, body, terrain, rare_rng, half, "RareCrystals", data.rare_crystal_count,
			Families.CRYSTAL_COLORS[data.family], Families.crystal_item_id(data.family), 1.25, 1.3)

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
		var rock_scale = Vector3(s * rng.randf_range(0.8, 1.4), s * rng.randf_range(0.5, 0.9), s * rng.randf_range(0.8, 1.4))
		var ground = terrain.get_global_height(pos.x, pos.y)
		var center = Vector3(pos.x, ground + rock_scale.y * 0.6, pos.y)   # 40 % enterré
		var rock_basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(rock_scale)
		transforms.append(Transform3D(rock_basis, center))
		colors.append(data.rock_color.darkened(rng.randf_range(0.0, 0.25)))
		# Collision : cylindre de la taille du rocher (seulement s'il dépasse assez du sol)
		if rock_scale.y * 1.6 > MIN_COLLIDING_HEIGHT:
			var shape = CylinderShape3D.new()
			shape.radius = min(rock_scale.x, rock_scale.z) * 0.85
			shape.height = rock_scale.y * 2.0
			_add_collision(body, shape, Transform3D(Basis(), center), "Rocks", transforms.size() - 1, &"pierre")

	_add_multimesh(world, "Rocks", mesh, transforms, colors)

# --- Cristaux : prismes hexagonaux pointus et lumineux, en grappes ---
static func _scatter_crystals(world, body, terrain, rng, half, node_name: String, count: int,
		color: Color, item_id: StringName, size_mult: float, glow: float):
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.22
	mesh.height = CRYSTAL_HEIGHT
	mesh.radial_segments = 6
	mesh.rings = 1
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.3
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.9 * glow   # brillent la nuit
	mesh.material = mat

	var transforms = []
	var colors = []
	var tries = 0
	while transforms.size() < count and tries < 200:
		tries += 1
		var center2d = Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		if _too_close_to_path(center2d):
			continue
		var cluster_size = rng.randi_range(3, 6)
		for i in cluster_size:
			if transforms.size() >= count:
				break
			var pos = center2d + Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2))
			var s = rng.randf_range(0.6, 2.2) * size_mult
			# Inclinaison aléatoire jusqu'à 25° autour d'un axe horizontal
			var tilt_axis = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
			var rot = Basis(tilt_axis, deg_to_rad(rng.randf_range(0.0, 25.0))) * Basis(Vector3.UP, rng.randf() * TAU)
			var base = Vector3(pos.x, terrain.get_global_height(pos.x, pos.y) - 0.1, pos.y)
			var center = base + rot.y * (CRYSTAL_HEIGHT * s * 0.5)   # le mesh est centré : on le remonte
			transforms.append(Transform3D(rot.scaled(Vector3(s, s, s)), center))
			colors.append(color.lightened(rng.randf_range(0.0, 0.3)))
			# Tous les cristaux ont une collision (même petits) : ils doivent pouvoir être récoltés
			var shape = CylinderShape3D.new()
			shape.radius = max(0.2 * s, 0.25)
			shape.height = CRYSTAL_HEIGHT * s * 0.9
			_add_collision(body, shape, Transform3D(rot, center), node_name, transforms.size() - 1, item_id)

	_add_multimesh(world, node_name, mesh, transforms, colors)

static func _too_close_to_path(p: Vector2) -> bool:
	# Distance du point au segment départ -> portail
	var seg = CLEAR_TO - CLEAR_FROM
	var t = clamp((p - CLEAR_FROM).dot(seg) / seg.length_squared(), 0.0, 1.0)
	return p.distance_to(CLEAR_FROM + seg * t) < CLEAR_RADIUS

static func _add_collision(body: StaticBody3D, shape: Shape3D, xform: Transform3D,
		node_name: String, index: int, item_id: StringName):
	var col = CollisionShape3D.new()
	col.shape = shape
	col.transform = xform
	col.set_meta("decor_node", node_name)
	col.set_meta("decor_index", index)
	col.set_meta("item", item_id)
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

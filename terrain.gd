@tool
extends MeshInstance3D
## Terrain procédural : une même graine donne toujours le même monde.
## @tool : changer un paramètre dans l'inspecteur régénère le terrain dans l'éditeur.

@export var world_seed: int = 0:
	set(v): world_seed = v; _regenerate()
@export var size: float = 160.0:              ## côté du terrain en mètres
	set(v): size = v; _regenerate()
@export var resolution: int = 80:             ## nombre de cases par côté (80 -> une case de 2 m)
	set(v): resolution = max(v, 2); _regenerate()
@export var amplitude: float = 6.0:           ## hauteur max des collines (m), de -amplitude à +amplitude
	set(v): amplitude = v; _regenerate()
@export var frequency: float = 0.02:          ## petite valeur = collines larges
	set(v): frequency = v; _regenerate()
@export var octaves: int = 3:                 ## couches de détail (1 = très lisse)
	set(v): octaves = clamp(v, 1, 8); _regenerate()
@export var color_low: Color = Color(0.10, 0.12, 0.30):   ## couleur des creux
	set(v): color_low = v; _regenerate()
@export var color_high: Color = Color(0.45, 0.25, 0.65):  ## couleur des sommets
	set(v): color_high = v; _regenerate()
@export var rim_width: float = 18.0:          ## largeur de la ceinture de crêtes au bord (m)
	set(v): rim_width = v; _regenerate()
@export var rim_height: float = 14.0:         ## hauteur ajoutée tout au bord (m)
	set(v): rim_height = v; _regenerate()

var noise := FastNoiseLite.new()

func _ready():
	add_to_group("terrain")  # pour que game.gd et les portails trouvent le sol
	generate_terrain()
	if not Engine.is_editor_hint():
		_create_bounds()

func _regenerate():
	if is_node_ready():
		generate_terrain()

func _setup_noise():
	noise.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves

## Hauteur du sol en (x, z), coordonnées locales au terrain.
## Sert aussi à poser le joueur, les portails et le décor sur le sol.
func get_height(x: float, z: float) -> float:
	return noise.get_noise_2d(x, z) * amplitude + _rim(x, z)

## Les bords remontent en crêtes : le monde est une vallée, pas un plateau au-dessus du vide.
func _rim(x: float, z: float) -> float:
	var edge_distance = max(abs(x), abs(z))
	var half = size / 2.0
	return smoothstep(half - rim_width, half, edge_distance) * rim_height

## Taille de la zone praticable (sans la ceinture de crêtes), pour placer le décor.
func get_playable_half_size() -> float:
	return size / 2.0 - rim_width

## Murs invisibles tout au bord, au cas où le joueur escaladerait les crêtes.
## Créés seulement en jeu (pas dans l'éditeur) et jamais sauvegardés dans la scène.
func _create_bounds():
	var bounds = StaticBody3D.new()
	bounds.name = "Bounds"
	add_child(bounds)
	var half = size / 2.0
	var wall_height = 200.0
	for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var box = BoxShape3D.new()
		box.size = Vector3(1.0 if side.x != 0 else size + 2.0, wall_height, 1.0 if side.z != 0 else size + 2.0)
		var col = CollisionShape3D.new()
		col.shape = box
		col.position = side * (half + 0.5)
		bounds.add_child(col)

## Hauteur du sol (y global) sous le point global (x, z).
func get_global_height(x: float, z: float) -> float:
	var local = to_local(Vector3(x, 0, z))
	return to_global(Vector3(local.x, get_height(local.x, local.z), local.z)).y

func generate_terrain():
	_setup_noise()
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step = size / resolution
	var half = size / 2.0
	for zi in range(resolution):
		for xi in range(resolution):
			var x1 = xi * step - half
			var z1 = zi * step - half
			var x2 = x1 + step
			var z2 = z1 + step
			var p1 = Vector3(x1, get_height(x1, z1), z1)
			var p2 = Vector3(x2, get_height(x2, z1), z1)
			var p3 = Vector3(x1, get_height(x1, z2), z2)
			var p4 = Vector3(x2, get_height(x2, z2), z2)
			for p in [p1, p2, p3, p2, p4, p3]:
				surface.set_color(_height_color(p.y))
				surface.add_vertex(p)

	surface.generate_normals()
	mesh = surface.commit()

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true  # sinon les couleurs sont lues comme linéaires et sortent délavées
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)

	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	$StaticBody3D/CollisionShape3D.shape = shape

func _height_color(y: float) -> Color:
	var t = 0.5
	if amplitude > 0.0:
		t = clamp((y / amplitude + 1.0) / 2.0, 0.0, 1.0)
	# Dégradé en teinte (HSV) et non en RGB : entre deux couleurs opposées,
	# un mélange RGB passe par le gris, un mélange de teinte reste vif.
	var h = fposmod(lerp_angle(color_low.h * TAU, color_high.h * TAU, t) / TAU, 1.0)
	return Color.from_hsv(h, lerp(color_low.s, color_high.s, t), lerp(color_low.v, color_high.v, t))

# Le terrain est régénéré à chaque chargement : on évite de sauvegarder
# le mesh et la collision (des centaines de Ko) dans world.tscn.
func _notification(what):
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		mesh = null
		$StaticBody3D/CollisionShape3D.shape = null
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		generate_terrain()

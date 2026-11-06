extends RefCounted
## Objets posables (établi, coffre…) : modèle Kenney + boîte de collision ajustée au modèle.
## Usage : var node = preload("res://placeables.gd").create(item_data)
## Le nœud créé est dans le groupe "placed" et porte la méta "item" (id de l'objet).
## L'établi est aussi dans le groupe "workbench" (recettes avancées à proximité).

const WORKBENCH_RADIUS = 3.5   ## distance max pour utiliser un établi (m)

static func create(item: ItemData) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = String(item.id).capitalize()
	body.set_meta("item", item.id)
	body.add_to_group("placed")
	if item.id == &"etabli":
		body.add_to_group("workbench")
	var model: Node3D = item.model.instantiate()
	model.scale = Vector3.ONE * item.model_scale
	body.add_child(model)
	# Boîte de collision à la taille du modèle (calculée sur ses maillages)
	var box = _model_aabb(model)
	var shape = BoxShape3D.new()
	shape.size = box.size
	var col = CollisionShape3D.new()
	col.shape = shape
	col.position = box.get_center()
	body.add_child(col)
	return body

static func _model_aabb(model: Node3D) -> AABB:
	var result = AABB()
	var first = true
	for mesh_instance in model.find_children("*", "MeshInstance3D", true, false):
		# Transformation du maillage relative au corps (modèle mis à l'échelle compris)
		var xform = Transform3D(Basis().scaled(model.scale), Vector3.ZERO)
		var n: Node = mesh_instance
		var chain = Transform3D()
		while n != model:
			chain = n.transform * chain
			n = n.get_parent()
		var box = (xform * chain) * mesh_instance.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

## Y a-t-il un établi à portée de cette position ?
static func near_workbench(tree: SceneTree, position: Vector3) -> bool:
	for bench in tree.get_nodes_in_group("workbench"):
		if bench.is_inside_tree() and bench.global_position.distance_to(position) <= WORKBENCH_RADIUS:
			return true
	return false

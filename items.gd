extends RefCounted
## Registre des objets : charge tous les ItemData de res://items/ une seule fois.
## Usage : const Items = preload("res://items.gd") ; Items.get_item(&"pierre")

const ITEMS_DIR = "res://items/"

static var _items: Dictionary = {}   ## id -> ItemData

static func _load_all():
	if not _items.is_empty():
		return
	var dir = DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_error("Dossier d'objets introuvable : " + ITEMS_DIR)
		return
	for file in dir.get_files():
		# Dans un jeu exporté, les .tres deviennent .tres.remap
		var path = ITEMS_DIR + file.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var item = load(path)
		if item is ItemData:
			if _items.has(item.id):
				push_error("Identifiant d'objet en double : %s" % item.id)
			_items[item.id] = item

static func get_item(id: StringName) -> ItemData:
	_load_all()
	return _items.get(id)

static func all() -> Array:
	_load_all()
	return _items.values()

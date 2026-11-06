extends RefCounted
## Registre des recettes : charge tous les RecipeData de res://recipes/ une seule fois.
## Usage : const Recipes = preload("res://recipes.gd") ; Recipes.all()

const RECIPES_DIR = "res://recipes/"

static var _recipes: Array = []

static func all() -> Array:
	if _recipes.is_empty():
		var dir = DirAccess.open(RECIPES_DIR)
		if dir == null:
			push_error("Dossier de recettes introuvable : " + RECIPES_DIR)
			return []
		for file in dir.get_files():
			var path = RECIPES_DIR + file.trim_suffix(".remap")   # .remap dans un jeu exporté
			if path.ends_with(".tres"):
				var r = load(path)
				if r is RecipeData:
					_recipes.append(r)
		_recipes.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	return _recipes

## Recettes connues : tous les ingrédients ont déjà été trouvés au moins une fois.
static func known(discovered: Dictionary) -> Array:
	return all().filter(func(r): return r.ingredients.keys().all(func(id): return discovered.has(id)))

## Peut-on fabriquer cette recette maintenant ?
static func can_craft(r: RecipeData, inventory: Inventory, near_workbench: bool) -> bool:
	if r.requires_workbench and not near_workbench:
		return false
	for id in r.ingredients:
		if inventory.count_of(id) < r.ingredients[id]:
			return false
	return true

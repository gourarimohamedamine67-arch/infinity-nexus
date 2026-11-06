class_name RecipeData
extends Resource
## Une recette de fabrication. Un fichier .tres par recette dans res://recipes/.
## La recette est connue dès que le joueur a trouvé au moins une fois chacun de ses ingrédients.

@export var result: StringName              ## objet fabriqué (id d'un ItemData)
@export_range(1, 99) var result_count: int = 1
@export var ingredients: Dictionary = {}    ## id d'objet -> quantité, ex. {&"pierre": 6}
@export var requires_workbench := false     ## objets avancés : seulement près d'un établi
@export var sort_order := 0                 ## ordre d'affichage dans la liste

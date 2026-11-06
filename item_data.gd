class_name ItemData
extends Resource
## Description d'un objet (ressource, outil, construction, clé…).
## Un fichier .tres par objet dans res://items/ : on ajoute un objet sans toucher au code.

enum Kind { RESOURCE, TOOL, PLACEABLE, KEY }

@export var id: StringName                 ## identifiant unique, ex. &"pierre"
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: Kind = Kind.RESOURCE
@export var icon_color: Color = Color.WHITE ## couleur de l'icône (en attendant de vraies icônes)
@export var icon: Texture2D                 ## icône optionnelle (sinon carré coloré)
@export_range(1, 999) var max_stack: int = 99
@export var family: int = -1                ## famille de monde (-1 = ressource de base)
@export_range(0, 3) var rarity: int = 0     ## 0 commun, 1 peu commun, 2 rare, 3 exceptionnel

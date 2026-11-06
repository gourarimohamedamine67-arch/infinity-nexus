extends RefCounted
## Les 6 familles de mondes. La famille vient de la teinte du ciel (et inversement :
## une clé de portail qui vise une famille fait tirer une teinte dans sa plage).
## Usage : const Families = preload("res://families.gd")

enum Family { BRAISE, SYLVE, GIVRE, ABYSSE, ARCANE, OMBRE }

const NAMES = ["Braise", "Sylve", "Givre", "Abysse", "Arcane", "Ombre"]

## Plages de teinte [début, fin[ sur le cercle 0-1. Braise fait le tour par le rouge (0,93 -> 0,17).
const HUE_RANGES = [
	[0.93, 1.17],   # Braise : rouges, orangés, jaunes
	[0.17, 0.45],   # Sylve : verts
	[0.45, 0.55],   # Givre : cyans
	[0.55, 0.70],   # Abysse : bleus
	[0.70, 0.84],   # Arcane : violets
	[0.84, 0.93],   # Ombre : magentas
]

## Couleur des cristaux rares de chaque famille (vive, reconnaissable)
const CRYSTAL_COLORS = [
	Color(1.0, 0.45, 0.15),   # Braise : orange feu
	Color(0.35, 1.0, 0.35),   # Sylve : vert
	Color(0.55, 0.95, 1.0),   # Givre : cyan glacé
	Color(0.2, 0.4, 1.0),     # Abysse : bleu profond
	Color(0.7, 0.35, 1.0),    # Arcane : violet
	Color(1.0, 0.25, 0.75),   # Ombre : magenta
]

## Famille correspondant à une teinte (0-1).
static func from_hue(hue: float) -> int:
	var h = fposmod(hue, 1.0)
	for f in HUE_RANGES.size():
		var start: float = HUE_RANGES[f][0]
		var end: float = HUE_RANGES[f][1]
		if (h >= start and h < end) or (end > 1.0 and h + 1.0 >= start and h + 1.0 < end):
			return f
	return Family.BRAISE

## Teinte au hasard dans la plage d'une famille.
static func random_hue(family: int, rng: RandomNumberGenerator) -> float:
	var r = HUE_RANGES[family]
	return fposmod(rng.randf_range(r[0] + 0.01, r[1] - 0.01), 1.0)

static func name_of(family: int) -> String:
	return NAMES[family] if family >= 0 and family < NAMES.size() else "Neutre"

## Identifiant de l'objet « cristal rare » d'une famille (ex. &"cristal_braise").
static func crystal_item_id(family: int) -> StringName:
	return StringName("cristal_" + NAMES[family].to_lower())

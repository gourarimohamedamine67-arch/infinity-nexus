class_name WorldData
extends Resource
## Tout ce qui définit un monde. Le monde d'origine est un fichier (worlds/origin.tres),
## les autres sont générés à partir de leur graine avec WorldData.generate(seed).
## Servira aussi pour les sauvegardes (phase 4).

@export var world_seed: int = 0
@export var display_name: String = ""

@export_group("Terrain")
@export var amplitude: float = 6.0
@export var frequency: float = 0.02
@export_range(1, 8) var octaves: int = 3
@export var color_low: Color = Color(0.10, 0.12, 0.30)
@export var color_high: Color = Color(0.45, 0.25, 0.65)

@export_group("Ciel")
@export var sky_top: Color = Color(0.04, 0.04, 0.10)
@export var sky_horizon: Color = Color(0.10, 0.04, 0.18)
@export var ground_bottom: Color = Color(0, 0, 0)

@export_group("Brouillard")
@export var fog_color: Color = Color(0.10, 0.04, 0.18)
@export_range(0.0, 0.1) var fog_density: float = 0.0   ## 0 = pas de brouillard

@export_group("Soleil")
@export var sun_color: Color = Color(1, 1, 1)
@export_range(0.0, 4.0) var sun_energy: float = 1.0
@export_range(-90.0, 0.0) var sun_pitch_deg: float = -50.0  ## -90 = soleil au zénith
@export_range(-180.0, 180.0) var sun_yaw_deg: float = 30.0

@export_group("Jour et nuit")
@export var day_length_s: float = 480.0         ## durée d'un cycle complet (s) ; 0 = soleil fixe
@export_range(0.0, 1.0) var start_time: float = 0.3  ## 0-0,5 = jour (0,25 = midi), 0,5-1 = nuit
@export_range(0.0, 0.05) var star_density: float = 0.012

const GOLDEN_RATIO = 0.618034
## Décalage de teinte des sommets par rapport au ciel : [nom, décalage]
const SCHEMES = [
	["Analogue", 0.07],
	["Décalé", -0.14],
	["Triadique", 0.333],
	["Complémentaire", 0.5],
]

## Crée un monde procédural : une même graine donne toujours le même monde.
static func generate(seed_value: int) -> WorldData:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	# Nombre d'or : les teintes de graines consécutives sont bien espacées sur le cercle
	var hue = fposmod(seed_value * GOLDEN_RATIO + 0.13, 1.0)
	var scheme = SCHEMES[rng.randi() % SCHEMES.size()]
	var crest_hue = fposmod(hue + scheme[1], 1.0)
	var brightness = rng.randf()   # 0 = monde nocturne, 1 = monde lumineux

	var d = WorldData.new()
	d.world_seed = seed_value
	d.display_name = "Monde %d (%s)" % [seed_value, scheme[0]]

	d.amplitude = rng.randf_range(3.0, 10.0)
	d.frequency = rng.randf_range(0.012, 0.035)
	d.octaves = rng.randi_range(2, 5)
	# Sol : creux sombres et saturés dans la teinte du ciel, sommets vifs selon le schéma
	d.color_low = Color.from_hsv(hue, rng.randf_range(0.75, 0.95), lerp(0.12, 0.30, brightness))
	d.color_high = Color.from_hsv(crest_hue, rng.randf_range(0.65, 0.9), lerp(0.45, 0.80, brightness))

	# Ciel : haut sombre, horizon vif ; le brouillard reprend l'horizon pour fondre le sol au loin
	d.sky_top = Color.from_hsv(hue, 0.85, lerp(0.06, 0.30, brightness))
	d.sky_horizon = Color.from_hsv(fposmod(hue + 0.04, 1.0), 0.8, lerp(0.30, 0.70, brightness))
	d.ground_bottom = d.color_low.darkened(0.6)
	d.fog_color = d.sky_horizon
	d.fog_density = rng.randf_range(0.008, 0.022)

	# Soleil teinté comme le ciel (une teinte opposée grisait tout le monde)
	d.sun_color = Color.from_hsv(hue, 0.3, 1.0)
	d.sun_energy = lerp(0.6, 1.3, brightness)
	d.sun_pitch_deg = rng.randf_range(-65.0, -30.0)
	d.sun_yaw_deg = rng.randf_range(-180.0, 180.0)

	# Cycle lent (6 à 10 min) ; 70 % des mondes commencent de jour
	d.day_length_s = rng.randf_range(360.0, 600.0)
	if rng.randf() < 0.7:
		d.start_time = rng.randf_range(0.08, 0.42)
	else:
		d.start_time = rng.randf_range(0.58, 0.92)
	d.star_density = rng.randf_range(0.006, 0.02)
	return d

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

@export_group("Soleil")
@export var sun_color: Color = Color(1, 1, 1)
@export_range(0.0, 4.0) var sun_energy: float = 1.0
@export_range(-90.0, 0.0) var sun_pitch_deg: float = -50.0  ## -90 = soleil au zénith
@export_range(-180.0, 180.0) var sun_yaw_deg: float = 30.0

## Crée un monde procédural : une même graine donne toujours le même monde.
static func generate(seed_value: int) -> WorldData:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var hue = rng.randf()
	var d = WorldData.new()
	d.world_seed = seed_value
	d.display_name = "Monde %d" % seed_value
	d.amplitude = rng.randf_range(3.0, 10.0)
	d.frequency = rng.randf_range(0.012, 0.035)
	d.octaves = rng.randi_range(2, 5)
	d.color_low = Color.from_hsv(hue, 0.6, 0.25)
	d.color_high = Color.from_hsv(fmod(hue + 0.1, 1.0), 0.45, 0.65)
	d.sky_top = Color.from_hsv(hue, 0.7, 0.12)
	d.sky_horizon = Color.from_hsv(fmod(hue + 0.08, 1.0), 0.7, 0.22)
	d.sun_color = Color.from_hsv(fmod(hue + 0.5, 1.0), 0.25, 1.0)
	d.sun_energy = rng.randf_range(0.7, 1.3)
	d.sun_pitch_deg = rng.randf_range(-65.0, -35.0)
	d.sun_yaw_deg = rng.randf_range(-180.0, 180.0)
	return d

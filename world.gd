extends Node3D
## Un monde : terrain + ciel + soleil/lune + portail, configuré par une WorldData.
## setup() doit être appelé AVANT add_child() pour que le terrain ne soit généré qu'une fois.

const SKY_SHADER = preload("res://sky.gdshader")
const Weather = preload("res://weather.gd")
const Decor = preload("res://decor.gd")
const SKY_UPDATE_INTERVAL = 0.25   ## s entre deux mises à jour du ciel (recalcul coûteux)
const Sounds = preload("res://sounds.gd")
const Families = preload("res://families.gd")

## Récolte : points de vie, puissance d'outil requise et quantité donnée, par objet récolté.
## (« pierre » = rochers, « quartz » = cristaux pâles, le reste = cristaux rares de famille)
const HARVEST = {
	&"pierre": {"hp": 6, "power": 0, "drop": [2, 4]},
	&"quartz": {"hp": 6, "power": 1, "drop": [1, 3]},
	"rare":    {"hp": 9, "power": 1, "drop": [1, 2]},
}

@onready var portal = $Portal
@onready var sun: DirectionalLight3D = $DirectionalLight3D

var data: WorldData
var env: Environment
var sky_mat: ShaderMaterial
var moon: DirectionalLight3D
var time_of_day := 0.0       ## 0-0,5 = jour, 0,5-1 = nuit
var night_top: Color
var night_horizon: Color
var sky_timer := 0.0
var weather_light := 1.0     ## la pluie/neige/brume voile le soleil

## world_data : description du monde. return_seed : graine du monde d'où l'on vient (-1 = aucun).
func setup(world_data: WorldData, return_seed: int = -1):
	data = world_data
	var terrain = $Terrain
	terrain.world_seed = data.world_seed
	terrain.amplitude = data.amplitude
	terrain.frequency = data.frequency
	terrain.octaves = data.octaves
	terrain.color_low = data.color_low
	terrain.color_high = data.color_high

	_setup_sky()

	# Le portail ramène d'où l'on vient ; sinon il ouvre vers un nouveau monde.
	$Portal.destination_seed = return_seed if return_seed >= 0 else data.world_seed + 1

func _ready():
	add_to_group("world")   # le joueur trouve le monde actuel (récolte) par ce groupe
	# Lune : lumière bleutée opposée au soleil, active la nuit
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color(0.6, 0.7, 1.0)
	moon.shadow_enabled = false
	moon.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY  # le ciel dessine sa propre lune (shader)
	add_child(moon)
	if data:
		Decor.scatter(self, data, $Terrain)   # rochers et cristaux
	if data and data.weather in [Weather.Kind.RAIN, Weather.Kind.SNOW]:
		var weather = Weather.new()
		weather.setup(data.weather, data.sky_horizon)
		add_child(weather)
	# Ombres du soleil limitées à 80 m : quand il est bas, les ombres s'allongent et coûtent cher
	sun.directional_shadow_max_distance = 80.0
	time_of_day = data.start_time if data else 0.3
	_update_day_night(true)

func _process(delta):
	if data == null or data.day_length_s <= 0.0:
		return
	time_of_day = fposmod(time_of_day + delta / data.day_length_s, 1.0)
	sky_timer += delta
	var refresh_sky = sky_timer >= SKY_UPDATE_INTERVAL
	if refresh_sky:
		sky_timer = 0.0
	_update_day_night(refresh_sky)

# --- Ciel ---

func _setup_sky():
	# L'Environment est partagé entre toutes les instances de world.tscn : on le copie
	env = $WorldEnvironment.environment.duplicate(true)
	$WorldEnvironment.environment = env
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = SKY_SHADER
	env.sky.sky_material = sky_mat
	env.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL  # recalcul de l'éclairage étalé sur plusieurs images
	env.sky.radiance_size = Sky.RADIANCE_SIZE_128

	# Couleurs de nuit déduites du jour : même teinte, très sombre
	night_top = Color.from_hsv(data.sky_top.h, data.sky_top.s * 0.8, 0.025)
	night_horizon = Color.from_hsv(data.sky_horizon.h, data.sky_horizon.s * 0.7, data.sky_horizon.v * 0.22)
	sky_mat.set_shader_parameter("day_top", data.sky_top)
	sky_mat.set_shader_parameter("day_horizon", data.sky_horizon)
	sky_mat.set_shader_parameter("night_top", night_top)
	sky_mat.set_shader_parameter("night_horizon", night_horizon)
	sky_mat.set_shader_parameter("ground_bottom", data.ground_bottom)
	sky_mat.set_shader_parameter("star_density", data.star_density)
	sky_mat.set_shader_parameter("star_seed", float(data.world_seed % 1000) * 0.137)

	var fog_density = data.fog_density
	match data.weather:
		Weather.Kind.RAIN, Weather.Kind.SNOW:
			weather_light = 0.65
			fog_density *= 1.5
		Weather.Kind.MIST:
			weather_light = 0.8
			fog_density = max(fog_density * 3.5, 0.045)   # brume épaisse
	env.fog_enabled = fog_density > 0.0
	env.fog_density = fog_density
	env.fog_sky_affect = 0.3
	# Lumière ambiante : vient du ciel le jour, garde une teinte de nuit pour ne jamais être noire
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = night_horizon.lightened(0.15)

# --- Cycle jour/nuit ---

## Place soleil et lune selon l'heure, et (si refresh_sky) met à jour ciel et brouillard.
func _update_day_night(refresh_sky: bool):
	if data == null:
		return
	var angle = time_of_day * TAU            # 0 = lever, PI/2 = midi, PI = coucher
	var elevation = sin(angle)               # > 0 : soleil au-dessus de l'horizon
	var yaw = deg_to_rad(data.sun_yaw_deg)

	if data.day_length_s <= 0.0:
		# Soleil fixe (comportement d'avant le cycle)
		sun.rotation_degrees = Vector3(data.sun_pitch_deg, data.sun_yaw_deg, 0)
		elevation = 1.0
	else:
		sun.rotation = Vector3(-angle, yaw, 0)
	moon.rotation = Vector3(-angle - PI, yaw, 0)

	var day = smoothstep(-0.05, 0.15, elevation)
	var night = 1.0 - smoothstep(-0.15, 0.1, elevation)
	# Soleil plus chaud (orangé) près de l'horizon
	sun.light_color = data.sun_color.lerp(Color(1.0, 0.55, 0.3), clamp(1.0 - elevation * 3.0, 0.0, 1.0) * day)
	sun.light_energy = data.sun_energy * day * weather_light
	sun.visible = day > 0.0
	moon.light_energy = 0.35 * night
	moon.visible = night > 0.0

	if refresh_sky:
		sky_mat.set_shader_parameter("night", night)
		sky_mat.set_shader_parameter("moon_dir", moon.global_basis.z)  # la lumière va vers -Z : la lune est en +Z
		env.fog_light_color = data.fog_color.lerp(night_horizon, night)
		env.ambient_light_sky_contribution = 1.0 - 0.5 * night

# --- Récolte ---

## Frappe un objet du décor (forme de collision marquée par decor.gd).
## damage : dégâts du coup ; tool_power : puissance de l'outil tenu (0 = main nue).
## Renvoie {"refused": bool, "broken": bool, "item": StringName, "count": int}.
func hit_decor(col: CollisionShape3D, damage: int, tool_power: int) -> Dictionary:
	var item: StringName = col.get_meta("item")
	var rules = HARVEST.get(item, HARVEST["rare"])
	var is_rock = item == &"pierre"
	var pos = col.global_position
	if tool_power < rules.power:
		Sounds.play_at(self, pos, "impactSoft_medium", -6.0)   # « toc » sourd : rien ne se passe
		return {"refused": true, "broken": false, "item": item, "count": 0}

	var hp: int = col.get_meta("hp", rules.hp) - damage
	var mmi: MultiMeshInstance3D = get_node(String(col.get_meta("decor_node")))
	var index: int = col.get_meta("decor_index")
	var xform = mmi.multimesh.get_instance_transform(index)
	if hp > 0:
		col.set_meta("hp", hp)
		# Retour visuel : l'objet rétrécit un peu à chaque coup
		mmi.multimesh.set_instance_transform(index, Transform3D(xform.basis.scaled(Vector3.ONE * 0.9), xform.origin))
		Sounds.play_at(self, pos, "impactMining" if is_rock else "impactGlass_light")
		_burst(pos, _decor_color(item), 6)
		return {"refused": false, "broken": false, "item": item, "count": 0}

	# Cassé : l'instance disparaît (échelle 0), la collision est retirée, on récupère la ressource
	mmi.multimesh.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ZERO), xform.origin))
	col.queue_free()
	Sounds.play_at(self, pos, "impactMining" if is_rock else "impactGlass_medium", 3.0)
	_burst(pos, _decor_color(item), 18)
	var count = randi_range(rules.drop[0], rules.drop[1])
	return {"refused": false, "broken": true, "item": item, "count": count}

func _decor_color(item: StringName) -> Color:
	if item == &"pierre":
		return data.rock_color.lightened(0.2)
	if item == &"quartz":
		return data.crystal_color
	return Families.CRYSTAL_COLORS[data.family]

## Petits éclats qui jaillissent quand on frappe.
func _burst(pos: Vector3, color: Color, amount: int):
	var p = CPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.explosiveness = 1.0
	p.lifetime = 0.7
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -12, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var mesh = BoxMesh.new()
	mesh.size = Vector3.ONE * 0.08
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = color.s > 0.3   # éclats de cristaux colorés : légèrement lumineux
	mat.emission = color
	mesh.material = mat
	p.mesh = mesh
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)

## Point d'arrivée devant le portail. Renvoie [position xz, direction du regard].
## - par un portail : 6 m devant, dos au portail (on vient d'en sortir)
## - au lancement du jeu : 10 m devant, face au portail (pour le voir)
func get_arrival(by_portal: bool) -> Array:
	var front: Vector3 = portal.global_basis.z.normalized()  # le portail regarde vers +Z
	var distance = 6.0 if by_portal else 10.0   # 6 m : la caméra (4 m derrière le joueur) reste devant l'anneau
	var spot: Vector3 = portal.global_position + front * distance
	var look = front if by_portal else -front
	return [Vector2(spot.x, spot.z), look]

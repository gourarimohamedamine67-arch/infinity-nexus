extends RefCounted
## Sons Kenney (assets/kenney/sounds) joués dans l'espace 3D, avec une variante au hasard.
## Usage : const Sounds = preload("res://sounds.gd") ; Sounds.play_at(world, position, "impactMining")

const DIR = "res://assets/kenney/sounds/"
const VARIANTS = 5   # chaque son existe en 5 variantes : _000 à _004

static var _cache: Dictionary = {}

static func play_at(parent: Node, position: Vector3, sound: String, volume_db: float = 0.0):
	var variant = randi() % VARIANTS
	var path = "%s%s_%03d.ogg" % [DIR, sound, variant]
	if not _cache.has(path):
		_cache[path] = load(path)
	if _cache[path] == null:
		return
	var player = AudioStreamPlayer3D.new()
	player.stream = _cache[path]
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.92, 1.08)   # évite l'effet « son répété à l'identique »
	parent.add_child(player)
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()

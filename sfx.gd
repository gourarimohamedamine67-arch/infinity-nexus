extends RefCounted
## Sons générés par le code (aucun fichier audio externe).
## Usage : const Sfx = preload("res://sfx.gd") puis Sfx.portal_whoosh()

const MIX_RATE = 22050

## Son de traversée de portail (~1,2 s) : souffle qui monte + glissando + scintillement.
static func portal_whoosh() -> AudioStreamWAV:
	var duration = 1.2
	var count = int(duration * MIX_RATE)
	var rng = RandomNumberGenerator.new()
	rng.seed = 7  # toujours le même son
	var samples = PackedFloat32Array()
	samples.resize(count)

	var noise_filtered = 0.0
	var sweep_phase = 0.0
	var peak = 0.0
	for i in count:
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# Enveloppe générale : montée rapide (0,12 s) puis extinction douce
		var envelope = min(t / 0.12, 1.0) * pow(1.0 - progress, 1.6)

		# 1) Souffle : bruit blanc passé dans un filtre passe-bas qui s'ouvre
		var cutoff = lerp(0.02, 0.35, progress)
		noise_filtered += (rng.randf_range(-1.0, 1.0) - noise_filtered) * cutoff
		var whoosh = noise_filtered * 1.6

		# 2) Glissando : sinusoïde de 180 Hz à 900 Hz, avec un léger vibrato
		var freq = 180.0 * pow(5.0, progress) * (1.0 + 0.03 * sin(TAU * 6.0 * t))
		sweep_phase += TAU * freq / MIX_RATE
		var sweep = sin(sweep_phase) * 0.45

		# 3) Scintillement : deux notes aiguës qui tremblent, surtout en fin de son
		var shimmer = (sin(TAU * 1320.0 * t) + 0.6 * sin(TAU * 1980.0 * t)) \
			* (0.5 + 0.5 * sin(TAU * 11.0 * t)) * progress * 0.18

		var value = (whoosh + sweep + shimmer) * envelope
		samples[i] = value
		peak = max(peak, abs(value))

	# Normalisation à 80 % puis conversion en 16 bits
	var data = PackedByteArray()
	data.resize(count * 2)
	var gain = 0.8 / peak if peak > 0.0 else 1.0
	for i in count:
		data.encode_s16(i * 2, int(clamp(samples[i] * gain, -1.0, 1.0) * 32767.0))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream

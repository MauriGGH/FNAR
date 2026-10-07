extends AudioStreamPlayer

## El grito provisional del jumpscare, generado por código: un barrido de
## ruido que baja de tono, para no depender todavía de un archivo de audio.
## Cuando llegue el grito de verdad, se le pone el stream a este nodo y se
## borra la generación.

const SAMPLE_RATE: int = 22050
const DURATION: float = 0.55
## De qué tono a qué tono baja el barrido.
const FROM_HZ: float = 1400.0
const TO_HZ: float = 180.0
const AMPLITUDE: float = 0.3
## Cuánto ruido se le mezcla al tono, para que suene roto y no a sirena.
const NOISE: float = 0.55


func _ready() -> void:
	if stream == null:
		stream = _build_scream()


func _build_scream() -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	var samples: int = int(DURATION * SAMPLE_RATE)
	var phase: float = 0.0
	for i: int in samples:
		var t: float = float(i) / float(samples)
		var frequency: float = lerpf(FROM_HZ, TO_HZ, t * t)
		phase += TAU * frequency / float(SAMPLE_RATE)
		# Entra de golpe y se apaga, como un grito cortado.
		var envelope: float = minf(t * 14.0, 1.0) * (1.0 - t * t)
		var value: float = sin(phase) * (1.0 - NOISE) + randf_range(-1.0, 1.0) * NOISE
		var sample: int = int(clampf(value * envelope * AMPLITUDE, -1.0, 1.0) * 32767.0)
		data.append(sample & 0xFF)
		data.append((sample >> 8) & 0xFF)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav

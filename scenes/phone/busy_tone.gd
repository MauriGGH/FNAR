extends AudioStreamPlayer

## El tono de ocupado, generado por código para no depender todavía de un
## archivo: dos pitidos de 440 Hz con su silencio, como un teléfono de verdad
## cuando te cuelgan.

const SAMPLE_RATE: int = 22050
const TONE_HZ: float = 440.0
const BEEP_TIME: float = 0.33
const GAP_TIME: float = 0.2
const BEEPS: int = 2
const AMPLITUDE: float = 0.2


func _ready() -> void:
	if stream == null:
		stream = _build_tone()


## Lo que dura el tono completo, para saber cuándo hablar encima.
func tone_seconds() -> float:
	return float(BEEPS) * BEEP_TIME + float(BEEPS - 1) * GAP_TIME


func _build_tone() -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	for beep: int in BEEPS:
		_append(data, TONE_HZ, BEEP_TIME)
		if beep < BEEPS - 1:
			_append(data, 0.0, GAP_TIME)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav


## Un tramo de tono, o de silencio si la frecuencia es cero. Los extremos
## entran y salen suave para que no truene.
func _append(data: PackedByteArray, frequency: float, seconds: float) -> void:
	var samples: int = int(seconds * SAMPLE_RATE)
	var fade: int = int(0.004 * SAMPLE_RATE)
	for i: int in samples:
		var value: float = 0.0
		if frequency > 0.0:
			var envelope: float = minf(minf(float(i), float(samples - i)) / float(fade), 1.0)
			value = sin(TAU * frequency * float(i) / float(SAMPLE_RATE)) * envelope * AMPLITUDE
		var sample: int = int(clampf(value, -1.0, 1.0) * 32767.0)
		data.append(sample & 0xFF)
		data.append((sample >> 8) & 0xFF)

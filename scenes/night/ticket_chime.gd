extends AudioStreamPlayer

## El aviso sonoro de un ticket nuevo, provisional: dos pitidos cortos
## generados por código, para no depender todavía de un archivo de audio.
## Cuando el equipo entregue el sonido de verdad, basta con ponerle el stream
## a este nodo y borrar la generación.

const SAMPLE_RATE: int = 22050
## Las dos notas del aviso, en hercios, y lo que dura cada una.
const TONES: Array[float] = [880.0, 1320.0]
const TONE_TIME: float = 0.09
const GAP_TIME: float = 0.04
const AMPLITUDE: float = 0.22


func _ready() -> void:
	if stream == null:
		stream = _build_chime()


## Arma el wav de los dos pitidos, con una envolvente para que no truene.
func _build_chime() -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	for index: int in TONES.size():
		_append_tone(data, TONES[index], TONE_TIME)
		if index < TONES.size() - 1:
			_append_silence(data, GAP_TIME)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav


func _append_tone(data: PackedByteArray, frequency: float, seconds: float) -> void:
	var samples: int = int(seconds * SAMPLE_RATE)
	for i: int in samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		# Entra y sale suave, para que no suene a click.
		var envelope: float = sin(PI * float(i) / float(samples))
		_append_sample(data, sin(TAU * frequency * t) * envelope * AMPLITUDE)


func _append_silence(data: PackedByteArray, seconds: float) -> void:
	for i: int in int(seconds * SAMPLE_RATE):
		_append_sample(data, 0.0)


func _append_sample(data: PackedByteArray, value: float) -> void:
	var sample: int = int(clampf(value, -1.0, 1.0) * 32767.0)
	data.append(sample & 0xFF)
	data.append((sample >> 8) & 0xFF)

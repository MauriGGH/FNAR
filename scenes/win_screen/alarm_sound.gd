extends AudioStreamPlayer

## El despertador de las 6 AM, provisional: pitidos cortos y repetidos generados
## por código, en bucle, hasta que suena la campana. Cuando llegue el audio de
## verdad basta con ponerle el stream a este nodo.

const SAMPLE_RATE: int = 22050
const FREQUENCY: float = 2100.0
const BEEP_TIME: float = 0.11
const GAP_TIME: float = 0.1
## Pitidos por tanda, y el silencio entre tandas.
const BEEPS_PER_BURST: int = 4
const BURST_GAP: float = 0.5
const AMPLITUDE: float = 0.3


func _ready() -> void:
	if stream == null:
		stream = _build_alarm()


func _build_alarm() -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	for index: int in BEEPS_PER_BURST:
		_append_beep(data)
		_append_silence(data, GAP_TIME)
	_append_silence(data, BURST_GAP)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	# En bucle: suena hasta que lo pare la campana.
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = 0
	return wav


## Un pitido con los bordes suavizados, para que no truene.
func _append_beep(data: PackedByteArray) -> void:
	var samples: int = int(BEEP_TIME * SAMPLE_RATE)
	# Los primeros y últimos milisegundos entran y salen en rampa.
	var ramp: int = maxi(1, int(0.004 * SAMPLE_RATE))
	for i: int in samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = minf(1.0, minf(float(i), float(samples - i)) / float(ramp))
		_append_sample(data, sin(TAU * FREQUENCY * t) * envelope * AMPLITUDE)


func _append_silence(data: PackedByteArray, seconds: float) -> void:
	for i: int in int(seconds * SAMPLE_RATE):
		_append_sample(data, 0.0)


func _append_sample(data: PackedByteArray, value: float) -> void:
	var sample: int = int(clampf(value, -1.0, 1.0) * 32767.0)
	data.append(sample & 0xFF)
	data.append((sample >> 8) & 0xFF)

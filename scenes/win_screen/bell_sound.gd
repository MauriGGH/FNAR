extends AudioStreamPlayer

## La campana de la escuela con aplausos, provisional y por código: primero dos
## golpes de campana y encima una ovación que crece y se va. Igual que los otros
## sonidos del juego, se reemplaza poniéndole el stream al nodo.

const SAMPLE_RATE: int = 22050
const LENGTH: float = 3.2

## La campana: dos golpes y sus armónicos, que es lo que la hace sonar metálica.
const STRIKE_TIMES: Array[float] = [0.0, 0.42]
const BELL_FREQUENCY: float = 660.0
const BELL_PARTIALS: Array[float] = [1.0, 2.76, 5.4]
const BELL_GAINS: Array[float] = [1.0, 0.5, 0.22]
const BELL_DECAY: float = 2.6
const BELL_AMPLITUDE: float = 0.42

## Los aplausos: ruido con la envolvente de una ovación.
const CLAP_START: float = 0.5
const CLAP_RISE: float = 0.5
const CLAP_FALL: float = 1.6
const CLAP_AMPLITUDE: float = 0.3


func _ready() -> void:
	if stream == null:
		stream = _build_bell()


func _build_bell() -> AudioStreamWAV:
	var length: int = int(LENGTH * SAMPLE_RATE)
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(length)
	for strike: float in STRIKE_TIMES:
		_add_strike(buffer, strike)
	_add_applause(buffer)

	var peak: float = 0.0
	for value: float in buffer:
		peak = maxf(peak, absf(value))
	var scale: float = 1.0 if is_zero_approx(peak) else 0.9 / peak
	var data: PackedByteArray = PackedByteArray()
	data.resize(length * 2)
	for i: int in length:
		var sample: int = int(clampf(buffer[i] * scale, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav


## Un golpe de campana: los armónicos apagándose juntos.
func _add_strike(buffer: PackedFloat32Array, start: float) -> void:
	var first: int = int(start * SAMPLE_RATE)
	for i: int in buffer.size() - first:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = exp(-BELL_DECAY * t)
		if envelope < 0.001:
			break
		var value: float = 0.0
		for p: int in BELL_PARTIALS.size():
			value += sin(TAU * BELL_FREQUENCY * BELL_PARTIALS[p] * t) * BELL_GAINS[p]
		buffer[first + i] += value * envelope * BELL_AMPLITUDE


## La ovación: ruido blanco que sube rápido y baja despacio.
func _add_applause(buffer: PackedFloat32Array) -> void:
	var first: int = int(CLAP_START * SAMPLE_RATE)
	for i: int in buffer.size() - first:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = 0.0
		if t < CLAP_RISE:
			envelope = t / CLAP_RISE
		else:
			envelope = exp(-(t - CLAP_RISE) / CLAP_FALL)
		buffer[first + i] += randf_range(-1.0, 1.0) * envelope * CLAP_AMPLITUDE

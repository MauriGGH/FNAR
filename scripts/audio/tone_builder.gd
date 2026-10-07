class_name ToneBuilder
extends RefCounted

## Los sonidos provisionales del juego, generados por código. Están todos aquí
## para que el AudioManager pueda armar el que falte sin depender de ningún nodo
## de escena: si el archivo de verdad no está en assets/audio/, se usa el de
## aquí y el juego suena igual, aunque de aspecto más pobre.
##
## Cada sonido es una función estática que devuelve un AudioStreamWAV. Las
## primitivas de abajo (tonos, ruido, campanas) las comparten varias.

const SAMPLE_RATE: int = 22050

# --- Cajita musical ----------------------------------------------------------
## La nota de referencia: un la agudo, el registro de una cajita musical.
const BOX_BASE_HZ: float = 880.0
const BOX_BEAT: float = 0.42
## Melodía original, en menor, para que suene a cajita vieja y no a canción
## conocida. Pares [semitonos desde la nota base, tiempos que dura].
const BOX_MELODY: Array[Array] = [
	[0, 1], [3, 1], [7, 1], [5, 1],
	[3, 1], [0, 1], [-1, 1], [0, 2],
	[7, 1], [10, 1], [12, 1], [10, 1],
	[7, 1], [3, 1], [-1, 1], [0, 2],
]
## Los armónicos de la campanita y cuánto pesa cada uno.
const BOX_PARTIALS: Array[float] = [1.0, 2.0, 3.01]
const BOX_GAINS: Array[float] = [1.0, 0.42, 0.18]
## Lo rápido que se apaga cada nota y cuánto sigue sonando sobre la siguiente:
## el tañido que se encima es lo que la hace sonar a cajita musical.
const BOX_DECAY: float = 4.2
const BOX_TAIL: float = 1.1
const BOX_AMPLITUDE: float = 0.5


## En qué segundo empieza cada nota de la melodía. Lo usa el apagón para
## parpadear las chispas al ritmo, una por nota.
static func music_box_note_times() -> PackedFloat32Array:
	var times: PackedFloat32Array = PackedFloat32Array()
	var beat: int = 0
	for note: Array in BOX_MELODY:
		times.append(float(beat) * BOX_BEAT)
		beat += int(note[1])
	return times


## Lo que dura la melodía entera, contando la cola del último tañido.
static func music_box_length() -> float:
	var beats: int = 0
	for note: Array in BOX_MELODY:
		beats += int(note[1])
	return float(beats) * BOX_BEAT + BOX_TAIL


## La melodía. Las notas se suman en un buffer de floats porque cada tañido
## sigue sonando encima de la nota siguiente.
static func music_box() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(music_box_length())
	var beat: int = 0
	for note: Array in BOX_MELODY:
		_add_bell(buffer, float(beat) * BOX_BEAT,
			BOX_BASE_HZ * pow(2.0, float(note[0]) / 12.0),
			BOX_PARTIALS, BOX_GAINS, BOX_DECAY, BOX_TAIL, BOX_AMPLITUDE)
		beat += int(note[1])
	return _to_wav(buffer)


# --- Aviso de ticket nuevo ---------------------------------------------------
const TICKET_TONES: Array[float] = [880.0, 1320.0]
const TICKET_TONE_TIME: float = 0.09
const TICKET_GAP: float = 0.04
const TICKET_AMPLITUDE: float = 0.22


## Dos pitidos cortos, el aviso de que llegó un ticket.
static func ticket_chime() -> AudioStreamWAV:
	var length: float = float(TICKET_TONES.size()) * TICKET_TONE_TIME \
		+ float(TICKET_TONES.size() - 1) * TICKET_GAP
	var buffer: PackedFloat32Array = _buffer(length)
	var at: float = 0.0
	for tone: float in TICKET_TONES:
		_add_tone(buffer, at, tone, TICKET_TONE_TIME, TICKET_AMPLITUDE)
		at += TICKET_TONE_TIME + TICKET_GAP
	return _to_wav(buffer)


# --- Grito del jumpscare -----------------------------------------------------
const SCREAM_TIME: float = 0.55
const SCREAM_FROM_HZ: float = 1400.0
const SCREAM_TO_HZ: float = 180.0
const SCREAM_AMPLITUDE: float = 0.3
## Cuánto ruido se le mezcla al tono, para que suene roto y no a sirena.
const SCREAM_NOISE: float = 0.55


## Un barrido que baja de tono, roto con ruido: el grito provisional.
static func scream() -> AudioStreamWAV:
	var samples: int = int(SCREAM_TIME * SAMPLE_RATE)
	var buffer: PackedFloat32Array = _buffer(SCREAM_TIME)
	var phase: float = 0.0
	for i: int in samples:
		var t: float = float(i) / float(samples)
		phase += TAU * lerpf(SCREAM_FROM_HZ, SCREAM_TO_HZ, t * t) / float(SAMPLE_RATE)
		# Entra de golpe y se apaga, como un grito cortado.
		var envelope: float = minf(t * 14.0, 1.0) * (1.0 - t * t)
		buffer[i] = (sin(phase) * (1.0 - SCREAM_NOISE)
			+ randf_range(-1.0, 1.0) * SCREAM_NOISE) * envelope * SCREAM_AMPLITUDE
	return _to_wav(buffer)


# --- Tono de ocupado del teléfono -------------------------------------------
const BUSY_HZ: float = 440.0
const BUSY_BEEP: float = 0.33
const BUSY_GAP: float = 0.2
const BUSY_BEEPS: int = 2
const BUSY_AMPLITUDE: float = 0.2


## Lo que dura el tono completo, para saber cuándo hablar encima.
static func busy_tone_length() -> float:
	return float(BUSY_BEEPS) * BUSY_BEEP + float(BUSY_BEEPS - 1) * BUSY_GAP


## Dos pitidos con su silencio, como un teléfono cuando te cuelgan.
static func busy_tone() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(busy_tone_length())
	for beep: int in BUSY_BEEPS:
		_add_tone(buffer, float(beep) * (BUSY_BEEP + BUSY_GAP), BUSY_HZ,
			BUSY_BEEP, BUSY_AMPLITUDE)
	return _to_wav(buffer)


# --- Despertador de las 6 AM -------------------------------------------------
const ALARM_HZ: float = 2100.0
const ALARM_BEEP: float = 0.11
const ALARM_GAP: float = 0.1
## Pitidos por tanda, y el silencio entre tandas.
const ALARM_BEEPS: int = 4
const ALARM_BURST_GAP: float = 0.5
const ALARM_AMPLITUDE: float = 0.3


## Pitidos repetidos, en bucle hasta que suena la campana.
static func alarm() -> AudioStreamWAV:
	var length: float = float(ALARM_BEEPS) * (ALARM_BEEP + ALARM_GAP) + ALARM_BURST_GAP
	var buffer: PackedFloat32Array = _buffer(length)
	for beep: int in ALARM_BEEPS:
		_add_tone(buffer, float(beep) * (ALARM_BEEP + ALARM_GAP), ALARM_HZ,
			ALARM_BEEP, ALARM_AMPLITUDE)
	return _to_wav(buffer)


# --- Campana de la escuela con aplausos -------------------------------------
const BELL_LENGTH: float = 3.2
## Dos golpes de campana y sus armónicos, que es lo que la hace sonar metálica.
const BELL_STRIKES: Array[float] = [0.0, 0.42]
const BELL_HZ: float = 660.0
const BELL_PARTIALS: Array[float] = [1.0, 2.76, 5.4]
const BELL_GAINS: Array[float] = [1.0, 0.5, 0.22]
const BELL_DECAY: float = 2.6
const BELL_AMPLITUDE: float = 0.42
## La ovación: ruido con la envolvente de unos aplausos.
const CLAP_START: float = 0.5
const CLAP_RISE: float = 0.5
const CLAP_FALL: float = 1.6
const CLAP_AMPLITUDE: float = 0.3


static func school_bell() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(BELL_LENGTH)
	for strike: float in BELL_STRIKES:
		_add_bell(buffer, strike, BELL_HZ, BELL_PARTIALS, BELL_GAINS,
			BELL_DECAY, BELL_LENGTH, BELL_AMPLITUDE)
	_add_applause(buffer)
	return _to_wav(buffer)


# --- Pasos que se acercan ----------------------------------------------------
## Tres pasos, cada vez más cerca y más fuerte. Los segundos en que caen y lo
## que sube el volumen de uno al siguiente.
const STEP_TIMES: Array[float] = [0.0, 0.62, 1.18]
const STEP_GAINS: Array[float] = [0.35, 0.6, 1.0]
const STEPS_LENGTH: float = 1.9
## Cada paso es un golpe grave de ruido muy corto.
const STEP_HZ: float = 70.0
const STEP_TIME: float = 0.16
const STEP_DECAY: float = 26.0
const STEP_NOISE: float = 0.45
const STEP_AMPLITUDE: float = 0.55


## Los tres pasos del apagón, acercándose en la oscuridad.
static func footsteps() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(STEPS_LENGTH)
	for index: int in STEP_TIMES.size():
		_add_thud(buffer, STEP_TIMES[index], STEP_HZ, STEP_TIME,
			STEP_AMPLITUDE * STEP_GAINS[index], STEP_DECAY, STEP_NOISE)
	return _to_wav(buffer)


## Lo que tardan los tres pasos, para encadenar el salto justo después.
static func footsteps_length() -> float:
	return STEPS_LENGTH


# --- Golpe grave de las alucinaciones ---------------------------------------
const HIT_LENGTH: float = 0.9
const HIT_HZ: float = 46.0
const HIT_DECAY: float = 5.5
const HIT_NOISE: float = 0.3
const HIT_AMPLITUDE: float = 0.75


## El golpe que acompaña al cuadro de una alucinación: muy grave y seco.
static func low_hit() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(HIT_LENGTH)
	_add_thud(buffer, 0.0, HIT_HZ, HIT_LENGTH, HIT_AMPLITUDE, HIT_DECAY, HIT_NOISE)
	return _to_wav(buffer)


# --- Primitivas --------------------------------------------------------------

static func _buffer(seconds: float) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(maxi(1, int(seconds * SAMPLE_RATE)))
	return buffer


## Un tono limpio con los bordes en rampa, para que no truene al entrar ni salir.
static func _add_tone(buffer: PackedFloat32Array, start: float, frequency: float,
		seconds: float, amplitude: float) -> void:
	var first: int = int(start * SAMPLE_RATE)
	var samples: int = int(seconds * SAMPLE_RATE)
	var ramp: int = maxi(1, int(0.004 * SAMPLE_RATE))
	for i: int in samples:
		var index: int = first + i
		if index >= buffer.size():
			return
		var envelope: float = minf(1.0, minf(float(i), float(samples - i)) / float(ramp))
		buffer[index] += sin(TAU * frequency * float(i) / float(SAMPLE_RATE)) \
			* envelope * amplitude


## Un tañido de campana: varios armónicos apagándose juntos.
static func _add_bell(buffer: PackedFloat32Array, start: float, frequency: float,
		partials: Array[float], gains: Array[float], decay: float,
		tail: float, amplitude: float) -> void:
	var first: int = int(start * SAMPLE_RATE)
	var samples: int = int(tail * SAMPLE_RATE)
	for i: int in samples:
		var index: int = first + i
		if index >= buffer.size():
			return
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = exp(-decay * t)
		if envelope < 0.001:
			return
		var value: float = 0.0
		for p: int in partials.size():
			value += sin(TAU * frequency * partials[p] * t) * gains[p]
		buffer[index] += value * envelope * amplitude


## Un golpe grave: una onda baja mezclada con ruido, que se apaga de golpe.
static func _add_thud(buffer: PackedFloat32Array, start: float, frequency: float,
		seconds: float, amplitude: float, decay: float, noise: float) -> void:
	var first: int = int(start * SAMPLE_RATE)
	var samples: int = int(seconds * SAMPLE_RATE)
	for i: int in samples:
		var index: int = first + i
		if index >= buffer.size():
			return
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = exp(-decay * t)
		if envelope < 0.001:
			return
		buffer[index] += (sin(TAU * frequency * t) * (1.0 - noise)
			+ randf_range(-1.0, 1.0) * noise) * envelope * amplitude


## Ruido blanco que sube rápido y baja despacio: una ovación.
static func _add_applause(buffer: PackedFloat32Array) -> void:
	var first: int = int(CLAP_START * SAMPLE_RATE)
	for i: int in buffer.size() - first:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = t / CLAP_RISE if t < CLAP_RISE \
			else exp(-(t - CLAP_RISE) / CLAP_FALL)
		buffer[first + i] += randf_range(-1.0, 1.0) * envelope * CLAP_AMPLITUDE


## Normaliza y pasa a 16 bits, para que nada sature.
static func _to_wav(buffer: PackedFloat32Array) -> AudioStreamWAV:
	var peak: float = 0.0
	for value: float in buffer:
		peak = maxf(peak, absf(value))
	var scale: float = 1.0 if is_zero_approx(peak) else 0.92 / peak
	var data: PackedByteArray = PackedByteArray()
	data.resize(buffer.size() * 2)
	for i: int in buffer.size():
		var sample: int = int(clampf(buffer[i] * scale, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav

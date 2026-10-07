extends AudioStreamPlayer

## La canción de cajita musical. La toca la botarga del Come Trabas mientras le
## quede cuerda, y vuelve a sonar en las chispas del apagón del Mago Eléctrico:
## es la misma melodía en los dos casos, por eso vive en un solo nodo.
##
## Si existe `assets/audio/cajita_musical.ogg` se usa ese archivo. Mientras no
## exista, la melodía se genera por código como placeholder, igual que el aviso
## de los tickets o el grito. Al entregar el .ogg no hay que tocar nada más.

const AUDIO_PATH: String = "res://assets/audio/cajita_musical.ogg"

## Qué tan fuerte suena en cada caso: de fondo con la botarga, al frente en las
## chispas, que son lo único que se ve y se oye en la oscuridad.
const LOOP_VOLUME_DB: float = -16.0
const ONCE_VOLUME_DB: float = -6.0

const SAMPLE_RATE: int = 22050
## La nota de referencia: un la agudo, el registro de una cajita musical.
const BASE_FREQUENCY: float = 880.0
## Lo que dura un tiempo de la melodía.
const BEAT_TIME: float = 0.42
## La melodía, en pares [semitonos desde la nota base, tiempos que dura].
## Melodía original, en menor, para que suene a cajita vieja y no a canción
## conocida.
const MELODY: Array[Array] = [
	[0, 1], [3, 1], [7, 1], [5, 1],
	[3, 1], [0, 1], [-1, 1], [0, 2],
	[7, 1], [10, 1], [12, 1], [10, 1],
	[7, 1], [3, 1], [-1, 1], [0, 2],
]
## Los armónicos de la campanita y cuánto pesa cada uno.
const PARTIALS: Array[float] = [1.0, 2.0, 3.01]
const PARTIAL_GAINS: Array[float] = [1.0, 0.42, 0.18]
## Lo rápido que se apaga cada nota y cuánto puede seguir sonando sobre la que
## sigue: el tañido que se encima es lo que la hace sonar a cajita musical.
const DECAY: float = 4.2
const RING_TAIL: float = 1.1
const AMPLITUDE: float = 0.5


func _ready() -> void:
	if stream == null:
		stream = _load_or_build()


## El archivo de verdad si ya está entregado; si no, la melodía por código.
func _load_or_build() -> AudioStream:
	if ResourceLoader.exists(AUDIO_PATH):
		var loaded: AudioStream = load(AUDIO_PATH) as AudioStream
		if loaded != null:
			# Una copia propia: marcar el bucle no debe tocar el recurso en caché.
			return loaded.duplicate() as AudioStream
	return _build_melody()


## Empieza la melodía en bucle. Si ya está sonando la deja seguir, para que no
## se reinicie a cada rato.
func start_loop() -> void:
	_set_looping(true)
	volume_db = LOOP_VOLUME_DB
	if not playing:
		play()


## La toca una vez desde el principio, para las chispas del apagón.
func play_once() -> void:
	_set_looping(false)
	volume_db = ONCE_VOLUME_DB
	play()


func stop_music() -> void:
	if playing:
		stop()


## El bucle se marca distinto según de dónde venga el audio.
func _set_looping(looping: bool) -> void:
	var wav: AudioStreamWAV = stream as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
		wav.loop_begin = 0
		wav.loop_end = 0
		return
	var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = looping


## Arma el wav de la melodía. Las notas se suman en un buffer de floats porque
## cada tañido sigue sonando encima de la nota siguiente.
func _build_melody() -> AudioStreamWAV:
	var total_beats: int = 0
	for note: Array in MELODY:
		total_beats += int(note[1])
	var length: int = int((float(total_beats) * BEAT_TIME + RING_TAIL) * SAMPLE_RATE)
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(length)
	var beat: int = 0
	for note: Array in MELODY:
		_add_note(buffer, int(note[0]), float(beat) * BEAT_TIME)
		beat += int(note[1])
	return _to_wav(buffer)


## Un tañido: los armónicos de la campana apagándose solos.
func _add_note(buffer: PackedFloat32Array, semitones: int, start: float) -> void:
	var frequency: float = BASE_FREQUENCY * pow(2.0, float(semitones) / 12.0)
	var first: int = int(start * SAMPLE_RATE)
	var samples: int = int(RING_TAIL * SAMPLE_RATE)
	for i: int in samples:
		var index: int = first + i
		if index >= buffer.size():
			break
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = exp(-DECAY * t)
		var value: float = 0.0
		for p: int in PARTIALS.size():
			value += sin(TAU * frequency * PARTIALS[p] * t) * PARTIAL_GAINS[p]
		buffer[index] += value * envelope * AMPLITUDE



## Pasa el buffer a 16 bits, normalizando para que nada sature.
func _to_wav(buffer: PackedFloat32Array) -> AudioStreamWAV:
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

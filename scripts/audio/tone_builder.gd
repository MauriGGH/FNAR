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


## Arma el provisional que pide el catálogo por su nombre. Va con match y no con
## call() porque sobre una clase, sin instancia, no se puede llamar por nombre.
static func build(generator: String) -> AudioStreamWAV:
	match generator:
		"music_box":
			return music_box()
		"ticket_chime":
			return ticket_chime()
		"scream":
			return scream()
		"busy_tone":
			return busy_tone()
		"alarm":
			return alarm()
		"school_bell":
			return school_bell()
		"footsteps":
			return footsteps()
		"low_hit":
			return low_hit()
		"glass_repel":
			return glass_repel()
		"office_ambience":
			return office_ambience()
		"hallway_ambience":
			return hallway_ambience()
		"phone_ring":
			return phone_ring()
		"door_shutter":
			return door_shutter()
		"door_bang":
			return door_bang()
		"camera_blip":
			return camera_blip()
		"flashlight_click":
			return flashlight_click()
		"breaker_lever":
			return breaker_lever()
		"camera_static":
			return camera_static()
		"typewriter_key":
			return typewriter_key()
		"menu_blip":
			return menu_blip()
		"menu_music":
			return menu_music()
		"arcade_level1":
			return arcade_level(1)
		"arcade_level2":
			return arcade_level(2)
		"arcade_level3":
			return arcade_level(3)
		"arcade_jump":
			return arcade_jump()
		"arcade_hurt":
			return arcade_hurt()
		"arcade_pick":
			return arcade_pick()
		"arcade_boot":
			return arcade_boot()
		"arcade_music_box":
			return arcade_music_box()
		"breach":
			return breach()
		"rescue":
			return rescue()
		"momo_song":
			return momo_song()
		"phone_hang_up":
			return phone_hang_up()
		"far_running":
			return far_running()
		"far_boots":
			return far_boots()
		"far_water":
			return far_water()
		"far_keyboard":
			return far_keyboard()
		"far_modem":
			return far_modem()
		"far_spark":
			return far_spark()
		"far_chair":
			return far_chair()
		"far_door_slam":
			return far_door_slam()
		"far_upstairs":
			return far_upstairs()
		"far_laugh":
			return far_laugh()
		"far_dishes":
			return far_dishes()
		"wasted_sting":
			return wasted_sting()
	return null

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


# --- El del cristal se aleja -------------------------------------------------
const REPEL_LENGTH: float = 0.7
## Un roce que se va alejando: ruido que sube de tono y se apaga, como unos
## pasos arrastrados yéndose por el pasillo.
const REPEL_FROM_HZ: float = 520.0
const REPEL_TO_HZ: float = 190.0
const REPEL_NOISE: float = 0.72
const REPEL_AMPLITUDE: float = 0.4


static func glass_repel() -> AudioStreamWAV:
	var samples: int = int(REPEL_LENGTH * SAMPLE_RATE)
	var buffer: PackedFloat32Array = _buffer(REPEL_LENGTH)
	var phase: float = 0.0
	for i: int in samples:
		var t: float = float(i) / float(samples)
		phase += TAU * lerpf(REPEL_FROM_HZ, REPEL_TO_HZ, t) / float(SAMPLE_RATE)
		# Entra enseguida y se va apagando, como algo que se aleja.
		var envelope: float = minf(t * 10.0, 1.0) * (1.0 - t) * (1.0 - t)
		buffer[i] = (sin(phase) * (1.0 - REPEL_NOISE)
			+ randf_range(-1.0, 1.0) * REPEL_NOISE) * envelope * REPEL_AMPLITUDE
	return _to_wav(buffer)


# --- Ambiente de la oficina --------------------------------------------------
## Un bucle de 4 s: el zumbido de las lámparas (la red y su armónico) y el aire
## del ventilador. Las frecuencias caben un número entero de veces en los 4 s,
## así que el zumbido empalma solo; al ruido del ventilador le toca el
## entrecruzado del final.
const OFFICE_LENGTH: float = 4.0
const OFFICE_HUM_HZ: Array[float] = [120.0, 240.0]
const OFFICE_HUM_GAINS: Array[float] = [0.5, 0.18]
## El ventilador: ruido grave con un vaivén lento, como un aspa que pasa.
const OFFICE_FAN_CUTOFF: float = 0.04
const OFFICE_FAN_GAIN: float = 0.5
const OFFICE_FAN_WOBBLE_HZ: float = 3.0
const OFFICE_FAN_WOBBLE: float = 0.22
const LOOP_CROSSFADE: float = 0.25


static func office_ambience() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(OFFICE_LENGTH + LOOP_CROSSFADE)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var value: float = 0.0
		for h: int in OFFICE_HUM_HZ.size():
			value += sin(TAU * OFFICE_HUM_HZ[h] * t) * OFFICE_HUM_GAINS[h]
		buffer[i] = value
	var fan: PackedFloat32Array = _low_passed_noise(buffer.size(), OFFICE_FAN_CUTOFF)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var wobble: float = 1.0 - OFFICE_FAN_WOBBLE \
			+ OFFICE_FAN_WOBBLE * sin(TAU * OFFICE_FAN_WOBBLE_HZ * t)
		buffer[i] += fan[i] * OFFICE_FAN_GAIN * wobble
	return _to_wav(_seamless(buffer, OFFICE_LENGTH))


# --- Ambiente del pasillo ----------------------------------------------------
## Viento lejano con crujidos de vez en cuando. Bucle de 8 s.
const HALLWAY_LENGTH: float = 8.0
const HALLWAY_WIND_CUTOFF: float = 0.012
const HALLWAY_WIND_GAIN: float = 0.75
## El viento no es parejo: sube y baja muy despacio.
const HALLWAY_SWELL_HZ: float = 0.17
const HALLWAY_SWELL: float = 0.45
## Los crujidos: en qué segundo cae cada uno y su tono.
const HALLWAY_CREAKS: Array[float] = [1.4, 3.9, 6.6]
const HALLWAY_CREAK_HZ: Array[float] = [148.0, 96.0, 205.0]
const HALLWAY_CREAK_TIME: float = 0.4
const HALLWAY_CREAK_GAIN: float = 0.22


static func hallway_ambience() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(HALLWAY_LENGTH + LOOP_CROSSFADE)
	var wind: PackedFloat32Array = _low_passed_noise(buffer.size(), HALLWAY_WIND_CUTOFF)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var swell: float = 1.0 - HALLWAY_SWELL \
			+ HALLWAY_SWELL * sin(TAU * HALLWAY_SWELL_HZ * t)
		buffer[i] = wind[i] * HALLWAY_WIND_GAIN * swell
	for c: int in HALLWAY_CREAKS.size():
		_add_creak(buffer, HALLWAY_CREAKS[c], HALLWAY_CREAK_HZ[c])
	return _to_wav(_seamless(buffer, HALLWAY_LENGTH))


## Un crujido de madera: un tono que se desafina y se apaga, con ruido encima.
static func _add_creak(buffer: PackedFloat32Array, start: float, frequency: float) -> void:
	var first: int = int(start * SAMPLE_RATE)
	var samples: int = int(HALLWAY_CREAK_TIME * SAMPLE_RATE)
	var phase: float = 0.0
	for i: int in samples:
		var index: int = first + i
		if index >= buffer.size():
			return
		var t: float = float(i) / float(samples)
		phase += TAU * (frequency * (1.0 + t * 0.35)) / float(SAMPLE_RATE)
		var envelope: float = sin(PI * t) * sin(PI * t)
		buffer[index] += (sin(phase) * 0.6 + randf_range(-1.0, 1.0) * 0.4) \
			* envelope * HALLWAY_CREAK_GAIN


# --- Timbre del teléfono -----------------------------------------------------
## Teléfono de oficina: dos ráfagas cortas y un silencio largo, en bucle. El
## tono es la mezcla de dos frecuencias, que es lo que le da el "rrring".
const RING_HZ: Array[float] = [440.0, 480.0]
const RING_BURST: float = 0.4
const RING_BURST_GAP: float = 0.2
const RING_BURSTS: int = 2
const RING_SILENCE: float = 2.0
## El temblor que hace que suene a campanilla y no a pitido.
const RING_TREMOLO_HZ: float = 20.0
const RING_AMPLITUDE: float = 0.35


static func phone_ring() -> AudioStreamWAV:
	var length: float = float(RING_BURSTS) * RING_BURST \
		+ float(RING_BURSTS - 1) * RING_BURST_GAP + RING_SILENCE
	var buffer: PackedFloat32Array = _buffer(length)
	for burst: int in RING_BURSTS:
		var start: float = float(burst) * (RING_BURST + RING_BURST_GAP)
		var first: int = int(start * SAMPLE_RATE)
		var samples: int = int(RING_BURST * SAMPLE_RATE)
		for i: int in samples:
			var index: int = first + i
			if index >= buffer.size():
				break
			var t: float = float(i) / float(SAMPLE_RATE)
			var fade: float = minf(1.0, minf(float(i), float(samples - i)) / (0.01 * SAMPLE_RATE))
			var tremolo: float = 0.65 + 0.35 * sin(TAU * RING_TREMOLO_HZ * t)
			var value: float = 0.0
			for hz: float in RING_HZ:
				value += sin(TAU * hz * t)
			buffer[index] += value * 0.5 * tremolo * fade * RING_AMPLITUDE
	return _to_wav(buffer)


# --- Cortina metálica --------------------------------------------------------
## La lámina bajando o subiendo: un traqueteo de ruido con un golpe al final.
const SHUTTER_LENGTH: float = 0.95
const SHUTTER_RATTLE_HZ: float = 26.0
const SHUTTER_CUTOFF: float = 0.25
const SHUTTER_GAIN: float = 0.55
## El golpe de la lámina al llegar abajo.
const SHUTTER_THUD_AT: float = 0.78
const SHUTTER_THUD_HZ: float = 58.0


static func door_shutter() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(SHUTTER_LENGTH)
	var rattle: PackedFloat32Array = _low_passed_noise(buffer.size(), SHUTTER_CUTOFF)
	var samples: int = buffer.size()
	for i: int in samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(samples)
		# El traqueteo va por golpecitos, como los eslabones de la lámina.
		var ticks: float = 0.5 + 0.5 * sin(TAU * SHUTTER_RATTLE_HZ * t)
		var envelope: float = minf(progress * 8.0, 1.0) * (1.0 - progress * 0.55)
		buffer[i] = rattle[i] * ticks * envelope * SHUTTER_GAIN
	_add_thud(buffer, SHUTTER_THUD_AT, SHUTTER_THUD_HZ, 0.2, 0.8, 22.0, 0.35)
	return _to_wav(buffer)


# --- Barcosa golpeando -------------------------------------------------------
## Un golpe en la lámina: el porrazo grave y el repique metálico encima.
const BANG_LENGTH: float = 0.45
const BANG_HZ: float = 62.0
const BANG_RING_HZ: float = 430.0
const BANG_RING_GAINS: Array[float] = [1.0, 0.6, 0.3]
const BANG_RING_PARTIALS: Array[float] = [1.0, 2.41, 4.17]


static func door_bang() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(BANG_LENGTH)
	_add_thud(buffer, 0.0, BANG_HZ, BANG_LENGTH, 0.9, 16.0, 0.4)
	_add_bell(buffer, 0.0, BANG_RING_HZ, BANG_RING_PARTIALS, BANG_RING_GAINS,
		9.0, BANG_LENGTH, 0.3)
	return _to_wav(buffer)


# --- Blip al cambiar de cámara -----------------------------------------------
const BLIP_HZ: float = 1600.0
const BLIP_TIME: float = 0.06
const BLIP_AMPLITUDE: float = 0.3


static func camera_blip() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(BLIP_TIME)
	_add_tone(buffer, 0.0, BLIP_HZ, BLIP_TIME, BLIP_AMPLITUDE)
	return _to_wav(buffer)


# --- Clic de la linterna -----------------------------------------------------
## Un chasquido seco: un golpe de ruido muy corto y agudo.
const CLICK_LENGTH: float = 0.05
const CLICK_DECAY: float = 160.0
const CLICK_AMPLITUDE: float = 0.5


static func flashlight_click() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(CLICK_LENGTH)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		buffer[i] = randf_range(-1.0, 1.0) * exp(-CLICK_DECAY * t) * CLICK_AMPLITUDE
	return _to_wav(buffer)


# --- Irrupción del operativo -------------------------------------------------
## La puerta derribada y los gritos de encima: un golpe seco muy grave y, tras
## él, ruido de banda ancha con la envolvente picada de unas voces gritando.
const BREACH_LENGTH: float = 1.2
const BREACH_HIT_HZ: float = 65.0
const BREACH_SHOUTS: Array[float] = [0.18, 0.42, 0.7, 0.95]
const BREACH_SHOUT_LENGTH: float = 0.22
const BREACH_SHOUT_AMPLITUDE: float = 0.45


# --- El rescate de Sergio y la canción de Momo --------------------------------
## Las dos son pistas largas con sus momentos marcados. Estos provisionales no
## imitan la música: solo ponen algo en cada tiempo para poder probar la escena
## con los archivos de verdad fuera.
const RESCUE_LENGTH: float = 18.8
const RESCUE_PAD_HZ: Array[float] = [98.0, 146.8, 196.0]
const MOMO_LENGTH: float = 15.3
const MOMO_BEAT: float = 0.42
const MOMO_BASE_HZ: float = 523.0
const MOMO_NOTES: Array[int] = [0, 4, 7, 4, 0, -3, 0, 4]


## El rescate: un acorde que se sostiene, un golpe de aire a los 3.5 s y un
## brillo que crece desde los 8.5 s, que es cuando entra el tótem.
static func rescue() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(RESCUE_LENGTH)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var value: float = 0.0
		for hz: float in RESCUE_PAD_HZ:
			value += sin(TAU * hz * t) * 0.12
		# El aire del haz.
		if t >= Sergio.RESCUE_BEAM_AT and t < Sergio.RESCUE_BEAM_AT + 1.2:
			var air: float = (t - Sergio.RESCUE_BEAM_AT) / 1.2
			value += randf_range(-1.0, 1.0) * sin(air * PI) * 0.3
		# Y el aura del tótem, que se abre y se queda.
		if t >= Sergio.RESCUE_TOTEM_AT:
			var up: float = minf((t - Sergio.RESCUE_TOTEM_AT) / 0.6, 1.0)
			value += sin(TAU * 784.0 * t) * 0.1 * up
			value += sin(TAU * 1046.0 * t) * 0.07 * up
		buffer[i] = value * 0.6
	return _to_wav(buffer)


## La de Momo: una melodía de cajita que se va desafinando, y al llegar al
## screamer todo se convierte en ruido.
static func momo_song() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(MOMO_LENGTH)
	var notes: int = int(Momo.SCREAMER_AT / MOMO_BEAT)
	for note: int in notes:
		var sour: float = -2.5 * float(note) / float(maxi(notes - 1, 1))
		var step: int = MOMO_NOTES[note % MOMO_NOTES.size()]
		var hz: float = MOMO_BASE_HZ * pow(2.0, (float(step) + sour) / 12.0)
		var first: int = int(float(note) * MOMO_BEAT * SAMPLE_RATE)
		var samples: int = int(MOMO_BEAT * 1.4 * SAMPLE_RATE)
		for i: int in samples:
			var index: int = first + i
			if index >= buffer.size():
				break
			var t: float = float(i) / float(SAMPLE_RATE)
			buffer[index] += sin(TAU * hz * t) * exp(-3.5 * t) * 0.28
	# El grito del final: ruido de banda ancha hasta que se acaba.
	var scream_at: int = int(Momo.SCREAMER_AT * SAMPLE_RATE)
	for i: int in range(scream_at, buffer.size()):
		var t: float = float(i - scream_at) / float(SAMPLE_RATE)
		buffer[i] += randf_range(-1.0, 1.0) * minf(t / 0.1, 1.0) * 0.45
	return _to_wav(buffer)


static func breach() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(BREACH_LENGTH)
	# El portazo.
	_add_thud(buffer, 0.0, BREACH_HIT_HZ, 0.5, 0.95, 9.0, 0.5)
	# Y los gritos encima, cada uno con su propia subida y bajada.
	for start: float in BREACH_SHOUTS:
		var first: int = int(start * SAMPLE_RATE)
		var samples: int = int(BREACH_SHOUT_LENGTH * SAMPLE_RATE)
		for i: int in samples:
			var index: int = first + i
			if index >= buffer.size():
				break
			var t: float = float(i) / float(samples)
			var envelope: float = sin(t * PI)
			buffer[index] += randf_range(-1.0, 1.0) * envelope * BREACH_SHOUT_AMPLITUDE
	return _to_wav(buffer)


# --- La maquinita, en 8 bits -------------------------------------------------
## Las melodías de los minijuegos, hechas con ondas cuadradas, que es lo que
## suena a consola vieja. La del nivel 1 va afinada; la del 2 es la misma pero
## **desafinada**, como una cinta que se estira; la del 3 no tiene melodía: es
## un zumbido grave y nada más.
const ARCADE_BEAT: float = 0.16
const ARCADE_BASE_HZ: float = 262.0   # un do
## La melodía, en semitonos desde la base. Son dos compases que dan la vuelta.
const ARCADE_MELODY: Array[int] = [
	0, 4, 7, 12, 7, 4, 0, 4,
	5, 9, 12, 9, 5, 2, 0, -5,
]
## Lo que se desafina cada nivel, en semitonos.
const ARCADE_DETUNE: Array[float] = [0.0, 0.35, 0.0]
const ARCADE_AMPLITUDE: float = 0.3
## El zumbido del nivel 3.
const ARCADE_DRONE_HZ: float = 58.0
const ARCADE_DRONE_LENGTH: float = 4.0


## Una onda cuadrada: o arriba o abajo, nada en medio. Es el sonido de la NES.
static func _square(phase: float) -> float:
	return 1.0 if fmod(phase, TAU) < PI else -1.0


static func arcade_level(level: int) -> AudioStreamWAV:
	if level >= 3:
		return arcade_drone()
	var length: float = ARCADE_BEAT * float(ARCADE_MELODY.size())
	var buffer: PackedFloat32Array = _buffer(length)
	var detune: float = ARCADE_DETUNE[clampi(level, 1, 3) - 1]
	for note: int in ARCADE_MELODY.size():
		var hz: float = ARCADE_BASE_HZ * pow(2.0, (float(ARCADE_MELODY[note]) + detune) / 12.0)
		var first: int = int(float(note) * ARCADE_BEAT * SAMPLE_RATE)
		var samples: int = int(ARCADE_BEAT * SAMPLE_RATE)
		for i: int in samples:
			var index: int = first + i
			if index >= buffer.size():
				break
			var t: float = float(i) / float(SAMPLE_RATE)
			# Cada nota ataca y se apaga, para que se oigan separadas.
			var envelope: float = minf(float(i) / 120.0, 1.0) * exp(-5.0 * t)
			buffer[index] += _square(TAU * hz * t) * envelope * ARCADE_AMPLITUDE
			# Y un bajo una octava abajo, a la mitad de volumen.
			buffer[index] += _square(TAU * hz * 0.5 * t) * envelope \
				* ARCADE_AMPLITUDE * 0.4
	return _to_wav(buffer)


## El zumbido del nivel 3: grave, con un batido lento que inquieta.
static func arcade_drone() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(ARCADE_DRONE_LENGTH)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var wobble: float = 1.0 + 0.012 * sin(TAU * 0.25 * t)
		buffer[i] = (_square(TAU * ARCADE_DRONE_HZ * wobble * t) * 0.18
			+ sin(TAU * ARCADE_DRONE_HZ * 1.5 * t) * 0.06)
	return _to_wav(buffer)


## El pitido de saltar: una onda cuadrada que sube de golpe.
static func arcade_jump() -> AudioStreamWAV:
	var length: float = 0.12
	var buffer: PackedFloat32Array = _buffer(length)
	var phase: float = 0.0
	for i: int in buffer.size():
		var t: float = float(i) / float(length * SAMPLE_RATE)
		phase += TAU * lerpf(300.0, 760.0, t) / float(SAMPLE_RATE)
		buffer[i] = _square(phase) * (1.0 - t) * 0.3
	return _to_wav(buffer)


## El de perder una vida: una onda cuadrada que se desploma de tono.
static func arcade_hurt() -> AudioStreamWAV:
	var length: float = 0.35
	var buffer: PackedFloat32Array = _buffer(length)
	var phase: float = 0.0
	for i: int in buffer.size():
		var t: float = float(i) / float(length * SAMPLE_RATE)
		phase += TAU * lerpf(420.0, 90.0, t * t) / float(SAMPLE_RATE)
		buffer[i] = _square(phase) * (1.0 - t) * 0.32
	return _to_wav(buffer)


## Y el de recoger: dos notas cortas, de premio.
static func arcade_pick() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(0.14)
	for step: int in 2:
		var hz: float = 660.0 if step == 0 else 990.0
		var first: int = int(float(step) * 0.06 * SAMPLE_RATE)
		var samples: int = int(0.055 * SAMPLE_RATE)
		for i: int in samples:
			var index: int = first + i
			if index >= buffer.size():
				break
			var t: float = float(i) / float(SAMPLE_RATE)
			buffer[index] = _square(TAU * hz * t) * exp(-22.0 * t) * 0.3
	return _to_wav(buffer)


## El arranque: un bip largo con su chisporroteo de estática.
static func arcade_boot() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(0.45)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var hiss: float = randf_range(-1.0, 1.0) * exp(-9.0 * t) * 0.18
		var beep: float = 0.0
		if t > 0.12 and t < 0.3:
			beep = _square(TAU * 880.0 * t) * 0.26
		buffer[i] = hiss + beep
	return _to_wav(buffer)


## La cajita musical del nivel 3, pero rota: la melodía de la botarga bajada de
## tono y con el afinado yéndose.
static func arcade_music_box() -> AudioStreamWAV:
	var length: float = 2.0
	var buffer: PackedFloat32Array = _buffer(length)
	var beat: float = 0.25
	var notes: Array[int] = [0, 3, 7, 5, 3, 0, -2, 0]
	for note: int in notes.size():
		var slide: float = -1.2 * float(note) / float(notes.size())
		var hz: float = BOX_BASE_HZ * 0.5 * pow(2.0, (float(notes[note]) + slide) / 12.0)
		var first: int = int(float(note) * beat * SAMPLE_RATE)
		var samples: int = int(beat * 1.6 * SAMPLE_RATE)
		for i: int in samples:
			var index: int = first + i
			if index >= buffer.size():
				break
			var t: float = float(i) / float(SAMPLE_RATE)
			buffer[index] += sin(TAU * hz * t) * exp(-3.0 * t) * 0.3
	return _to_wav(buffer)


# --- Música del menú ---------------------------------------------------------
## Un zumbido grave y lento, de los que no se notan hasta que paran. Dura seis
## segundos justos y las tres frecuencias caben un número entero de veces en
## ellos, así que el bucle no da ningún salto.
const MENU_MUSIC_LENGTH: float = 6.0
const MENU_MUSIC_HZ: Array[float] = [55.0, 82.5, 110.0]
const MENU_MUSIC_GAINS: Array[float] = [0.5, 0.26, 0.14]
## Lo que respira: sube y baja tres veces en los seis segundos.
const MENU_MUSIC_BREATH_HZ: float = 0.5
const MENU_MUSIC_AMPLITUDE: float = 0.35


static func menu_music() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(MENU_MUSIC_LENGTH)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		var value: float = 0.0
		for note: int in MENU_MUSIC_HZ.size():
			value += sin(TAU * MENU_MUSIC_HZ[note] * t) * MENU_MUSIC_GAINS[note]
		var breath: float = 0.75 + 0.25 * sin(TAU * MENU_MUSIC_BREATH_HZ * t)
		buffer[i] = value * breath * MENU_MUSIC_AMPLITUDE
	return _to_wav(buffer)


# --- Blip de menú ------------------------------------------------------------
## Un pitido corto y seco, de los de moverse por un menú de consola vieja.
const MENU_BLIP_LENGTH: float = 0.07
const MENU_BLIP_HZ: float = 740.0
const MENU_BLIP_AMPLITUDE: float = 0.4


static func menu_blip() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(MENU_BLIP_LENGTH)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		# Entra de golpe y se apaga enseguida, para que no zumbe.
		var envelope: float = exp(-28.0 * t) * minf(float(i) / 40.0, 1.0)
		buffer[i] = sin(TAU * MENU_BLIP_HZ * t) * envelope * MENU_BLIP_AMPLITUDE
	return _to_wav(buffer)


# --- Tecla de máquina de escribir --------------------------------------------
## El "clac" de una tecla: un golpe de madera corto con su repique metálico.
const TYPE_LENGTH: float = 0.09
const TYPE_HZ: float = 320.0
const TYPE_DECAY: float = 70.0
const TYPE_AMPLITUDE: float = 0.55
const TYPE_RING_HZ: float = 2600.0
const TYPE_RING_AMPLITUDE: float = 0.12


static func typewriter_key() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(TYPE_LENGTH)
	_add_thud(buffer, 0.0, TYPE_HZ, TYPE_LENGTH, TYPE_AMPLITUDE, TYPE_DECAY, 0.7)
	# El repique de la palanca al volver, encima del golpe.
	_add_tone(buffer, 0.012, TYPE_RING_HZ, 0.03, TYPE_RING_AMPLITUDE)
	return _to_wav(buffer)


# --- Palanca del breaker -----------------------------------------------------
## Más pesada que el clic de la linterna: dos chasquidos, el de la palanca al
## soltarse y el del contacto al cerrar.
const LEVER_LENGTH: float = 0.3
const LEVER_CLACKS: Array[float] = [0.0, 0.07]
const LEVER_HZ: float = 190.0
const LEVER_DECAY: float = 45.0
const LEVER_AMPLITUDE: float = 0.6


static func breaker_lever() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(LEVER_LENGTH)
	for clack: float in LEVER_CLACKS:
		_add_thud(buffer, clack, LEVER_HZ, 0.12, LEVER_AMPLITUDE, LEVER_DECAY, 0.65)
	return _to_wav(buffer)


# --- Estática de las cámaras -------------------------------------------------
## El siseo de fondo mientras el monitor está abierto. Bucle de 3 s, suave.
const STATIC_LENGTH: float = 3.0
const STATIC_CUTOFF: float = 0.5
const STATIC_GAIN: float = 0.5


static func camera_static() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(STATIC_LENGTH + LOOP_CROSSFADE)
	var hiss: PackedFloat32Array = _low_passed_noise(buffer.size(), STATIC_CUTOFF)
	for i: int in buffer.size():
		buffer[i] = hiss[i] * STATIC_GAIN
	return _to_wav(_seamless(buffer, STATIC_LENGTH))


# --- Colgar el teléfono ------------------------------------------------------
## Dos clacs secos muy juntos, como el auricular cayendo en la horquilla, y un
## tintineo corto de la campanilla.
const HANG_UP_LENGTH: float = 0.45
const HANG_UP_CLACKS: Array[float] = [0.0, 0.05]
const HANG_UP_HZ: float = 240.0
const HANG_UP_DECAY: float = 60.0
const HANG_UP_AMPLITUDE: float = 0.6
## El resto de campanilla que deja el golpe.
const HANG_UP_RING_HZ: float = 900.0
const HANG_UP_RING_PARTIALS: Array[float] = [1.0, 2.7]
const HANG_UP_RING_GAINS: Array[float] = [1.0, 0.4]


static func phone_hang_up() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(HANG_UP_LENGTH)
	for clack: float in HANG_UP_CLACKS:
		_add_thud(buffer, clack, HANG_UP_HZ, 0.1, HANG_UP_AMPLITUDE, HANG_UP_DECAY, 0.7)
	_add_bell(buffer, 0.04, HANG_UP_RING_HZ, HANG_UP_RING_PARTIALS, HANG_UP_RING_GAINS,
		14.0, HANG_UP_LENGTH, 0.22)
	return _to_wav(buffer)


# --- Lo que se oye de lejos --------------------------------------------------
# Todos salen por el bus Lejos, que ya les mete reverb grande y un paso bajo a
# 2500 Hz. Por eso aquí se generan secos y sin graves de más: el bus hace el
# trabajo de "esto viene de otra habitación".

## Pasos rápidos que se acercan: cada vez más seguidos y más fuertes.
const RUN_STEPS: int = 9
const RUN_LENGTH: float = 2.1
const RUN_HZ: float = 95.0


static func far_running() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(RUN_LENGTH)
	var at: float = 0.0
	var gap: float = 0.33
	for i: int in RUN_STEPS:
		var near: float = float(i) / float(RUN_STEPS - 1)
		_add_thud(buffer, at, RUN_HZ, 0.14, 0.3 + near * 0.6, 30.0, 0.5)
		at += gap
		gap = maxf(gap * 0.88, 0.14)   # se acerca: pisa más seguido
	return _to_wav(buffer)


## Botas pesadas y un radio con estática de fondo.
const BOOTS_STEPS: Array[float] = [0.0, 0.72, 1.44, 2.16]
const BOOTS_HZ: float = 70.0
const RADIO_START: float = 0.9
const RADIO_LENGTH: float = 1.1


static func far_boots() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(2.9)
	for at: float in BOOTS_STEPS:
		_add_thud(buffer, at, BOOTS_HZ, 0.18, 0.75, 20.0, 0.35)
	# El radio: ruido entrecortado, como una transmisión que no se entiende.
	var hiss: PackedFloat32Array = _low_passed_noise(buffer.size(), 0.35)
	var first: int = int(RADIO_START * SAMPLE_RATE)
	for i: int in int(RADIO_LENGTH * SAMPLE_RATE):
		var index: int = first + i
		if index >= buffer.size():
			break
		var t: float = float(i) / float(SAMPLE_RATE)
		# Se corta a trozos, como una radio con el dedo en el botón.
		var gate: float = 1.0 if fmod(t, 0.25) < 0.17 else 0.12
		buffer[index] += hiss[index] * gate * 0.3
	return _to_wav(buffer)


## Agua de lavabo: chorro continuo con borboteo.
static func far_water() -> AudioStreamWAV:
	var length: float = 4.0
	var buffer: PackedFloat32Array = _buffer(length + LOOP_CROSSFADE)
	var flow: PackedFloat32Array = _low_passed_noise(buffer.size(), 0.45)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		# El chorro no es parejo: le tiembla el caudal.
		var wobble: float = 0.75 + 0.25 * sin(TAU * 2.7 * t) * sin(TAU * 0.9 * t)
		buffer[i] = flow[i] * wobble * 0.6
	return _to_wav(_seamless(buffer, length))


## Tecleo: golpecitos secos y desiguales, en bucle.
static func far_keyboard() -> AudioStreamWAV:
	var length: float = 3.5
	var buffer: PackedFloat32Array = _buffer(length + LOOP_CROSSFADE)
	var at: float = 0.0
	while at < length + LOOP_CROSSFADE:
		_add_thud(buffer, at, randf_range(900.0, 1700.0), 0.03,
			randf_range(0.25, 0.5), 220.0, 0.85)
		at += randf_range(0.07, 0.22)
	return _to_wav(_seamless(buffer, length))


## Módem: el pitido de enlace y la cascada de ruido, mal sintonizado.
static func far_modem() -> AudioStreamWAV:
	var length: float = 2.6
	var buffer: PackedFloat32Array = _buffer(length)
	# Los dos tonos de negociación.
	_add_tone(buffer, 0.0, 1062.0, 0.6, 0.3)
	_add_tone(buffer, 0.7, 1800.0, 0.45, 0.28)
	_add_tone(buffer, 1.2, 2225.0, 0.3, 0.25)
	# Y el chorro de datos del final.
	var noise: PackedFloat32Array = _low_passed_noise(buffer.size(), 0.6)
	var first: int = int(1.5 * SAMPLE_RATE)
	for i: int in buffer.size() - first:
		var t: float = float(i) / float(SAMPLE_RATE)
		buffer[first + i] += noise[first + i] * exp(-t * 1.8) * 0.5
	return _to_wav(buffer)


## Zumbido eléctrico y, de vez en cuando, un trueno lejano. En bucle.
static func far_spark() -> AudioStreamWAV:
	var length: float = 5.0
	var buffer: PackedFloat32Array = _buffer(length + LOOP_CROSSFADE)
	for i: int in buffer.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		# 60 Hz y su armónico, que es a lo que suena un transformador.
		buffer[i] = (sin(TAU * 60.0 * t) * 0.5 + sin(TAU * 180.0 * t) * 0.2) * 0.35
	# El trueno: un golpe de ruido grave que rueda.
	var rumble: PackedFloat32Array = _low_passed_noise(buffer.size(), 0.02)
	var first: int = int(2.2 * SAMPLE_RATE)
	for i: int in buffer.size() - first:
		var t: float = float(i) / float(SAMPLE_RATE)
		buffer[first + i] += rumble[first + i] * exp(-t * 1.1) * minf(t * 6.0, 1.0) * 0.8
	return _to_wav(_seamless(buffer, length))


## Rechinido de silla: un chirrido que sube de tono y para en seco.
static func far_chair() -> AudioStreamWAV:
	var length: float = 0.8
	var samples: int = int(length * SAMPLE_RATE)
	var buffer: PackedFloat32Array = _buffer(length)
	var phase: float = 0.0
	for i: int in samples:
		var t: float = float(i) / float(samples)
		phase += TAU * lerpf(220.0, 520.0, t) / float(SAMPLE_RATE)
		# El chirrido raspa: onda sucia y con ruido encima.
		var envelope: float = sin(PI * t) * (0.6 + 0.4 * sin(TAU * 34.0 * t))
		buffer[i] = (sin(phase) * 0.5 + randf_range(-1.0, 1.0) * 0.5) * envelope * 0.5
	return _to_wav(buffer)


## Portazo: un golpe seco con cola de eco (el eco lo pone el bus).
static func far_door_slam() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(0.6)
	_add_thud(buffer, 0.0, 58.0, 0.5, 0.95, 14.0, 0.5)
	_add_bell(buffer, 0.0, 320.0, [1.0, 2.3] as Array[float], [1.0, 0.4] as Array[float],
		18.0, 0.5, 0.25)
	return _to_wav(buffer)


## Pasos en el piso de arriba: golpes sordos sobre la losa.
static func far_upstairs() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(2.6)
	var at: float = 0.0
	for i: int in 5:
		_add_thud(buffer, at, 52.0, 0.2, randf_range(0.5, 0.85), 18.0, 0.3)
		at += randf_range(0.42, 0.62)
	return _to_wav(buffer)


## Risa lejana: tres sílabas con el tono cayendo.
const LAUGH_AT: Array[float] = [0.0, 0.26, 0.52]
const LAUGH_HZ: Array[float] = [330.0, 300.0, 265.0]


static func far_laugh() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(1.1)
	for i: int in LAUGH_AT.size():
		_add_bell(buffer, LAUGH_AT[i], LAUGH_HZ[i],
			[1.0, 2.0, 3.0] as Array[float], [1.0, 0.5, 0.25] as Array[float],
			11.0, 0.3, 0.45)
	return _to_wav(buffer)


## Platos en la cafetería: tintineos agudos, unos cuantos y desordenados.
static func far_dishes() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(1.4)
	for i: int in 7:
		_add_bell(buffer, randf_range(0.0, 1.0), randf_range(1400.0, 2600.0),
			[1.0, 2.6] as Array[float], [1.0, 0.45] as Array[float],
			26.0, 0.35, randf_range(0.2, 0.4))
	return _to_wav(buffer)


# --- El golpe de WASTED ------------------------------------------------------
## Un acorde grave que cae y se queda sonando: el "se acabó". Sin voz.
const WASTED_LENGTH: float = 2.6
## Tres notas de un acorde menor, bien abajo.
const WASTED_HZ: Array[float] = [55.0, 65.4, 82.4]
const WASTED_DECAY: float = 1.1
const WASTED_AMPLITUDE: float = 0.55
## El golpe seco del principio, antes del acorde.
const WASTED_HIT_HZ: float = 44.0


static func wasted_sting() -> AudioStreamWAV:
	var buffer: PackedFloat32Array = _buffer(WASTED_LENGTH)
	_add_thud(buffer, 0.0, WASTED_HIT_HZ, 0.9, 0.9, 5.0, 0.25)
	for hz: float in WASTED_HZ:
		_add_bell(buffer, 0.02, hz, [1.0, 2.0, 3.0] as Array[float],
			[1.0, 0.35, 0.15] as Array[float], WASTED_DECAY, WASTED_LENGTH,
			WASTED_AMPLITUDE / float(WASTED_HZ.size()))
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


## Ruido pasado por un filtro de un polo: cuanto más chico el corte, más grave.
static func _low_passed_noise(samples: int, cutoff: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(samples)
	var value: float = 0.0
	for i: int in samples:
		value += (randf_range(-1.0, 1.0) - value) * cutoff
		out[i] = value
	# El filtro deja la señal muy baja: se renormaliza para no perderla.
	var peak: float = 0.0
	for sample: float in out:
		peak = maxf(peak, absf(sample))
	if peak > 0.0:
		for i: int in samples:
			out[i] /= peak
	return out


## Convierte un buffer largo en un bucle que empalma: la cola de más allá del
## final se mezcla encima del principio, así el corte no suena a clic.
static func _seamless(buffer: PackedFloat32Array, length: float) -> PackedFloat32Array:
	var keep: int = int(length * SAMPLE_RATE)
	var tail: int = buffer.size() - keep
	if tail <= 0:
		return buffer
	var out: PackedFloat32Array = buffer.slice(0, keep)
	for i: int in tail:
		var fade: float = float(i) / float(tail)
		out[i] = out[i] * fade + buffer[keep + i] * (1.0 - fade)
	return out

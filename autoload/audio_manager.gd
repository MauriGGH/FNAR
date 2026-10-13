extends Node

## Autoload. El único que toca audio en todo el juego: se le pide un sonido por
## su id del catálogo (data/sounds.gd) y él se encarga del archivo, del bus y
## del volumen.
##
## Si el archivo de verdad no está en assets/audio/, usa el provisional que
## genera ToneBuilder y lo avisa una vez en consola, para que la lista de lo que
## falta esté a la vista sin llenar la salida de repeticiones.
##
## Cada id tiene su propio reproductor, así que parar la cajita musical no corta
## el grito. Los reproductores se crean la primera vez que se pide el sonido.

## Cambió el volumen de un bus. Lo escucha el menú de opciones.
signal bus_volume_changed(bus: String, value: float)
## Se acabó un sonido de los de una sola vez (los bucles no terminan solos). Es
## lo que encadena las secuencias, y lo puede escuchar quien quiera.
signal sound_finished(id: String)

## Lo más bajo que llega el deslizador antes de callar del todo.
const MIN_DB: float = -40.0

## Lo bajo que queda un sonido al final de un fundido, antes de pararlo.
const FADE_SILENCE_DB: float = -60.0

var _players: Dictionary = {}      # id -> AudioStreamPlayer
var _streams: Dictionary = {}      # id -> AudioStream
var _warned: Dictionary = {}       # id -> true, para avisar una sola vez
var _fades: Dictionary = {}        # id -> Tween del fundido que esté corriendo
## Los bucles que se pidieron y todavía no se han parado. Se lleva aparte de
## _players porque un bucle que se queda colgado de una escena a la siguiente
## es lo que arruina el ambiente: hay que poder callarlos todos de golpe sin
## cortar los sonidos de una sola vez (un grito, un golpe) que estén en el aire.
var _loops: Dictionary = {}        # id -> true mientras ese bucle esté puesto
## Lo que espera su turno en cada secuencia: nombre -> [{id, from}]. Dos
## efectos de la misma secuencia **nunca** suenan a la vez: el siguiente entra
## cuando el anterior acaba de verdad.
var _queued: Dictionary = {}
## Lo que hay que llamar cuando termine un sonido: id -> Callable. Así la
## imagen se encadena con el sonido y no con un tiempo apuntado a mano.
var _after: Dictionary = {}


func _ready() -> void:
	# Tiene que seguir sonando con el árbol pausado (el menú de pruebas, la pausa).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: String in Sounds.MIXER_BUSES:
		_apply_bus_volume(bus, SaveGame.bus_volume(bus))


# --- Reproducción ------------------------------------------------------------

## Suena desde el principio. Si ya estaba sonando, se reinicia.
func play(id: String) -> void:
	var player: AudioStreamPlayer = _player_for(id)
	if player == null:
		return
	_stop_fade(id)
	player.stream_paused = false
	player.volume_db = Sounds.volume_db(id)
	_apply_pan(id)
	player.play()


# --- Secuencias ---------------------------------------------------------------

## Arranca una secuencia (un susto, un rescate, una irrupción): calla lo que
## quede sonando de ella y tira su cola. Un susto nuevo no se mezcla con los
## restos del anterior.
func begin_sequence(sequence: String) -> void:
	_queued.erase(sequence)
	for id: String in Sounds.sequence_ids(sequence):
		_after.erase(id)
		if is_playing(id):
			stop(id)


## Suena dentro de una secuencia. Si hay otro de la misma en el aire, este
## **espera su turno** y entra en cuanto el otro termine; si no, suena ya.
## `then` se llama al acabar este, para encadenar lo que venga después.
func play_in_sequence(sequence: String, id: String, then: Callable = Callable(),
		from_position: float = 0.0) -> void:
	if then.is_valid():
		_after[id] = then
	else:
		_after.erase(id)
	if _sequence_playing(sequence).is_empty():
		_play_entry(id, from_position)
		return
	if not _queued.has(sequence):
		_queued[sequence] = []
	(_queued[sequence] as Array).append({"id": id, "from": from_position})


## ¿Sigue sonando, o esperando, algo de esta secuencia? Lo pregunta quien tiene
## que aguantar una imagen hasta que el audio acabe.
func sequence_busy(sequence: String) -> bool:
	return not _sequence_playing(sequence).is_empty() or _queued.has(sequence)


## Cuál de los sonidos de la secuencia está sonando ahora, si alguno.
func _sequence_playing(sequence: String) -> String:
	for id: String in Sounds.sequence_ids(sequence):
		if is_playing(id):
			return id
	return ""


## Suelta el siguiente de la cola, si queda alguno.
func _advance_sequence(sequence: String) -> void:
	if sequence.is_empty() or not _queued.has(sequence):
		return
	var queue: Array = _queued[sequence] as Array
	if queue.is_empty():
		_queued.erase(sequence)
		return
	var entry: Dictionary = queue.pop_front()
	if queue.is_empty():
		_queued.erase(sequence)
	_play_entry(str(entry["id"]), float(entry["from"]))


## Un sonido de la cola. Si ni archivo ni provisional existen no se puede
## esperar su final, así que lo que venía detrás se llama de inmediato.
func _play_entry(id: String, from_position: float) -> void:
	if _player_for(id) == null:
		_run_after.call_deferred(id)
		return
	if from_position > 0.0:
		play_from(id, from_position)
	else:
		play(id)


## Se acabó un sonido: lo que esperaba por él se entera.
func _on_player_finished(id: String) -> void:
	_run_after(id)
	sound_finished.emit(id)
	_advance_sequence(Sounds.sequence_of(id))


func _run_after(id: String) -> void:
	var callback: Callable = _after.get(id, Callable()) as Callable
	_after.erase(id)
	if callback.is_valid():
		callback.call()


## Suena desde ese segundo, no desde el principio. Lo usa el apagón, que no
## toca la canción entera sino un tramo de en medio.
func play_from(id: String, from_position: float) -> void:
	var player: AudioStreamPlayer = _player_for(id)
	if player == null:
		return
	_stop_fade(id)
	player.volume_db = Sounds.volume_db(id)
	_apply_pan(id)
	player.play(maxf(from_position, 0.0))


## Lo baja a nada en estos segundos y lo para. Al acabar lo deja a su volumen
## de catálogo otra vez, para que la próxima vez suene normal.
func fade_out(id: String, seconds: float) -> void:
	var player: AudioStreamPlayer = _players.get(id, null) as AudioStreamPlayer
	if player == null or not player.playing:
		return
	_stop_fade(id)
	var tween: Tween = create_tween()
	_fades[id] = tween
	tween.tween_property(player, "volume_db", FADE_SILENCE_DB, maxf(seconds, 0.01))
	tween.tween_callback(_end_fade.bind(id))


## Corta el fundido que estuviera corriendo, sin tocar el volumen.
func _stop_fade(id: String) -> void:
	var tween: Tween = _fades.get(id, null) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_fades.erase(id)


## El fundido llegó al final: parar y dejar el volumen como estaba.
func _end_fade(id: String) -> void:
	_fades.erase(id)
	stop(id)


## Como play_loop, pero entrando con un fundido y, si se le pide, desde un
## segundo concreto. Lo usa la música del menú: al volver de Extras retoma
## donde iba en vez de empezar otra vez.
func play_loop_faded(id: String, seconds: float, from_position: float = 0.0) -> void:
	var player: AudioStreamPlayer = _player_for(id)
	if player == null:
		return
	_stop_fade(id)
	_loops[id] = true
	player.stream_paused = false
	_apply_pan(id)
	player.play(maxf(from_position, 0.0))
	player.volume_db = FADE_SILENCE_DB
	var tween: Tween = create_tween()
	_fades[id] = tween
	tween.tween_property(player, "volume_db", Sounds.volume_db(id),
		maxf(seconds, 0.01))
	# Un fundido de entrada no para nada al acabar: solo deja de estar en curso.
	tween.tween_callback(_stop_fade.bind(id))


## Congela todo lo que esté sonando menos los ids que se le digan, **sin perder
## la posición**: al soltarlo, cada cosa sigue donde iba. Lo usa el evento de
## Momo, que para el juego entero y deja solo su canción.
func set_paused_except(keep: Array[String], paused: bool) -> void:
	for id: Variant in _players:
		var player: AudioStreamPlayer = _players[id] as AudioStreamPlayer
		if player == null:
			continue
		player.stream_paused = paused and not (str(id) in keep)


## Suena en bucle. Si ya estaba sonando, lo deja seguir para que no se reinicie
## a cada rato. Queda apuntado en el registro hasta que alguien lo pare.
func play_loop(id: String) -> void:
	var player: AudioStreamPlayer = _player_for(id)
	if player == null:
		return
	_loops[id] = true
	if player.playing:
		return
	_apply_pan(id)
	player.play()


## Los sonidos lejanos vienen de un lado o del otro. Un AudioStreamPlayer no
## tiene paneo propio, así que se mueve el del bus Lejos justo antes de
## soltarlos. Si dos lejanos de lados opuestos se pisan, manda el último; como
## son cosas sueltas y espaciadas, en la práctica no se nota.
func _apply_pan(id: String) -> void:
	if not Sounds.is_distant(id):
		return
	var index: int = AudioServer.get_bus_index(Sounds.BUS_DISTANT)
	if index < 0:
		return
	for slot: int in AudioServer.get_bus_effect_count(index):
		var panner: AudioEffectPanner = AudioServer.get_bus_effect(index, slot) as AudioEffectPanner
		if panner != null:
			panner.pan = Sounds.pan_of(id)
			return


func stop(id: String) -> void:
	_stop_fade(id)
	_loops.erase(id)
	# Cortarlo a mano no dispara su `finished`, así que lo que esperaba detrás
	# se descarta: si no, se quedaría colgado para siempre.
	_after.erase(id)
	var player: AudioStreamPlayer = _players.get(id, null) as AudioStreamPlayer
	if player == null:
		return
	if player.playing:
		player.stop()
	player.stream_paused = false
	# Si venía de un fundido, su volumen quedó por el suelo: se devuelve al del
	# catálogo para que la próxima vez no suene callado.
	player.volume_db = Sounds.volume_db(id)
	_advance_sequence(Sounds.sequence_of(id))


## El tono de un sonido: 1.0 es el normal, menos es más grave y más lento. Lo
## usa la cajita de la botarga, que se va apagando conforme se queda sin cuerda.
func set_pitch(id: String, pitch: float) -> void:
	var player: AudioStreamPlayer = _player_for(id)
	if player != null:
		player.pitch_scale = maxf(pitch, 0.01)


func is_playing(id: String) -> bool:
	var player: AudioStreamPlayer = _players.get(id, null) as AudioStreamPlayer
	return player != null and player.playing


## Calla todo. Lo usan los cambios de pantalla, para que nada se arrastre de una
## escena a la siguiente.
func stop_all() -> void:
	# Las colas se tiran primero: si no, cada stop() soltaría el siguiente de
	# su secuencia y el sonido se colaría en la pantalla nueva.
	_queued.clear()
	_after.clear()
	for id: Variant in _players:
		stop(str(id))


## Calla **solo los bucles**: el ambiente, la estática, la cajita, los lejanos
## de sitio, el glitch de Armando, la carrera de Barcosa, la música del menú...
## Lo llama cada pantalla al montarse, porque un bucle colgado de la pantalla
## anterior es lo que traba el ambiente y se oye encima del nuevo. Los sonidos
## de una sola vez no se tocan: un grito o un golpe en el aire se acaban solos.
func stop_all_loops() -> void:
	for id: Variant in _loops.keys():
		stop(str(id))
	_loops.clear()


## Los ids que están sonando ahora mismo, en orden, para los registros del
## panel de pruebas. Marca con * los que son bucles.
func active_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for id: Variant in _players:
		var player: AudioStreamPlayer = _players[id] as AudioStreamPlayer
		if player != null and player.playing:
			ids.append("%s%s" % [str(id), "*" if _loops.has(id) else ""])
	ids.sort()
	return ids


## true si el archivo de verdad ya está en assets/audio/. Lo pregunta quien
## tiene un plan B que no es un provisional por código: el botón de Rochis usa
## la síntesis de voz mientras no esté grabada la suya.
func has_real_file(id: String) -> bool:
	var path: String = Sounds.file_path(id)
	return not path.is_empty() and ResourceLoader.exists(path)


## Por dónde va la reproducción, en segundos. Los subtítulos de las llamadas se
## cuelgan de esto y no de un contador propio: así no se desfasan aunque el
## juego dé un tirón.
func playback_position(id: String) -> float:
	var player: AudioStreamPlayer = _players.get(id, null) as AudioStreamPlayer
	return 0.0 if player == null else player.get_playback_position()


## Lo que dura un sonido, en segundos. Hace falta para encadenar cosas con él
## (hablar después del tono de ocupado, saltar después de los pasos).
func length(id: String) -> float:
	var stream: AudioStream = _stream_for(id)
	return 0.0 if stream == null else stream.get_length()


# --- Mezcla ------------------------------------------------------------------

## El volumen de un bus, de 0 a 1.
func bus_volume(bus: String) -> float:
	return SaveGame.bus_volume(bus)


## Lo cambia y lo guarda.
func set_bus_volume(bus: String, value: float) -> void:
	var clamped: float = clampf(value, 0.0, 1.0)
	_apply_bus_volume(bus, clamped)
	SaveGame.set_bus_volume(bus, clamped)
	bus_volume_changed.emit(bus, clamped)


## El volumen de las voces, de 0 a 1. El TTS no pasa por los buses de audio, así
## que quien habla tiene que multiplicar su volumen por esto a mano.
func voice_volume() -> float:
	return bus_volume(Sounds.BUS_VOICES) * bus_volume(Sounds.BUS_MASTER)


func _apply_bus_volume(bus: String, value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, is_zero_approx(value))
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))


# --- Carga -------------------------------------------------------------------

func _player_for(id: String) -> AudioStreamPlayer:
	if _players.has(id):
		return _players[id] as AudioStreamPlayer
	var stream: AudioStream = _stream_for(id)
	if stream == null:
		return null
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = "Player_" + id
	player.stream = stream
	player.bus = Sounds.bus_of(id)
	player.volume_db = Sounds.volume_db(id)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.finished.connect(_on_player_finished.bind(id))
	add_child(player)
	_players[id] = player
	return player


## El archivo de verdad si está; si no, el provisional. Se queda en caché.
func _stream_for(id: String) -> AudioStream:
	if _streams.has(id):
		return _streams[id] as AudioStream
	var stream: AudioStream = _load_real(id)
	if stream == null:
		stream = _build_placeholder(id)
	if stream != null:
		_set_looping(stream, Sounds.is_looping(id))
	_streams[id] = stream
	return stream


func _load_real(id: String) -> AudioStream:
	var path: String = Sounds.file_path(id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded: AudioStream = load(path) as AudioStream
	# Una copia propia: marcar el bucle no debe tocar el recurso en caché.
	return null if loaded == null else loaded.duplicate() as AudioStream


## El provisional de ToneBuilder, avisando una sola vez de que falta el archivo.
func _build_placeholder(id: String) -> AudioStream:
	var generator: String = Sounds.generator_of(id)
	if generator.is_empty():
		_warn_once(id, "sin sonido ni provisional")
		return null
	var built: AudioStreamWAV = ToneBuilder.build(generator)
	if built == null:
		_warn_once(id, "el provisional «%s» no existe en ToneBuilder" % generator)
		return null
	_warn_once(id, "falta %s, suena el provisional" % Sounds.file_name(id))
	return built


func _warn_once(id: String, message: String) -> void:
	if _warned.has(id):
		return
	_warned[id] = true
	print("[audio] %s: %s" % [id, message])


## El bucle se marca distinto según de dónde venga el audio.
func _set_looping(stream: AudioStream, looping: bool) -> void:
	var wav: AudioStreamWAV = stream as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
		wav.loop_begin = 0
		# OJO: loop_end tiene que ser el final de verdad. Dejarlo en 0 no
		# significa "hasta el final": significa un bucle de largo cero, y el
		# sonido se corta al instante en vez de repetirse.
		wav.loop_end = _frame_count(wav) if looping else 0
		return
	var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = looping
		return
	var mp3: AudioStreamMP3 = stream as AudioStreamMP3
	if mp3 != null:
		mp3.loop = looping


## Cuántas muestras tiene un wav, contando el formato y los canales.
func _frame_count(wav: AudioStreamWAV) -> int:
	var bytes_per_sample: int = 2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1
	var channels: int = 2 if wav.stereo else 1
	return wav.data.size() / (bytes_per_sample * channels)

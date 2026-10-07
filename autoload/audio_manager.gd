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

## Lo más bajo que llega el deslizador antes de callar del todo.
const MIN_DB: float = -40.0

var _players: Dictionary = {}      # id -> AudioStreamPlayer
var _streams: Dictionary = {}      # id -> AudioStream
var _warned: Dictionary = {}       # id -> true, para avisar una sola vez


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
	player.play()


## Suena en bucle. Si ya estaba sonando, lo deja seguir para que no se reinicie
## a cada rato.
func play_loop(id: String) -> void:
	var player: AudioStreamPlayer = _player_for(id)
	if player == null or player.playing:
		return
	player.play()


func stop(id: String) -> void:
	var player: AudioStreamPlayer = _players.get(id, null) as AudioStreamPlayer
	if player != null and player.playing:
		player.stop()


func is_playing(id: String) -> bool:
	var player: AudioStreamPlayer = _players.get(id, null) as AudioStreamPlayer
	return player != null and player.playing


## Calla todo. Lo usan los cambios de pantalla, para que nada se arrastre de una
## escena a la siguiente.
func stop_all() -> void:
	for id: Variant in _players:
		stop(str(id))


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
		wav.loop_end = 0
		return
	var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = looping
		return
	var mp3: AudioStreamMP3 = stream as AudioStreamMP3
	if mp3 != null:
		mp3.loop = looping

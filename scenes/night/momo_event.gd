class_name MomoEvent
extends Control

## El susto de Momo, de principio a fin. Esta capa lleva lo que va a pantalla
## completa —el parpadeo de luz, el screamer y el corte a negro— y le pide a la
## oficina lo que pasa dentro de su vista izquierda: la foto tomada y el zoom
## lentísimo hacia él.
##
## Los tiempos salen de la canción (`momo_cancion`, 15.3 s): el screamer entra
## en su segundo 12.10 y el susto acaba cuando acaba el audio. Si el archivo
## faltara, se usa `Momo.FALLBACK_TIME`.
##
## El que para el juego es el `night.gd`: esta capa solo avisa de cuándo empieza
## y de cuándo termina.

## Ya pasó el parpadeo: que la oficina ponga la foto de Momo.
signal view_requested()
## Lo acercada que va la vista, de ZOOM_FROM a ZOOM_TO.
signal zoom_changed(amount: float)
## Se acabó: el juego sigue donde estaba.
signal finished()

enum Phase { IDLE, FLICKER, SONG, SCREAM, BLACK }

var is_playing: bool = false

var _phase: Phase = Phase.IDLE
## Lo que lleva la fase de ahora y, aparte, lo que lleva la canción.
var _left: float = 0.0
var _song: float = 0.0
var _total: float = Momo.FALLBACK_TIME
## Los cortes de luz que faltan y si ahora mismo está a oscuras.
var _cuts_left: int = 0
var _is_dark: bool = false
## Lo que lleva el screamer en pantalla, para su crecida.
var _scream_elapsed: float = 0.0
var _screamer: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	set_process(false)


## Arranca el susto. Lo llama el night.gd cuando el dado le sale.
func play() -> void:
	if is_playing:
		return
	is_playing = true
	visible = true
	_screamer = Momo.texture(Momo.SCREAMER_IMAGE)
	var length: float = AudioManager.length(Sounds.MOMO_SONG)
	_total = length if length > 0.0 else Momo.FALLBACK_TIME
	_song = 0.0
	_scream_elapsed = 0.0
	# El parpadeo de luz de la entrada: dos o tres cortes rápidos.
	_cuts_left = randi_range(Momo.FLICKER_CUTS.x, Momo.FLICKER_CUTS.y) * 2
	_phase = Phase.FLICKER
	_left = Momo.FLICKER_CUT_TIME
	_is_dark = true
	set_process(true)
	queue_redraw()


## Corta el susto donde esté, sin avisar. Para el panel de pruebas.
func stop_now() -> void:
	if is_playing:
		_stop()


func _process(delta: float) -> void:
	if not is_playing:
		return
	_left -= delta
	match _phase:
		Phase.FLICKER:
			_tick_flicker()
		Phase.SONG:
			_tick_song(delta)
		Phase.SCREAM:
			_tick_scream(delta)
		Phase.BLACK:
			if _left <= 0.0:
				_stop()
		Phase.IDLE:
			set_process(false)
	queue_redraw()


## Los cortes de luz. En el último, ya a oscuras, se cambia la foto de la
## vista: así el cambio no se ve, solo el resultado.
func _tick_flicker() -> void:
	if _left > 0.0:
		return
	_cuts_left -= 1
	_left = Momo.FLICKER_CUT_TIME
	_is_dark = not _is_dark
	if _cuts_left == 1:
		view_requested.emit()
	if _cuts_left > 0:
		return
	_is_dark = false
	_phase = Phase.SONG
	_left = 0.0
	AudioManager.begin_sequence(Sounds.SEQ_MOMO)
	AudioManager.play_in_sequence(Sounds.SEQ_MOMO, Sounds.MOMO_SONG)


## Mientras suena: la vista se va acercando a Momo, muy despacio.
func _tick_song(delta: float) -> void:
	_song += delta
	zoom_changed.emit(lerpf(Momo.ZOOM_FROM, Momo.ZOOM_TO,
		clampf(_song / _total, 0.0, 1.0)))
	if _song >= Momo.SCREAMER_AT:
		_phase = Phase.SCREAM
		_scream_elapsed = 0.0


## El screamer: crece de golpe y se queda temblando y parpadeando hasta que la
## canción se acaba.
func _tick_scream(delta: float) -> void:
	_song += delta
	_scream_elapsed += delta
	zoom_changed.emit(lerpf(Momo.ZOOM_FROM, Momo.ZOOM_TO,
		clampf(_song / _total, 0.0, 1.0)))
	if _song >= _total:
		_phase = Phase.BLACK
		_left = Momo.BLACK_TIME
		_is_dark = true


func _stop() -> void:
	is_playing = false
	visible = false
	_phase = Phase.IDLE
	_is_dark = false
	set_process(false)
	AudioManager.begin_sequence(Sounds.SEQ_MOMO)
	finished.emit()


func _draw() -> void:
	if _phase == Phase.SCREAM:
		_draw_screamer()
		return
	# El negro del parpadeo y el del final son el mismo.
	if _is_dark:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0))


## El screamer, centrado, creciendo del 60 % al 120 % del alto de la pantalla,
## temblando fuerte y parpadeando.
func _draw_screamer() -> void:
	if _screamer == null:
		return
	var grow: float = clampf(_scream_elapsed / Momo.SCREAMER_GROW_TIME, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - grow, 3.0)
	var height: float = size.y * lerpf(Momo.SCREAMER_FROM, Momo.SCREAMER_TO, eased)
	var width: float = height * float(_screamer.get_width()) \
		/ float(_screamer.get_height())
	var shake: float = Momo.SCREAMER_SHAKE_PIXELS * size.y / Momo.REFERENCE_HEIGHT
	var wave: float = sin(_scream_elapsed * TAU * Momo.SCREAMER_SHAKE_HZ)
	var center: Vector2 = size * 0.5 + Vector2(wave, -wave * 0.6) * shake
	# El parpadeo: nunca se va del todo, solo baja de golpe.
	var blink: float = 1.0 - Momo.SCREAMER_BLINK_DEPTH * (0.5 + 0.5
		* sin(_scream_elapsed * TAU * Momo.SCREAMER_BLINK_HZ))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0))
	draw_texture_rect(_screamer,
		Rect2(center - Vector2(width, height) * 0.5, Vector2(width, height)),
		false, Color(1.0, 1.0, 1.0, blink))

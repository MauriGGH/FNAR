extends Control

## La muerte por apagón. Cuando la energía llega a 0 todo se apaga y el jugador
## se queda a oscuras. Entre 3 y 12 s después aparecen dos chispas azules a lo
## lejos, que parpadean al ritmo de la cajita musical: una por nota. Cuando la
## melodía acaba, las chispas se apagan y hay silencio total entre 2 y 5 s. Luego
## se oyen tres pasos que se acercan, y de ahí viene el salto del Mago Eléctrico.
##
## Pasa en todas las noches, aunque el Mago esté en nivel 0: el apagón es suyo.
## Y si dan las 6 AM en cualquier momento de la secuencia, el jugador se salva.

## Llegó el momento del salto.
signal strike()
## Ya se ven las chispas. Lo usa la noche para apagar lo que siguiera sonando.
signal sparks_started()

enum Phase { IDLE, WAITING, SPARKS, SILENCE, STEPS }

const MIN_WAIT: float = 3.0
const MAX_WAIT: float = 12.0
## El silencio total después de la melodía, antes de los pasos.
const MIN_SILENCE: float = 2.0
const MAX_SILENCE: float = 5.0

## Las dos chispas, en posición normalizada de la pantalla.
const SPARK_SPOTS: Array[Vector2] = [Vector2(0.39, 0.46), Vector2(0.58, 0.44)]
const SPARK_COLOR: Color = Color(0.45, 0.72, 1.0)
const SPARK_RADIUS: float = 7.0
## Lo que se queda encendida la chispa en cada nota.
const SPARK_ON_TIME: float = 0.18

var is_running: bool = false
var is_showing_sparks: bool = false

var _phase: Phase = Phase.IDLE
var _left: float = 0.0
## Cuánto llevamos dentro de la fase de las chispas, para ir casando las notas.
var _sparks_elapsed: float = 0.0
## En qué segundo entra cada nota de la melodía. Son los tiempos del provisional
## de ToneBuilder; si algún día entra un archivo de verdad con otro compás, hay
## que medirlo y ajustarlo aquí.
var _note_times: PackedFloat32Array = PackedFloat32Array()
var _melody_length: float = 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_times = ToneBuilder.music_box_note_times()
	_melody_length = ToneBuilder.music_box_length()


## Empieza la cuenta a oscuras. El tiempo es al azar para que no se aprenda.
func start() -> void:
	if is_running:
		return
	is_running = true
	is_showing_sparks = false
	_phase = Phase.WAITING
	_left = randf_range(MIN_WAIT, MAX_WAIT)
	_sparks_elapsed = 0.0
	visible = true
	queue_redraw()


## Se corta: dieron las 6 AM y el jugador se salvó. Puede pasar en cualquier
## fase, también con la melodía ya sonando.
func cancel() -> void:
	if is_running:
		AudioManager.stop(Sounds.MUSIC_BOX_BLACKOUT)
		AudioManager.stop(Sounds.FOOTSTEPS)
	is_running = false
	is_showing_sparks = false
	_phase = Phase.IDLE
	visible = false


func _process(delta: float) -> void:
	if not is_running:
		return
	_left -= delta
	match _phase:
		Phase.WAITING:
			if _left <= 0.0:
				_begin_sparks()
		Phase.SPARKS:
			_sparks_elapsed += delta
			queue_redraw()
			if _left <= 0.0:
				_begin_silence()
		Phase.SILENCE:
			if _left <= 0.0:
				_begin_steps()
		Phase.STEPS:
			if _left <= 0.0:
				_fire()
		Phase.IDLE:
			pass


## Las chispas y la melodía, juntas y desde el principio de las dos.
func _begin_sparks() -> void:
	_phase = Phase.SPARKS
	is_showing_sparks = true
	_sparks_elapsed = 0.0
	_left = _melody_length
	# La cajita de la botarga se calla: a oscuras solo se oye esta.
	AudioManager.stop(Sounds.MUSIC_BOX)
	AudioManager.play(Sounds.MUSIC_BOX_BLACKOUT)
	sparks_started.emit()
	queue_redraw()


## Silencio de verdad: ni chispas ni música.
func _begin_silence() -> void:
	_phase = Phase.SILENCE
	is_showing_sparks = false
	_left = randf_range(MIN_SILENCE, MAX_SILENCE)
	AudioManager.stop(Sounds.MUSIC_BOX_BLACKOUT)
	queue_redraw()


## Los tres pasos acercándose. El salto cae justo cuando se acaban.
func _begin_steps() -> void:
	_phase = Phase.STEPS
	_left = ToneBuilder.footsteps_length()
	AudioManager.play(Sounds.FOOTSTEPS)


func _fire() -> void:
	is_running = false
	is_showing_sparks = false
	_phase = Phase.IDLE
	visible = false
	strike.emit()


## Las chispas están encendidas si estamos dentro de la ventana de una nota.
func _is_lit() -> bool:
	for time: float in _note_times:
		if _sparks_elapsed >= time and _sparks_elapsed < time + SPARK_ON_TIME:
			return true
	return false


func _draw() -> void:
	if not is_showing_sparks or not _is_lit():
		return
	for spot: Vector2 in SPARK_SPOTS:
		DrawKit.glow(self, spot * size, SPARK_RADIUS, SPARK_COLOR, 1.0)
		draw_circle(spot * size, SPARK_RADIUS * 0.45, Color(0.85, 0.94, 1.0, 0.9))


# --- Depuración ---------------------------------------------------------------

## Para el menú de pruebas: salta la espera a oscuras y arranca con las chispas.
func debug_skip_to_sparks() -> void:
	if not is_running:
		start()
	if _phase == Phase.WAITING:
		_begin_sparks()


## En qué va la secuencia, para enseñarlo en el panel.
func phase_text() -> String:
	match _phase:
		Phase.WAITING:
			return "a oscuras (%.1f s)" % _left
		Phase.SPARKS:
			return "chispas con la melodía (%.1f s)" % _left
		Phase.SILENCE:
			return "silencio (%.1f s)" % _left
		Phase.STEPS:
			return "pasos acercándose (%.1f s)" % _left
	return "parado"

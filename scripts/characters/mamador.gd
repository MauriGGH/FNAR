class_name Mamador
extends Animatronic

## Mamador (rol Freddy). Sale de la sala de juntas y baja por el pasillo hasta
## el cristal de la oficina. Al llegar revisa solo dos cosas, la ventana de
## Claudio y la puerta cerrada, y las revisa durante los 4 s que se queda ahí.
## Ignora la linterna, el breaker y las cámaras: vigilarlo no lo frena.
## Reserva el pasillo antes de entrar al pasillo norte, así que mientras él
## está ahí Barcosa espera, y al revés.

enum State {
	WALKING,     # Avanzando por su ruta
	INSPECTING,  # Parado en el cristal, revisando
}

const ROUTE: Array[String] = ["sala_juntas", "pasillo_norte", "pasillo_sur"]
const STEP_SALA_JUNTAS: int = 0
const STEP_PASILLO_NORTE: int = 1
const STEP_PASILLO_SUR: int = 2

## Cada cuánto tira el dado para dar un paso.
const MOVE_INTERVAL: float = 6.0
## Lo que se queda inspeccionando desde el cristal.
const INSPECT_TIME: float = 4.0

const GAME_OVER_CAUSE: String = "Delito federal"
const HALLWAY_NOTICE: String = "[pasos lentos y llavero]"
const PHRASE_NOTICE: String = "[Mamador: ¡delito federal!]"
const NOTICE_TIME: float = 2.5
const WINDOW_PRESENCE: String = "Mamador mirando por el cristal"

var _state: State = State.WALKING
var _inspect_elapsed: float = 0.0


func ai_key() -> String:
	return Nights.MAMADOR


func start() -> void:
	ai_level = night_ai_level()
	move_interval = MOVE_INTERVAL
	route = PackedStringArray(ROUTE)
	super()
	_state = State.WALKING
	_inspect_elapsed = 0.0


func _process(delta: float) -> void:
	if not is_active:
		return
	match _state:
		State.WALKING:
			super(delta)  # El dado de la IA de la clase base
		State.INSPECTING:
			_process_inspecting(delta)


## Le ganó el dado: da un paso. El pasillo lo tiene que reservar antes de
## entrar, y lo suelta al irse.
func advance() -> void:
	var next_step: int = _route_index + 1
	if next_step > STEP_PASILLO_SUR:
		return
	if next_step == STEP_PASILLO_NORTE and not GameManager.reserve_hallway(self):
		return  # Lo tiene Barcosa: espera en la sala de juntas.

	move_to_step(next_step)
	if next_step == STEP_PASILLO_NORTE:
		made_noise.emit(HALLWAY_NOTICE, NOTICE_TIME)
	elif next_step == STEP_PASILLO_SUR:
		_state = State.INSPECTING
		_inspect_elapsed = 0.0


## Mientras está en el cristal revisa todo el tiempo, no solo al llegar.
func _process_inspecting(delta: float) -> void:
	if GameManager.is_ai_window_open or door_closed:
		stop()
		GameManager.release_hallway(self)
		GameManager.trigger_game_over(GAME_OVER_CAUSE)
		return
	_inspect_elapsed += delta
	if _inspect_elapsed >= INSPECT_TIME:
		_leave()


## No encontró nada: dice su frase, se va y deja el pasillo libre.
func _leave() -> void:
	made_noise.emit(PHRASE_NOTICE, NOTICE_TIME)
	GameManager.release_hallway(self)
	_state = State.WALKING
	move_to_step(STEP_SALA_JUNTAS)


func zone_presence(zone_id: String) -> String:
	if zone_id == "front_glass" and _state == State.INSPECTING:
		return WINDOW_PRESENCE
	return ""


func debug_text() -> String:
	if _state == State.INSPECTING:
		return "en el cristal, revisando (%.1f s)" % maxf(INSPECT_TIME - _inspect_elapsed, 0.0)
	var text: String = "en %s" % Rooms.display_name(current_room)
	if _route_index == STEP_SALA_JUNTAS and not GameManager.is_hallway_free():
		text += ", esperando el pasillo"
	return text


## F6: lo manda directo al pasillo norte, el paso antes del cristal.
func debug_force_to_stairs() -> void:
	debug_activate()
	if _state != State.WALKING:
		return
	if not GameManager.reserve_hallway(self):
		return
	move_to_step(STEP_PASILLO_NORTE)
	made_noise.emit(HALLWAY_NOTICE, NOTICE_TIME)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F6:
		debug_force_to_stairs()

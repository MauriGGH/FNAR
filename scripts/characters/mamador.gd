class_name Mamador
extends Animatronic

## Mamador (rol Freddy). Sube despacio desde el estacionamiento hasta el cristal
## de la oficina. Al llegar revisa solo dos cosas, la ventana de la IA y la
## puerta cerrada, y las revisa durante los 4 s que se queda ahí.
## Ignora la linterna, el breaker y las cámaras: vigilarlo no lo frena.

enum State {
	WALKING,     # Avanzando por su ruta
	INSPECTING,  # Parado en el cristal, revisando
}

## Nivel de IA mientras no exista la configuración por noche (hito 6).
## Para probar: 10. El nivel real de la noche 1 es 3.
const DEBUG_AI_LEVEL: int = 10

const ROUTE: Array[String] = ["estacionamiento", "cafeteria", "escalera_pb", "pasillo_sur"]
const STEP_ESTACIONAMIENTO: int = 0
const STEP_CAFETERIA: int = 1
const STEP_ESCALERA_PB: int = 2
const STEP_PASILLO_SUR: int = 3

## Cada cuánto tira el dado para dar un paso.
const MOVE_INTERVAL: float = 6.0
## Lo que se queda inspeccionando desde el cristal.
const INSPECT_TIME: float = 4.0

const GAME_OVER_CAUSE: String = "Delito federal"
const STAIRS_NOTICE: String = "[pasos lentos y llavero]"
const PHRASE_NOTICE: String = "[Mamador: ¡delito federal!]"
const NOTICE_TIME: float = 2.5
const WINDOW_PRESENCE: String = "Mamador mirando por el cristal"

var _state: State = State.WALKING
var _inspect_elapsed: float = 0.0


func start() -> void:
	ai_level = DEBUG_AI_LEVEL
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


## Le ganó el dado: da un paso. El pasillo sur lo tiene que reservar antes.
func advance() -> void:
	var next_step: int = _route_index + 1
	if next_step > STEP_PASILLO_SUR:
		return
	if next_step == STEP_PASILLO_SUR and not GameManager.reserve_hallway(self):
		return  # Lo tiene Barcosa: espera en la escalera.

	move_to_step(next_step)
	if next_step == STEP_ESCALERA_PB:
		made_noise.emit(STAIRS_NOTICE, NOTICE_TIME)
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
	move_to_step(STEP_ESTACIONAMIENTO)


func window_presence() -> String:
	return WINDOW_PRESENCE if _state == State.INSPECTING else ""


func debug_text() -> String:
	if _state == State.INSPECTING:
		return "en el cristal, revisando (%.1f s)" % maxf(INSPECT_TIME - _inspect_elapsed, 0.0)
	var text: String = "en %s" % Rooms.display_name(current_room)
	if _route_index == STEP_ESCALERA_PB and not GameManager.is_hallway_free():
		text += ", esperando el pasillo"
	return text


## F6: lo manda directo a la escalera a planta baja, el paso antes del pasillo.
func debug_force_to_stairs() -> void:
	if _state != State.WALKING:
		return
	move_to_step(STEP_ESCALERA_PB)
	made_noise.emit(STAIRS_NOTICE, NOTICE_TIME)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F6:
		debug_force_to_stairs()

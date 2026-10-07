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
	RESTING,     # Descansando en el estacionamiento antes de volver a subir
}

## Su recorrido completo: baja de la sala de juntas al cristal y, después de
## inspeccionar, sigue bajando hasta el estacionamiento. De ahí vuelve a subir
## por los mismos pasos, así que la ruta se camina en los dos sentidos.
const ROUTE: Array[String] = ["sala_juntas", "pasillo_norte", "pasillo_sur",
	"escalera_pb", "estacionamiento"]
const STEP_SALA_JUNTAS: int = 0
const STEP_PASILLO_NORTE: int = 1
const STEP_PASILLO_SUR: int = 2
const STEP_ESCALERA_PB: int = 3
const STEP_ESTACIONAMIENTO: int = 4

## Lo que se queda junto al coche antes de volver a subir.
const REST_TIME: float = 12.0

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
var _rest_elapsed: float = 0.0
## +1 bajando por la ruta, -1 subiendo de regreso.
var _direction: int = 1


## Nombre corto para los archivos de imagen: cam07_mamador.png y demás.
func image_slug() -> String:
	return "mamador"


## Antes de salir de su lugar inicial se queda mirando fijo a la cámara.
func stalks_before_leaving() -> bool:
	return true


func game_over_cause() -> String:
	return GAME_OVER_CAUSE


func ai_key() -> String:
	return Nights.MAMADOR


func start() -> void:
	ai_level = night_ai_level()
	move_interval = MOVE_INTERVAL
	route = PackedStringArray(ROUTE)
	super()
	_state = State.WALKING
	_inspect_elapsed = 0.0
	_rest_elapsed = 0.0
	_direction = 1


func _process(delta: float) -> void:
	if not is_active:
		return
	match _state:
		State.WALKING:
			super(delta)  # El dado de la IA de la clase base
		State.INSPECTING:
			_process_inspecting(delta)
		State.RESTING:
			_process_resting(delta)


## Le ganó el dado: un paso en el sentido que lleva. El pasillo lo tiene que
## reservar antes de entrar, tanto bajando como subiendo, y lo suelta al salir.
func advance() -> void:
	var next_step: int = _route_index + _direction
	if next_step < 0 or next_step >= route.size():
		return
	if _needs_hallway(next_step) and not GameManager.reserve_hallway(self):
		return  # Lo tiene Barcosa: espera donde está.

	# Al bajar del pasillo sur a la escalera, el pasillo queda libre.
	if _route_index == STEP_PASILLO_SUR and next_step == STEP_ESCALERA_PB:
		GameManager.release_hallway(self)

	move_to_step(next_step)
	if next_step == STEP_PASILLO_NORTE:
		made_noise.emit(HALLWAY_NOTICE, NOTICE_TIME)
	elif next_step == STEP_PASILLO_SUR:
		_state = State.INSPECTING
		_inspect_elapsed = 0.0
	elif next_step == STEP_ESTACIONAMIENTO:
		# Llegó al coche: se queda un rato y después vuelve a subir.
		_state = State.RESTING
		_rest_elapsed = 0.0


## El pasillo se pide al entrar al norte bajando y al sur subiendo.
func _needs_hallway(next_step: int) -> bool:
	if next_step == STEP_PASILLO_NORTE and _direction > 0:
		return true
	return next_step == STEP_PASILLO_SUR and _direction < 0


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


## No encontró nada: dice su frase y empieza a bajar hacia el estacionamiento.
## El pasillo lo suelta en cuanto pisa la escalera, no aquí.
func _leave() -> void:
	made_noise.emit(PHRASE_NOTICE, NOTICE_TIME)
	_state = State.WALKING
	_direction = 1
	advance()


## Se le acabó el descanso junto al coche: da la vuelta y vuelve a subir.
func _process_resting(delta: float) -> void:
	_rest_elapsed += delta
	if _rest_elapsed < REST_TIME:
		return
	_state = State.WALKING
	_direction = -1
	_rest_elapsed = 0.0


## Parado en la escalera lleva su sufijo: cam07_mamador-escalera.
func _slug_token() -> String:
	if current_room == ROUTE[STEP_ESCALERA_PB]:
		return "%s-escalera" % image_slug()
	return super()


## Se ve por el cristal mientras inspecciona.
func is_in_zone(zone_id: String) -> bool:
	return zone_id == "front_glass" and _state == State.INSPECTING


func zone_presence(zone_id: String) -> String:
	if zone_id == "front_glass" and _state == State.INSPECTING:
		return WINDOW_PRESENCE
	return ""


func debug_text() -> String:
	if _state == State.INSPECTING:
		return "en el cristal, revisando (%.1f s)" % maxf(INSPECT_TIME - _inspect_elapsed, 0.0)
	if _state == State.RESTING:
		return "descansando en el estacionamiento (%.1f s)" % maxf(REST_TIME - _rest_elapsed, 0.0)
	var text: String = "en %s%s" % [Rooms.display_name(current_room),
		" (acechando)" if is_stalking else ""]
	text += ", subiendo" if _direction < 0 else ", bajando"
	if _needs_hallway(_route_index + _direction) and not GameManager.is_hallway_free():
		text += ", esperando el pasillo"
	return text


## F6: lo manda directo al pasillo norte, el paso antes del cristal.
func debug_force_to_stairs() -> void:
	debug_activate()
	if _state != State.WALKING:
		return
	_direction = 1
	if not GameManager.reserve_hallway(self):
		return
	move_to_step(STEP_PASILLO_NORTE)
	made_noise.emit(HALLWAY_NOTICE, NOTICE_TIME)


func _unhandled_input(event: InputEvent) -> void:
	if DebugKeys.matches(event, DebugKeys.MAMADOR_HALLWAY):
		debug_force_to_stairs()

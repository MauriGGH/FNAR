class_name Barcosa
extends Animatronic

## Barcosa (rol Foxy). Se esconde en la sala de servicio del salón B y va
## saliendo por etapas cada vez que el dado de la IA le gana... salvo que lo
## estés viendo por la CAM 10: vigilarlo le quita la oportunidad. Desde la
## etapa 2 sale corriendo por el pasillo hasta la puerta, y solo lo detiene
## encontrarla cerrada.

enum State {
	STALKING,  # En el salón B, avanzando de etapa
	RUNNING,   # Corriendo por el pasillo
	BANGING,   # Golpeando la puerta cerrada
}

## Nivel de IA mientras no exista la configuración por noche (hito 6).
## Para probar: 10. Con 20 sale casi siempre; con 0 no se mueve en toda la noche.
const DEBUG_AI_LEVEL: int = 10

# Su ruta fija. Los índices son los pasos que usa move_to_step().
const ROUTE: Array[String] = ["salon_b", "pasillo_norte", "pasillo_sur"]
const STEP_SALON_B: int = 0
const STEP_PASILLO_NORTE: int = 1
const STEP_PASILLO_SUR: int = 2

const STAGE_HIDDEN: int = 0
const STAGE_PEEKING: int = 1
const STAGE_LEAVING: int = 2
const STAGE_NAMES: Array[String] = ["escondido", "asomándose", "saliendo"]

## Cada cuánto tira el dado para avanzar una etapa.
const STAGE_INTERVAL: float = 5.0

# Lo que tarda en cruzar cada mitad del pasillo.
const NORTH_RUN_TIME: float = 1.5
const SOUTH_RUN_TIME: float = 1.0

# En la puerta cerrada: golpea y habla 5 s, y cada golpe cuesta 1 %.
const BANG_TIME: float = 5.0
const KNOCK_INTERVAL: float = 1.0
const KNOCK_POWER_COST: float = 1.0

const DOOR_PRESENCE: String = "Barcosa golpeando la puerta"

const CAMERA_STATE_LEFT: String = "salio"

const GAME_OVER_CAUSE: String = "Barcosa"
const RUN_NOTICE: String = "[pasos corriendo]"
const KNOCK_NOTICE: String = "[golpes en la puerta]"

signal stage_changed(stage: int)

var stage: int = STAGE_HIDDEN

var _state: State = State.STALKING
var _run_step: int = STEP_SALON_B
var _step_timer: float = 0.0
var _bang_elapsed: float = 0.0
var _knock_timer: float = 0.0


func start() -> void:
	ai_level = DEBUG_AI_LEVEL
	move_interval = STAGE_INTERVAL
	route = PackedStringArray(ROUTE)
	super()
	_state = State.STALKING
	_set_stage(STAGE_HIDDEN)


func _process(delta: float) -> void:
	if not is_active:
		return
	match _state:
		State.STALKING:
			super(delta)  # El dado de la IA de la clase base
		State.RUNNING:
			_process_run(delta)
		State.BANGING:
			_process_banging(delta)


## Vigilarlo por la CAM 10 le quita la oportunidad de avanzar.
func can_move() -> bool:
	return _state == State.STALKING and not is_being_watched()


## Le ganó el dado: sube una etapa o, si ya está en la 2, sale corriendo.
func advance() -> void:
	if stage < STAGE_LEAVING:
		_set_stage(stage + 1)
		return
	_try_start_run()


## Estados de la CAM 10: una etapa por cada paso de su salida, y "salio"
## desde que deja el salón hasta que regresa.
func camera_state() -> String:
	if _state != State.STALKING:
		return CAMERA_STATE_LEFT
	return "etapa%d" % stage


## Sigue reportando la CAM 10 aunque ya ande por el pasillo, y no reporta
## nada en las demás: sus etapas son del salón B y no significan nada en el
## pasillo. Cuando haya imágenes suyas corriendo, aquí van sus estados.
func camera_state_for(camera: int) -> String:
	if camera == Rooms.camera_of(ROUTE[STEP_SALON_B]):
		return camera_state()
	return ""


func debug_text() -> String:
	match _state:
		State.RUNNING:
			return "corriendo (%s)" % Rooms.display_name(current_room)
		State.BANGING:
			return "golpeando la puerta (%.1f s)" % maxf(BANG_TIME - _bang_elapsed, 0.0)
		_:
			var text: String = "etapa %d (%s)" % [stage, STAGE_NAMES[stage]]
			if stage == STAGE_LEAVING and not GameManager.is_hallway_free():
				text += " esperando el pasillo"
			return text


## F4: lo manda directo a correr, para no esperar al dado.
func debug_force_run() -> void:
	if _state != State.STALKING:
		return
	_set_stage(STAGE_LEAVING)
	_try_start_run()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F4:
		debug_force_run()


# --- La carrera ---------------------------------------------------------------

## Solo sale si el pasillo está libre; si lo tiene otro, se queda en la etapa 2.
func _try_start_run() -> void:
	if not GameManager.reserve_hallway(self):
		return
	_state = State.RUNNING
	_run_step = STEP_PASILLO_NORTE
	_step_timer = NORTH_RUN_TIME
	move_to_step(STEP_PASILLO_NORTE)
	made_noise.emit(RUN_NOTICE, NORTH_RUN_TIME + SOUTH_RUN_TIME)


func _process_run(delta: float) -> void:
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	if _run_step == STEP_PASILLO_NORTE:
		_run_step = STEP_PASILLO_SUR
		_step_timer = SOUTH_RUN_TIME
		move_to_step(STEP_PASILLO_SUR)
		return
	_arrive_at_door()


## Llegó a la puerta: la chapa cerrada lo detiene; abierta, te atrapa.
func _arrive_at_door() -> void:
	if not door_closed:
		_catch_player()
		return
	_state = State.BANGING
	_bang_elapsed = 0.0
	_knock_timer = 0.0
	made_noise.emit(KNOCK_NOTICE, BANG_TIME)


func _process_banging(delta: float) -> void:
	# Si abres la chapa mientras golpea, se mete de una.
	if not door_closed:
		_catch_player()
		return
	_bang_elapsed += delta
	# El corte va antes del golpe: si no, el golpe del segundo 5 se cuela
	# y serían 6 golpes en 5 s en vez de 5.
	if _bang_elapsed >= BANG_TIME:
		_go_home()
		return
	_knock_timer -= delta
	if _knock_timer <= 0.0:
		_knock_timer = KNOCK_INTERVAL
		PowerManager.drain(KNOCK_POWER_COST)


## Se rinde y vuelve al salón B desde cero, dejando el pasillo libre.
func _go_home() -> void:
	GameManager.release_hallway(self)
	_state = State.STALKING
	move_to_step(STEP_SALON_B)
	_set_stage(STAGE_HIDDEN)


func _catch_player() -> void:
	stop()
	GameManager.release_hallway(self)
	GameManager.trigger_game_over(GAME_OVER_CAUSE)


func zone_presence(zone_id: String) -> String:
	if zone_id == "entrance_door" and _state == State.BANGING:
		return DOOR_PRESENCE
	return ""


func _set_stage(new_stage: int) -> void:
	stage = clampi(new_stage, STAGE_HIDDEN, STAGE_LEAVING)
	stage_changed.emit(stage)

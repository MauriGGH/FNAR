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
## Lo que se ve de él en el pasillo (CAM 1 y CAM 2).
const STATE_RUNNING: String = "barcosa-corriendo"
const STATE_BANGING: String = "barcosa-golpeando"

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


## Nombre corto para los archivos de imagen: cam07_barcosa.png y demás.
func image_slug() -> String:
	return "barcosa"


func game_over_cause() -> String:
	return GAME_OVER_CAUSE


func ai_key() -> String:
	return Nights.BARCOSA


func start() -> void:
	ai_level = night_ai_level()
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


## En la CAM 10 reporta sus etapas, aunque ya ande por el pasillo. En el
## pasillo norte (CAM 1) basta su nombre; solo en la CAM 2, donde se ve la
## puerta, lleva además lo que está haciendo: corriendo o golpeando.
func camera_token(camera: int) -> String:
	if not is_active:
		return ""
	if camera == Rooms.camera_of(ROUTE[STEP_SALON_B]):
		return camera_state()
	if camera != Rooms.camera_of(current_room):
		return ""
	if camera != Rooms.camera_of(ROUTE[STEP_PASILLO_SUR]):
		return image_slug() if _state == State.RUNNING else ""
	match _state:
		State.RUNNING:
			return STATE_RUNNING
		State.BANGING:
			return STATE_BANGING
	return ""


## Corriendo por el pasillo tapa a cualquiera que coincida con él.
func hides_others(camera: int) -> bool:
	return _state == State.RUNNING and camera == Rooms.camera_of(current_room)


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
	debug_activate()
	if _state != State.STALKING:
		return
	_set_stage(STAGE_LEAVING)
	_try_start_run()


func _unhandled_input(event: InputEvent) -> void:
	if DebugKeys.matches(event, DebugKeys.BARCOSA_RUN):
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


## Se ve en la puerta mientras la golpea.
func is_in_zone(zone_id: String) -> bool:
	return zone_id == "entrance_door" and _state == State.BANGING


func zone_presence(zone_id: String) -> String:
	if zone_id == "entrance_door" and _state == State.BANGING:
		return DOOR_PRESENCE
	return ""


func _set_stage(new_stage: int) -> void:
	stage = clampi(new_stage, STAGE_HIDDEN, STAGE_LEAVING)
	stage_changed.emit(stage)

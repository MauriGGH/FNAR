class_name Audel
extends Animatronic

## El Mago Eléctrico (rol Balloon Boy; antes Audel Electrix). En pantalla se
## llama "Mago Eléctrico", pero el id, la clase, los estados y los archivos
## siguen siendo audel (cam06_audel-acecho, centro_audel.png) para no romper
## nada. Vive en el techo y baja por la escalera
## hacia la recepción y la oficina. No mata: si entra, hace el "cortaso", que
## se lleva un pedazo de energía y deja la linterna muerta un rato.
## Si le bajas el breaker mientras va en la escalera, se regresa al techo.

enum State {
	WALKING,   # Bajando por su ruta
	CORTASO,   # Haciendo el cortaso en la oficina
}


const ROUTE: Array[String] = ["techo", "escalera_techo", "recepcion", "oficina"]
const STEP_TECHO: int = 0
const STEP_ESCALERA: int = 1
const STEP_RECEPCION: int = 2
const STEP_OFICINA: int = 3

## Cada cuánto tira el dado para dar un paso.
const MOVE_INTERVAL: float = 6.0
## Lo que dura el cortaso antes de que se regrese al techo.
const CORTASO_TIME: float = 1.6

## De cada 100 oportunidades que no usa para moverse, cuántas acaban en
## descarga. Solo cuenta mientras está en el techo.
const DISCHARGE_CHANCE: int = 40

const DISCHARGE_NOTICE: String = "[chispazo en el techo]"
## Lo que se ve el chispazo en la CAM 6, y el sufijo de su estado.
const DISCHARGE_TIME: float = 2.5
const STATE_DISCHARGE: String = "-descarga"
const LADDER_NOTICE: String = "[zumbido eléctrico]"
const CORTASO_NOTICE: String = "[cortaso]"
const NOTICE_TIME: float = 2.5
const LADDER_PRESENCE: String = "Mago Eléctrico bajando la escalera"
const LADDER_ZONE: String = "ladder"

## Avisa que hay que dibujar las chispas sobre la pantalla.
signal cortaso_started()
## La descarga del pararrayos, con las cámaras que se llevó.
signal discharge_started(cameras: PackedInt32Array)

var _state: State = State.WALKING
var _cortaso_elapsed: float = 0.0
## Lo que le queda al chispazo que se ve en la CAM 6.
var _discharge_left: float = 0.0


## Nombre corto para los archivos de imagen: cam07_audel.png y demás.
func image_slug() -> String:
	return "audel"


## Soltando la descarga se ve distinto en el techo: cam06_audel-descarga.
func _slug_token() -> String:
	if _discharge_left > 0.0:
		return "%s%s" % [image_slug(), STATE_DISCHARGE]
	return super()


## Antes de salir de su lugar inicial se queda mirando fijo a la cámara.
func stalks_before_leaving() -> bool:
	return true


func ai_key() -> String:
	return Nights.AUDEL


func start() -> void:
	ai_level = night_ai_level()
	move_interval = MOVE_INTERVAL
	route = PackedStringArray(ROUTE)
	super()
	_state = State.WALKING
	_cortaso_elapsed = 0.0


func _process(delta: float) -> void:
	if not is_active:
		return
	if _discharge_left > 0.0:
		_discharge_left = maxf(_discharge_left - delta, 0.0)
	match _state:
		State.WALKING:
			super(delta)  # El dado de la IA de la clase base
		State.CORTASO:
			_cortaso_elapsed += delta
			if _cortaso_elapsed >= CORTASO_TIME:
				_go_back_to_roof()


## La oportunidad que no usa para moverse puede acabar en descarga, pero solo
## si sigue arriba en el techo, junto al pararrayos.
func try_move() -> bool:
	if super():
		return true
	if _state != State.WALKING or _route_index != STEP_TECHO:
		return false
	if randi_range(1, 100) <= DISCHARGE_CHANCE:
		cause_discharge()
	return false


## La descarga: tumba de 1 a 3 cámaras y avisa para el destello y la estática.
func cause_discharge() -> void:
	var affected: PackedInt32Array = GameManager.patch_panel.cause_discharge(GameManager.current_night)
	# Mientras dura, la CAM 6 lo enseña soltando el chispazo.
	_discharge_left = DISCHARGE_TIME
	if affected.is_empty():
		return
	made_noise.emit(DISCHARGE_NOTICE, NOTICE_TIME)
	discharge_started.emit(affected)


## Le ganó el dado: baja un paso. Al llegar a la oficina hace el cortaso.
func advance() -> void:
	var next_step: int = _route_index + 1
	if next_step > STEP_OFICINA:
		return
	move_to_step(next_step)
	if next_step == STEP_ESCALERA:
		made_noise.emit(LADDER_NOTICE, NOTICE_TIME)
	elif next_step == STEP_OFICINA:
		_do_cortaso()


## El breaker lo manda de vuelta al techo, pero solo si va en la escalera.
func on_blackout() -> void:
	if _state != State.WALKING or _route_index != STEP_ESCALERA:
		return
	move_to_step(STEP_TECHO)


## Se ve en la escalera al techo mientras baja.
func is_in_zone(zone_id: String) -> bool:
	return zone_id == LADDER_ZONE and _state == State.WALKING and _route_index == STEP_ESCALERA


func zone_presence(zone_id: String) -> String:
	if zone_id == LADDER_ZONE and _state == State.WALKING and _route_index == STEP_ESCALERA:
		return LADDER_PRESENCE
	return ""


func debug_text() -> String:
	if _state == State.CORTASO:
		return "cortaso (%.1f s)" % maxf(CORTASO_TIME - _cortaso_elapsed, 0.0)
	var text: String = "en %s" % Rooms.display_name(current_room)
	if PowerManager.is_flashlight_disabled:
		text += ", linterna muerta"
	var down: Array = GameManager.patch_panel.disconnected
	if not down.is_empty():
		text += ", sin señal: %s" % str(down)
	return text


## F10: lo manda directo a la escalera, para no esperar al dado.
func debug_force_to_ladder() -> void:
	debug_activate()
	if _state != State.WALKING:
		return
	move_to_step(STEP_ESCALERA)
	made_noise.emit(LADDER_NOTICE, NOTICE_TIME)




func _do_cortaso() -> void:
	_state = State.CORTASO
	_cortaso_elapsed = 0.0
	made_noise.emit(CORTASO_NOTICE, NOTICE_TIME)
	PowerManager.apply_cortaso()
	cortaso_started.emit()


func _go_back_to_roof() -> void:
	_state = State.WALKING
	_cortaso_elapsed = 0.0
	move_to_step(STEP_TECHO)


## El cortaso sin esperar a que entre, para probar el susto.
func debug_force_cortaso() -> void:
	debug_activate()
	_do_cortaso()


## El panel de pruebas lo manda a atacar por aquí.
func debug_force_attack() -> void:
	debug_force_to_ladder()

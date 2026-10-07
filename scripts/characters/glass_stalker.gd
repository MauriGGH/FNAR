class_name GlassStalker
extends Animatronic

## Base de los profes que terminan pegados al cristal de la oficina: Ureña,
## Juan.exe y Armando Prompts. Todos funcionan igual ahí: solo se ven con la
## linterna encendida y se alejan con destellos cortos; si no, entran y es
## game over. Ninguno usa la reserva del pasillo, así que pueden coincidir
## entre ellos y con Barcosa o Mamador.
##
## Cada uno lleva su propia cuenta de destellos, pero el night.gd le avisa de
## la linterna a todos a la vez: un mismo destello cuenta para todos los que
## estén en el cristal en ese momento.
##
## Lo único que cambia cada profe es su ruta, su intervalo, su clave en la
## tabla de noches y su tecla de depuración.

enum State { WALKING, AT_GLASS }

# Destellos: solo cuentan los encendidos cortos, ni un toque ni un reflector.
const FLASH_MIN_TIME: float = 0.2
const FLASH_MAX_TIME: float = 1.0
const FLASHES_TO_REPEL: int = 4
## Lo que aguanta en el cristal antes de entrar.
const GLASS_TIME: float = 10.0

const GLASS_ZONE: String = "front_glass"
const ARRIVE_NOTICE: String = "[respiración en el cristal]"
const NOTICE_TIME: float = 2.2

var flashes: int = 0

var _state: State = State.WALKING
var _glass_elapsed: float = 0.0
## Lo que lleva encendida la linterna, acumulado con el delta del juego. Con
## el reloj de pared no serviría: el tiempo del juego es el que cuenta.
var _flash_elapsed: float = -1.0
## +1 avanzando por la ruta, -1 de regreso. Solo lo usa el que se retira
## caminando (Armando), que sale del edificio y después da la vuelta.
var _direction: int = 1


func start() -> void:
	route = build_route()
	move_interval = step_interval()
	ai_level = night_ai_level()
	super()
	_state = State.WALKING
	_glass_elapsed = 0.0
	_flash_elapsed = -1.0
	_direction = 1
	flashes = 0


func _process(delta: float) -> void:
	if not is_active:
		return
	if _flash_elapsed >= 0.0:
		_flash_elapsed += delta
	match _state:
		State.WALKING:
			super(delta)  # El dado de la IA de la clase base
		State.AT_GLASS:
			_glass_elapsed += delta
			if _glass_elapsed >= GLASS_TIME:
				_catch_player()


## Le ganó el dado: un paso en el sentido que lleva. Al llegar al final de la
## ruta da la vuelta, así que el que se retira caminando regresa por donde vino.
func advance() -> void:
	var next_step: int = _route_index + _direction
	if next_step < 0 or next_step >= route.size():
		_direction = -_direction
		next_step = _route_index + _direction
	if next_step < 0 or next_step >= route.size():
		return
	move_to_step(next_step)
	if next_step == glass_step():
		_arrive_at_glass()


## Cada encendido corto de la linterna cuenta un destello.
func set_flashlight_on(is_on: bool) -> void:
	if is_on:
		_flash_elapsed = 0.0
		return
	if _flash_elapsed < 0.0:
		return
	var duration: float = _flash_elapsed
	_flash_elapsed = -1.0
	if _state != State.AT_GLASS:
		return
	if duration < FLASH_MIN_TIME or duration > FLASH_MAX_TIME:
		return  # Ni un toque ni dejarla prendida: tiene que ser un destello.
	flashes += 1
	if flashes >= FLASHES_TO_REPEL:
		_repel()


## Solo se ve pegado al cristal si la linterna está encendida.
## Está pegado al cristal, alumbrado o no.
func is_in_zone(zone_id: String) -> bool:
	return zone_id == GLASS_ZONE and _state == State.AT_GLASS


## En el cristal solo se ve dentro del haz.
func needs_flashlight(zone_id: String) -> bool:
	return zone_id == GLASS_ZONE


func zone_presence(zone_id: String) -> String:
	if zone_id != GLASS_ZONE or _state != State.AT_GLASS:
		return ""
	return glass_presence() if PowerManager.is_flashlight_on else ""


func debug_text() -> String:
	if _state == State.AT_GLASS:
		return "en el cristal, %d/%d destellos, %.1f s" % [
			flashes, FLASHES_TO_REPEL, maxf(GLASS_TIME - _glass_elapsed, 0.0)]
	var text: String = "en %s" % Rooms.display_name(current_room)
	if is_stalking:
		text += " (acechando)"
	if retreats_walking():
		text += ", subiendo" if _direction < 0 else ", bajando"
	return text


## true mientras esté pegado al cristal. Lo usan las pruebas y la depuración.
func is_at_glass() -> bool:
	return _state == State.AT_GLASS


## Su tecla de depuración lo manda directo al cristal, sin esperar al dado.
func debug_force_to_glass() -> void:
	debug_activate()
	if _state != State.WALKING or route.size() < 2:
		return
	_direction = 1
	move_to_step(glass_step() - 1)
	advance()


# --- Ganchos que cambia cada profe --------------------------------------------

## Su ruta. El último paso es siempre el cristal.
func build_route() -> PackedStringArray:
	return PackedStringArray()


## Cada cuánto tira el dado.
func step_interval() -> float:
	return 7.0


## En qué paso de la ruta se pega al cristal.
func glass_step() -> int:
	return maxi(route.size() - 1, 0)


## A qué paso regresa cuando lo ahuyentan, si se retira de un salto.
func retreat_step() -> int:
	return 0


## Por defecto, al ahuyentarlo vuelve de un salto a su lugar inicial. Armando
## no: sigue caminando hacia abajo, sale del edificio, llega a la cafetería y
## de ahí da la vuelta para volver a subir.
func retreats_walking() -> bool:
	return false


## La causa del game over y lo que dice la etiqueta de presencia. Por defecto
## salen del nombre que trae el nodo, así que casi ningún profe los cambia.
func game_over_cause() -> String:
	return display_name


func glass_presence() -> String:
	return "%s pegado al cristal" % display_name


func repel_notice() -> String:
	return "[%s se aleja]" % display_name


# --- Interno ------------------------------------------------------------------

func _arrive_at_glass() -> void:
	_state = State.AT_GLASS
	_glass_elapsed = 0.0
	flashes = 0
	made_noise.emit(ARRIVE_NOTICE, NOTICE_TIME)


func _repel() -> void:
	made_noise.emit(repel_notice(), NOTICE_TIME)
	_state = State.WALKING
	_glass_elapsed = 0.0
	flashes = 0
	if not retreats_walking():
		_direction = 1
		move_to_step(retreat_step())
		return
	# Se va caminando hacia abajo, un paso de inmediato para despegarse.
	_direction = 1
	advance()


func _catch_player() -> void:
	stop()
	GameManager.trigger_game_over(game_over_cause())


## El panel de pruebas lo manda a atacar por aquí.
func debug_force_attack() -> void:
	debug_force_to_glass()

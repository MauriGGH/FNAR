class_name GlassStalker
extends Animatronic

## Base de los profes que terminan pegados al cristal de la oficina: Ureña,
## Juan.exe y Armando Prompts. Todos funcionan igual ahí: solo se ven con la
## linterna encendida y se alejan con destellos cortos; si no, entran y es
## game over. Ninguno usa la reserva del pasillo, así que pueden coincidir
## entre ellos y con Barcosa o Mamador.
##
## La linterna ya no se apunta: alumbra todo el pasillo, así que le da a todos
## los que estén en el cristal a la vez. Cada uno lleva su propio "susto", que
## sube mientras hay luz y baja despacio en cuanto se apaga. Al llenarse, se va.
## No hay ritmo que acertar: vale mantenerla encendida o darle parpadeos
## rápidos, porque lo que cuenta es la luz acumulada.
##
## Los tiempos están en night_config.gd, para poder ajustarlos sin tocar esto.

enum State { WALKING, AT_GLASS }

const GLASS_ZONE: String = "front_glass"
const ARRIVE_NOTICE: String = "[respiración en el cristal]"
const NOTICE_TIME: float = 2.2

## De 0 a 1. A 1 se va. No se enseña: el jugador lo nota porque el profe acaba
## yéndose, no porque haya una barra.
var fear: float = 0.0

var _state: State = State.WALKING
var _glass_elapsed: float = 0.0
## Lo que aguanta en el cristal esta noche, de night_config.gd.
var _glass_time: float = NightConfig.GLASS_TIME_FIRST_NIGHT
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
	_glass_time = NightConfig.glass_time(GameManager.current_night)
	fear = 0.0
	_direction = 1


func _process(delta: float) -> void:
	if not is_active:
		return
	match _state:
		State.WALKING:
			super(delta)  # El dado de la IA de la clase base
		State.AT_GLASS:
			_glass_elapsed += delta
			if _glass_elapsed >= _glass_time:
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


## La clase base se lo manda a todos; aquí no hace falta hacer nada con el
## encendido en sí: lo que cuenta es la luz acumulada, y de eso se encarga
## update_beam() cuadro a cuadro.
func set_flashlight_on(_is_on: bool) -> void:
	pass


## El night.gd le dice, en cada cuadro, si la linterna lo está alumbrando. Con
## luz el susto sube; sin luz baja, pero mucho más despacio, así que los
## parpadeos se van sumando.
func update_beam(is_lit: bool, delta: float) -> void:
	if _state != State.AT_GLASS:
		fear = 0.0
		return
	if is_lit:
		fear += delta / NightConfig.FLASH_FILL_TIME
	else:
		fear -= delta / NightConfig.FLASH_DECAY_TIME
	fear = clampf(fear, 0.0, 1.0)
	if fear >= 1.0:
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
		return "en el cristal, susto %d %%, le quedan %.1f s" % [
			roundi(fear * 100.0), maxf(_glass_time - _glass_elapsed, 0.0)]
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
	# Llega sin susto, aunque la linterna ya estuviera encendida.
	fear = 0.0
	made_noise.emit(ARRIVE_NOTICE, NOTICE_TIME)


func _repel() -> void:
	made_noise.emit(repel_notice(), NOTICE_TIME)
	AudioManager.play(Sounds.GLASS_REPEL)
	_state = State.WALKING
	_glass_elapsed = 0.0
	fear = 0.0
	if not retreats_walking():
		_direction = 1
		move_to_step(retreat_step())
		return
	# Se va caminando hacia abajo, un paso de inmediato para despegarse.
	_direction = 1
	advance()


## El rescate lo devuelve al principio de su ruta, con el susto a cero.
func go_home() -> void:
	fear = 0.0
	_glass_elapsed = 0.0
	_state = State.WALKING
	super()


func _catch_player() -> void:
	stop()
	GameManager.trigger_game_over(game_over_cause())


## El panel de pruebas lo manda a atacar por aquí.
func debug_force_attack() -> void:
	debug_force_to_glass()

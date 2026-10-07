extends Node

## Autoload. Lleva la energía de la oficina, de 0 a 100 %.
## Gastan la puerta cerrada, las cámaras, la PC y la linterna.

signal power_changed(percent: float)
signal power_depleted()
## La corriente cortada por el breaker: apaga cámaras y PC y oscurece la
## oficina. La chapa de la puerta no se entera, porque está en el no-break.
signal blackout_changed(is_blackout: bool)

var power: float = NightConfig.MAX_POWER
var is_draining: bool = false
var is_door_closed: bool = false
var are_cameras_open: bool = false
var is_pc_open: bool = false
var is_flashlight_on: bool = false
## Depuración (F8): la energía deja de bajar, pero todo lo demás sigue igual.
var is_infinite: bool = false

var is_blackout: bool = false
## Bandera para cuando programemos la linterna: el cortaso la deja inservible.
var is_flashlight_disabled: bool = false

var _blackout_left: float = 0.0
var _cooldown_left: float = 0.0
var _flashlight_left: float = 0.0


## Deja la energía lista para empezar una noche. Casi siempre al 100 %, pero el
## reto del apagón arranca a la mitad.
func reset(start_power: float = NightConfig.MAX_POWER) -> void:
	power = clampf(start_power, 0.0, NightConfig.MAX_POWER)
	is_door_closed = false
	are_cameras_open = false
	is_pc_open = false
	is_flashlight_on = false
	is_flashlight_disabled = false
	_blackout_left = 0.0
	_cooldown_left = 0.0
	_flashlight_left = 0.0
	_set_blackout(false)
	power_changed.emit(power)


## Enciende o apaga el consumo (lo controla el GameManager).
func set_draining(draining: bool) -> void:
	is_draining = draining


# Cada vez que cambia algo que gasta, se avisa: así el HUD repinta las barras
# de consumo aunque la energía no se esté moviendo (energía infinita, o la
# noche ya terminada).
func set_door_closed(closed: bool) -> void:
	if is_door_closed == closed:
		return
	is_door_closed = closed
	power_changed.emit(power)


func set_cameras_open(open: bool) -> void:
	if are_cameras_open == open:
		return
	are_cameras_open = open
	power_changed.emit(power)


func set_pc_open(open: bool) -> void:
	if is_pc_open == open:
		return
	is_pc_open = open
	power_changed.emit(power)


func set_flashlight_on(on: bool) -> void:
	if is_flashlight_on == on:
		return
	is_flashlight_on = on
	power_changed.emit(power)


## Porcentaje que se pierde por segundo real con el estado actual.
func drain_per_second() -> float:
	var per_hour: float = NightConfig.IDLE_DRAIN_PER_HOUR
	if is_door_closed:
		per_hour += NightConfig.DOOR_DRAIN_PER_HOUR
	if are_cameras_open:
		per_hour += NightConfig.CAMERA_DRAIN_PER_HOUR
	if is_pc_open:
		per_hour += NightConfig.PC_DRAIN_PER_HOUR
	if is_flashlight_on:
		per_hour += NightConfig.FLASHLIGHT_DRAIN_PER_HOUR
	# Contra la hora normal, no contra la del modo prueba.
	return per_hour / NightConfig.power_hour_duration()


## Cuántas cosas están gastando energía ahora mismo, de 1 a 4, como el
## indicador de "usage" de FNAF 1. La oficina sola ya cuenta como 1.
## Ya están las cuatro: la oficina, la chapa, la pantalla que esté arriba y
## la linterna.
func usage_level() -> int:
	var level: int = 1
	if is_door_closed:
		level += 1
	if are_cameras_open:
		level += 1
	if is_pc_open:
		level += 1
	if is_flashlight_on:
		level += 1
	return mini(level, 4)


## Quita energía de golpe: los golpes de Barcosa, el cortaso de Audel o una
## respuesta mala en la llamada de Ureña.
func drain(amount: float) -> void:
	if not is_draining or amount <= 0.0:
		return
	_apply_drain(amount)


## F8: prende y apaga la energía infinita. No toca el consumo ni las barras,
## solo deja de restar; al apagarla sigue desde donde se quedó.
func toggle_infinite() -> void:
	is_infinite = not is_infinite
	power_changed.emit(power)


## El panel de pruebas pone la energía donde quiera. En 0 dispara el apagón
## igual que si se hubiera gastado sola.
func debug_set_power(percent: float) -> void:
	power = clampf(percent, 0.0, NightConfig.MAX_POWER)
	power_changed.emit(power)
	if is_zero_approx(power):
		is_draining = false
		power_depleted.emit()


func _process(delta: float) -> void:
	_process_breaker(delta)
	if not is_draining:
		return
	_apply_drain(drain_per_second() * delta)


# --- Breaker ------------------------------------------------------------------

## true si la palanca se puede bajar ahora mismo.
func can_cut_power() -> bool:
	return not is_blackout and _cooldown_left <= 0.0


## Baja la palanca. Devuelve false si todavía está en espera.
func cut_power() -> bool:
	if not can_cut_power():
		return false
	_blackout_left = NightConfig.BLACKOUT_TIME
	_set_blackout(true)
	return true


## De 1 a 0 mientras la corriente está cortada, para dibujar el tablero.
func blackout_progress() -> float:
	if NightConfig.BLACKOUT_TIME <= 0.0:
		return 0.0
	return clampf(_blackout_left / NightConfig.BLACKOUT_TIME, 0.0, 1.0)


## De 1 a 0 mientras hay que esperar para volver a usar el breaker.
func cooldown_progress() -> float:
	if NightConfig.BREAKER_COOLDOWN <= 0.0:
		return 0.0
	return clampf(_cooldown_left / NightConfig.BREAKER_COOLDOWN, 0.0, 1.0)


## El cortaso de Audel: se va un pedazo de energía y la linterna queda muerta.
func apply_cortaso() -> void:
	drain(NightConfig.CORTASO_POWER_LOSS)
	set_flashlight_on(false)  # El cortaso la apaga de inmediato.
	is_flashlight_disabled = true
	_flashlight_left = NightConfig.FLASHLIGHT_DISABLED_TIME


func _process_breaker(delta: float) -> void:
	if _blackout_left > 0.0:
		_blackout_left -= delta
		if _blackout_left <= 0.0:
			_blackout_left = 0.0
			_cooldown_left = NightConfig.BREAKER_COOLDOWN
			_set_blackout(false)
	elif _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)

	if _flashlight_left > 0.0:
		_flashlight_left = maxf(_flashlight_left - delta, 0.0)
		if is_zero_approx(_flashlight_left):
			is_flashlight_disabled = false


func _set_blackout(blackout: bool) -> void:
	if is_blackout == blackout:
		return
	is_blackout = blackout
	blackout_changed.emit(is_blackout)


func _apply_drain(amount: float) -> void:
	if is_infinite:
		return
	power = maxf(power - amount, 0.0)
	power_changed.emit(power)
	if is_zero_approx(power):
		is_draining = false
		power_depleted.emit()

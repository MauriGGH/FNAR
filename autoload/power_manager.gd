extends Node

## Autoload. Lleva la energía de la oficina, de 0 a 100 %.
## Gastan la puerta cerrada y las cámaras abiertas; falta la linterna.

signal power_changed(percent: float)
signal power_depleted()

var power: float = NightConfig.MAX_POWER
var is_draining: bool = false
var is_door_closed: bool = false
var are_cameras_open: bool = false
var is_pc_open: bool = false
## Depuración (F8): la energía deja de bajar, pero todo lo demás sigue igual.
var is_infinite: bool = false


## Deja la energía al 100 % para empezar una noche.
func reset() -> void:
	power = NightConfig.MAX_POWER
	is_door_closed = false
	are_cameras_open = false
	is_pc_open = false
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


## Porcentaje que se pierde por segundo real con el estado actual.
func drain_per_second() -> float:
	var per_hour: float = NightConfig.IDLE_DRAIN_PER_HOUR
	if is_door_closed:
		per_hour += NightConfig.DOOR_DRAIN_PER_HOUR
	if are_cameras_open:
		per_hour += NightConfig.CAMERA_DRAIN_PER_HOUR
	if is_pc_open:
		per_hour += NightConfig.PC_DRAIN_PER_HOUR
	# Contra la hora normal, no contra la del modo prueba.
	return per_hour / NightConfig.power_hour_duration()


## Cuántas cosas están gastando energía ahora mismo, de 1 a 4, como el
## indicador de "usage" de FNAF 1. La oficina sola ya cuenta como 1.
## Cuando entren la linterna y el breaker sumarán aquí.
func usage_level() -> int:
	var level: int = 1
	if is_door_closed:
		level += 1
	if are_cameras_open:
		level += 1
	if is_pc_open:
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


func _process(delta: float) -> void:
	if not is_draining:
		return
	_apply_drain(drain_per_second() * delta)


func _apply_drain(amount: float) -> void:
	if is_infinite:
		return
	power = maxf(power - amount, 0.0)
	power_changed.emit(power)
	if is_zero_approx(power):
		is_draining = false
		power_depleted.emit()

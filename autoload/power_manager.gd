extends Node

## Autoload. Lleva la energía de la oficina, de 0 a 100 %.
## Gastan la puerta cerrada y las cámaras abiertas; falta la linterna.

signal power_changed(percent: float)
signal power_depleted()

var power: float = NightConfig.MAX_POWER
var is_draining: bool = false
var is_door_closed: bool = false
var are_cameras_open: bool = false


## Deja la energía al 100 % para empezar una noche.
func reset() -> void:
	power = NightConfig.MAX_POWER
	is_door_closed = false
	are_cameras_open = false
	power_changed.emit(power)


## Enciende o apaga el consumo (lo controla el GameManager).
func set_draining(draining: bool) -> void:
	is_draining = draining


func set_door_closed(closed: bool) -> void:
	is_door_closed = closed


func set_cameras_open(open: bool) -> void:
	are_cameras_open = open


## Porcentaje que se pierde por segundo real con el estado actual.
func drain_per_second() -> float:
	var per_hour: float = NightConfig.IDLE_DRAIN_PER_HOUR
	if is_door_closed:
		per_hour += NightConfig.DOOR_DRAIN_PER_HOUR
	if are_cameras_open:
		per_hour += NightConfig.CAMERA_DRAIN_PER_HOUR
	return per_hour / NightConfig.hour_duration()


## Cuántas cosas están gastando energía ahora mismo, de 1 a 4, como el
## indicador de "usage" de FNAF 1. La oficina sola ya cuenta como 1.
## Cuando entren la linterna y el breaker sumarán aquí.
func usage_level() -> int:
	var level: int = 1
	if is_door_closed:
		level += 1
	if are_cameras_open:
		level += 1
	return mini(level, 4)


## Quita energía de golpe: los golpes de Barcosa, el cortaso de Audel o una
## respuesta mala en la llamada de Ureña.
func drain(amount: float) -> void:
	if not is_draining or amount <= 0.0:
		return
	_apply_drain(amount)


func _process(delta: float) -> void:
	if not is_draining:
		return
	_apply_drain(drain_per_second() * delta)


func _apply_drain(amount: float) -> void:
	power = maxf(power - amount, 0.0)
	power_changed.emit(power)
	if is_zero_approx(power):
		is_draining = false
		power_depleted.emit()

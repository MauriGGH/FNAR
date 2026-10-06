extends Node

## Autoload. Lleva la energía de la oficina, de 0 a 100 %.
## En el hito 1 solo gasta la puerta; después se sumarán linterna y cámaras.

signal power_changed(percent: float)
signal power_depleted()

var power: float = NightConfig.MAX_POWER
var is_draining: bool = false
var is_door_closed: bool = false


## Deja la energía al 100 % para empezar una noche.
func reset() -> void:
	power = NightConfig.MAX_POWER
	is_door_closed = false
	power_changed.emit(power)


## Enciende o apaga el consumo (lo controla el GameManager).
func set_draining(draining: bool) -> void:
	is_draining = draining


func set_door_closed(closed: bool) -> void:
	is_door_closed = closed


## Porcentaje que se pierde por segundo real con el estado actual.
func drain_per_second() -> float:
	var per_hour: float = NightConfig.IDLE_DRAIN_PER_HOUR
	if is_door_closed:
		per_hour += NightConfig.DOOR_DRAIN_PER_HOUR
	return per_hour / NightConfig.hour_duration()


func _process(delta: float) -> void:
	if not is_draining:
		return
	power = maxf(power - drain_per_second() * delta, 0.0)
	power_changed.emit(power)
	if is_zero_approx(power):
		is_draining = false
		power_depleted.emit()

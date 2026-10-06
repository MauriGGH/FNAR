class_name TestProfe
extends Animatronic

## Profe de prueba: recorre su ruta de ida y vuelta, nada más.
## Sirve para comprobar el grafo, el dado de la IA y el sistema de cámaras.
## BORRAR cuando entren los profes de verdad.

var _direction: int = 1


func start() -> void:
	super()
	_direction = 1


## Al llegar a un extremo de la ruta se da la vuelta en vez de quedarse quieto.
func advance() -> void:
	var next_index: int = _route_index + _direction
	if next_index < 0 or next_index >= route.size():
		_direction = -_direction
		next_index = _route_index + _direction
	if next_index < 0 or next_index >= route.size():
		return  # Ruta de un solo paso: no hay a dónde ir.
	move_to_step(next_index)

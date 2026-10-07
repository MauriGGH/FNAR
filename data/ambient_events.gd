class_name AmbientEvents
extends RefCounted

## Sucesos raros de las cámaras de ambiente (7, 8 y 9). No hacen nada: son
## atmósfera, y de paso pistas para una secuela. Cada tanto, mientras el
## jugador mira una de esas cámaras, la imagen parpadea y sale uno de estos
## avisos.

## Las cámaras por las que no pasa ningún profe.
const CAMERAS: Array[int] = [7, 8, 9]

## Cada cuánto se tira el dado. La probabilidad sube con la noche: en la 1
## sale poco, en la 6 bastante seguido.
const CHECK_TIME: float = 4.0
const CHANCE_BY_NIGHT: Dictionary = {
	1: 0.15, 2: 0.2, 3: 0.28, 4: 0.36, 5: 0.45, 6: 0.55,
}
## Lo que dura el parpadeo de la imagen.
const FLICKER_TIME: float = 0.4
const NOTICE_TIME: float = 2.0

## Lo que se queda puesta la imagen del suceso antes de volver a la normal.
const EVENT_TIME: float = 4.0
## El evento que parpadea alterna con la imagen vacía a este ritmo.
const BLINK_TIME: float = 0.45

## Los sucesos con imagen propia, por cámara. "blink" es el que alterna con
## cam09_vacia en vez de quedarse fijo.
const EVENTS: Dictionary = {
	8: [
		{"state": "evento1", "notice": "[una figura bajo el arbol]", "blink": false},
		{"state": "evento2", "notice": "[un coche con las luces prendidas]", "blink": false},
	],
	9: [
		{"state": "evento1", "notice": "[una silla bajada mirando a la camara]", "blink": false},
		{"state": "evento2", "notice": "[una sombra en la luz de la maquina]", "blink": true},
	],
}

## Avisos por cámara. El 0 son los que sirven para cualquiera.
const NOTICES: Dictionary = {
	0: ["[algo se movió]", "[la imagen se fue un momento]", "[ruido lejano]"],
	7: ["[pasos en el hueco de la escalera]", "[la luz de la escalera titila]",
		"[algo bajó corriendo]"],
	8: ["[se prendió un coche solo]", "[una sombra entre los coches]",
		"[la pluma del estacionamiento se movió]"],
	9: ["[una silla se corrió sola]", "[algo se cayó en la cafetería]",
		"[las luces de la cafetería parpadean]"],
}


static func is_ambient(camera: int) -> bool:
	return camera in CAMERAS


## Qué tan probable es que pase algo esa noche.
static func chance(night: int) -> float:
	return float(CHANCE_BY_NIGHT.get(clampi(night, 1, 6), 0.3))


## true si esa cámara tiene sucesos con imagen propia.
static func has_events(camera: int) -> bool:
	return EVENTS.has(camera)


## Un suceso al azar de esa cámara, o un diccionario vacío si no tiene.
static func pick_event(camera: int) -> Dictionary:
	var pool: Array = EVENTS.get(camera, [])
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]


## Un aviso al azar para esa cámara, mezclando los suyos con los generales.
static func pick_notice(camera: int) -> String:
	var pool: Array = []
	pool.append_array(NOTICES.get(camera, []))
	pool.append_array(NOTICES.get(0, []))
	if pool.is_empty():
		return ""
	return str(pool[randi() % pool.size()])

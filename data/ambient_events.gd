class_name AmbientEvents
extends RefCounted

## Sucesos raros de las cámaras de ambiente (7, 8 y 9). No hacen nada: son
## atmósfera, y de paso pistas para una secuela. Cada tanto, mientras el
## jugador mira una de esas cámaras, la imagen parpadea y sale uno de estos
## avisos.

## Las cámaras por las que no pasa ningún profe.
const CAMERAS: Array[int] = [7, 8, 9]

## Cada cuánto se tira el dado y qué tan probable es que salga algo.
const CHECK_TIME: float = 4.0
const CHANCE: float = 0.3
## Lo que dura el parpadeo de la imagen.
const FLICKER_TIME: float = 0.4
const NOTICE_TIME: float = 2.0

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


## Un aviso al azar para esa cámara, mezclando los suyos con los generales.
static func pick_notice(camera: int) -> String:
	var pool: Array = []
	pool.append_array(NOTICES.get(camera, []))
	pool.append_array(NOTICES.get(0, []))
	if pool.is_empty():
		return ""
	return str(pool[randi() % pool.size()])

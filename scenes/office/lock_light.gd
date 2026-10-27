class_name LockLight
extends Control

## El foquito de la chapa de la puerta. **Es lo que dice si la puerta está
## abierta o cerrada**, en lugar del letrero "CHAPA ABIERTA" que había antes:
## verde abierta, rojo cerrada, como cualquier chapa magnética de verdad.
##
## La foto ya trae el foco encendido en verde, así que:
##
## - Abierta no se dibuja nada: el verde de la foto ya está ahí.
## - Cerrada se pinta el rojo encima, con su derrame: el foco es chico y el
##   rojo lo tapa de sobra, así que no hace falta borrar el verde antes.
##
## Cuelga del Content de la vista central, como el tótem y la baraja, así que
## se mueve con el mismo parallax y se apaga con el apagón sin tocarlo aparte.

## Dónde está el foco y cuánto mide, **medido** sobre
## `oficina_centro_oscura.jpeg` buscando el píxel más verde de la zona
## `lock_box`: el núcleo cae en (0.6785, 0.7070) y la mancha con su halo tiene
## unos 25 px de ancho sobre una foto de 1375, o sea 0.018 del ancho.
const AT: Vector2 = Vector2(0.6785, 0.7070)
const RADIUS: float = 0.0036
## El derrame, que tiene que llegar tan lejos como el verde de la foto para
## taparlo: el verde se escapa unos 25 px sobre una foto de 1375 de ancho.
const SPILL: float = 0.016
## El halo se pinta a mano con muchas capas muy tenues en vez de con
## `DrawKit.glow`: aquel usa pocas y a este tamaño se le veían los escalones,
## como una diana. Y el foco tampoco es `DrawKit.led`, que le pinta un aro casi
## negro alrededor y aquí parecía una calcomanía pegada en la caja.
const GLOW_LAYERS: int = 16
const GLOW_ALPHA: float = 0.05

const CLOSED_COLOR: Color = Color(0.86, 0.22, 0.18)
## Lo que late el rojo, para que se note que está encendido y no pintado.
const PULSE_HZ: float = 0.8
const PULSE_DEPTH: float = 0.18

var _closed: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func set_closed(closed: bool) -> void:
	if _closed == closed:
		return
	_closed = closed
	set_process(closed)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	if not _closed:
		return
	var center: Vector2 = size * AT
	var intensity: float = 1.0 - PULSE_DEPTH * (0.5 + 0.5 * sin(_elapsed * TAU * PULSE_HZ))
	# El derrame: del halo grande y casi invisible al núcleo.
	var spill: float = size.x * SPILL
	for i: int in GLOW_LAYERS:
		var t: float = float(i) / float(GLOW_LAYERS - 1)
		draw_circle(center, lerpf(spill, spill * 0.12, t),
			Color(CLOSED_COLOR.r, CLOSED_COLOR.g, CLOSED_COLOR.b,
				GLOW_ALPHA * intensity))
	# Y el foco, sin aro: el rojo ya tapa el verde de la foto.
	var radius: float = size.x * RADIUS
	draw_circle(center, radius, CLOSED_COLOR.darkened(0.35))
	draw_circle(center, radius * 0.72, CLOSED_COLOR)
	draw_circle(center - Vector2(radius * 0.25, radius * 0.3), radius * 0.3,
		Color(1.0, 0.72, 0.68, 0.55 * intensity))

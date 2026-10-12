class_name TicketEnvelope
extends Control

## El aviso de que llegó un ticket, cuando la PC está **cerrada**: un sobrecito
## chiquito que parpadea tres veces encima de la pantalla del monitor de la
## oficina. Sin texto y sin banner: si estás mirando para allá lo ves, y si no,
## te queda el "ping" del audio.
##
## Se dibuja por código (no hay arte de sobre) y vive dentro del contenido de
## la vista central, así que se mueve con la vista como todo lo demás.

## Cuántas veces parpadea y cuánto dura cada parpadeo.
const BLINKS: int = 3
const ON_TIME: float = 0.26
const OFF_TIME: float = 0.2

## El tamaño del sobre, medido a 1080p, y lo que se levanta sobre el monitor.
const REFERENCE_HEIGHT: float = 1080.0
const WIDTH: float = 46.0
const HEIGHT: float = 32.0
const LIFT: float = 10.0

const PAPER: Color = Color(0.93, 0.92, 0.86)
const EDGE: Color = Color(0.25, 0.24, 0.22)
const GLOW: Color = Color(1.0, 0.86, 0.45)

## Dónde está la pantalla del monitor, en píxeles del contenido de la vista.
var _anchor: Rect2 = Rect2()
var _left: int = 0
var _on: bool = false
var _timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	visible = false


## La oficina le dice dónde cae el monitor; el sobre se pone encima, centrado.
## (No se llama set_anchor porque ese nombre ya es de Control.)
func set_target(rect: Rect2) -> void:
	_anchor = rect
	queue_redraw()


## Llegó un ticket: tres parpadeos y se va.
func blink() -> void:
	if _anchor.size.x <= 0.0:
		return
	_left = BLINKS
	_on = true
	_timer = ON_TIME
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	if _on:
		_on = false
		_timer = OFF_TIME
		_left -= 1
		if _left <= 0:
			visible = false
			set_process(false)
	else:
		_on = true
		_timer = ON_TIME
	queue_redraw()


func _draw() -> void:
	if not _on or _anchor.size.x <= 0.0:
		return
	var scale: float = size.y / REFERENCE_HEIGHT
	var box: Vector2 = Vector2(WIDTH, HEIGHT) * scale
	var at: Vector2 = Vector2(_anchor.get_center().x - box.x * 0.5,
		_anchor.position.y - box.y - LIFT * scale)
	var rect: Rect2 = Rect2(at, box)
	# Un resplandor detrás, para que se note sobre la foto oscura.
	DrawKit.glow(self, rect.get_center(), box.x * 0.9, GLOW, 0.5)
	draw_rect(rect, PAPER)
	draw_rect(rect, EDGE, false, maxf(1.0, 2.0 * scale))
	# La solapa: las dos diagonales del sobre.
	draw_line(rect.position, rect.get_center(), EDGE, maxf(1.0, 2.0 * scale))
	draw_line(Vector2(rect.end.x, rect.position.y), rect.get_center(), EDGE,
		maxf(1.0, 2.0 * scale))

class_name MinimapArea
extends Control

## El cuarto completo de una cámara en el minimapa: todo el rectángulo
## responde al clic, no solo la etiqueta. Se ilumina al pasar el mouse y el
## de la cámara que se está viendo queda con un verde tenue de fondo.

signal clicked(camera: int)

const HOVER_FILL: Color = Color(0.85, 0.92, 1.0, 0.1)
const CURRENT_FILL: Color = Color(0.2, 0.68, 0.32, 0.2)
const CURRENT_HOVER_FILL: Color = Color(0.25, 0.78, 0.38, 0.3)
const HOVER_EDGE: Color = Color(0.9, 0.95, 1.0, 0.35)
const CURRENT_EDGE: Color = Color(0.3, 0.85, 0.42, 0.5)

var camera: int = 0
var is_current: bool = false

var _hovered: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func set_current(current: bool) -> void:
	if current == is_current:
		return
	is_current = current
	queue_redraw()


func _on_hover(hovered: bool) -> void:
	_hovered = hovered
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	clicked.emit(camera)
	accept_event()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if is_current:
		draw_rect(rect, CURRENT_HOVER_FILL if _hovered else CURRENT_FILL)
		draw_rect(rect, CURRENT_EDGE, false, 1.0)
		return
	if _hovered:
		draw_rect(rect, HOVER_FILL)
		draw_rect(rect, HOVER_EDGE, false, 1.0)

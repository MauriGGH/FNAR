extends Control

## Barra de las cámaras, estilo FNAF: un rectángulo ancho y bajo pegado al
## borde de abajo, gris translúcido con borde blanco fino, y dos chevrones
## gruesos que apuntan hacia arriba cuando las cámaras están abajo y hacia
## abajo cuando están arriba. Sin texto.
## Se activa con solo pasarle el mouse por encima; Espacio hace lo mismo.

signal hovered()

const BACKGROUND_COLOR: Color = Color(0.09, 0.09, 0.11, 0.5)
const BACKGROUND_HOVER: Color = Color(0.2, 0.2, 0.23, 0.62)
const BORDER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.75)
const BORDER_WIDTH: float = 2.0
const CHEVRON_COLOR: Color = Color(1.0, 1.0, 1.0, 0.95)

const CHEVRON_COUNT: int = 2
const CHEVRON_SIZE: Vector2 = Vector2(38.0, 13.0)
const CHEVRON_THICKNESS: float = 5.0
const CHEVRON_GAP: float = 16.0

var pointing_up: bool = true

var _hovered: bool = false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(queue_redraw)


func set_pointing_up(up: bool) -> void:
	if up == pointing_up:
		return
	pointing_up = up
	queue_redraw()


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()
	hovered.emit()


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACKGROUND_HOVER if _hovered else BACKGROUND_COLOR)
	draw_rect(rect, BORDER_COLOR, false, BORDER_WIDTH)

	# Los chevrones van centrados, uno al lado del otro.
	var row_width: float = CHEVRON_COUNT * CHEVRON_SIZE.x + (CHEVRON_COUNT - 1) * CHEVRON_GAP
	var start_x: float = (size.x - row_width) * 0.5
	for i: int in CHEVRON_COUNT:
		_draw_chevron(Vector2(start_x + i * (CHEVRON_SIZE.x + CHEVRON_GAP) + CHEVRON_SIZE.x * 0.5, size.y * 0.5))


## Un chevron grueso, con la punta arriba o abajo según el estado.
func _draw_chevron(center: Vector2) -> void:
	var half: Vector2 = CHEVRON_SIZE * 0.5
	var tip_y: float = center.y - half.y if pointing_up else center.y + half.y
	var side_y: float = center.y + half.y if pointing_up else center.y - half.y
	draw_polyline(PackedVector2Array([
		Vector2(center.x - half.x, side_y),
		Vector2(center.x, tip_y),
		Vector2(center.x + half.x, side_y),
	]), CHEVRON_COLOR, CHEVRON_THICKNESS, true)

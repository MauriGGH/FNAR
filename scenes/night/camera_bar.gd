extends Control

## Barra semitransparente de abajo, estilo FNAF: con solo pasarle el mouse por
## encima avisa para abrir o cerrar las cámaras. Las flechas apuntan hacia
## arriba cuando están cerradas y hacia abajo cuando están abiertas.

signal hovered()

const BACKGROUND_COLOR: Color = Color(0.06, 0.06, 0.08, 0.55)
const EDGE_COLOR: Color = Color(0.85, 0.87, 0.9, 0.35)
const ARROW_COLOR: Color = Color(0.9, 0.92, 0.95, 0.85)
const ARROW_COUNT: int = 5
const ARROW_SIZE: Vector2 = Vector2(18.0, 10.0)
const ARROW_GAP: float = 10.0
const ARROW_TOP: float = 9.0

var pointing_up: bool = true


func _ready() -> void:
	mouse_entered.connect(func() -> void: hovered.emit())
	resized.connect(queue_redraw)


func set_pointing_up(up: bool) -> void:
	if up == pointing_up:
		return
	pointing_up = up
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2.0)), EDGE_COLOR)

	var row_width: float = ARROW_COUNT * ARROW_SIZE.x + (ARROW_COUNT - 1) * ARROW_GAP
	var start_x: float = (size.x - row_width) * 0.5
	for i: int in ARROW_COUNT:
		_draw_arrow(Vector2(start_x + i * (ARROW_SIZE.x + ARROW_GAP), ARROW_TOP))


func _draw_arrow(origin: Vector2) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	if pointing_up:
		points.append(origin + Vector2(ARROW_SIZE.x * 0.5, 0.0))
		points.append(origin + Vector2(ARROW_SIZE.x, ARROW_SIZE.y))
		points.append(origin + Vector2(0.0, ARROW_SIZE.y))
	else:
		points.append(origin)
		points.append(origin + Vector2(ARROW_SIZE.x, 0.0))
		points.append(origin + Vector2(ARROW_SIZE.x * 0.5, ARROW_SIZE.y))
	draw_colored_polygon(points, ARROW_COLOR)

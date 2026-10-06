extends Control

## Esquinas blancas en forma de L, como el visor de una cámara.
## Se dibujan por código para que se peguen a los bordes en cualquier resolución.

const ARM_LENGTH: float = 46.0
const THICKNESS: float = 4.0
const MARGIN: float = 26.0
const COLOR: Color = Color(1.0, 1.0, 1.0, 0.7)


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var frame: Rect2 = Rect2(Vector2(MARGIN, MARGIN), size - Vector2(MARGIN, MARGIN) * 2.0)
	if frame.size.x <= ARM_LENGTH or frame.size.y <= ARM_LENGTH:
		return

	var left: float = frame.position.x
	var top: float = frame.position.y
	var right: float = frame.end.x
	var bottom: float = frame.end.y
	var horizontal: Vector2 = Vector2(ARM_LENGTH, THICKNESS)
	var vertical: Vector2 = Vector2(THICKNESS, ARM_LENGTH)

	# Arriba izquierda, arriba derecha, abajo izquierda, abajo derecha.
	draw_rect(Rect2(Vector2(left, top), horizontal), COLOR)
	draw_rect(Rect2(Vector2(left, top), vertical), COLOR)
	draw_rect(Rect2(Vector2(right - ARM_LENGTH, top), horizontal), COLOR)
	draw_rect(Rect2(Vector2(right - THICKNESS, top), vertical), COLOR)
	draw_rect(Rect2(Vector2(left, bottom - THICKNESS), horizontal), COLOR)
	draw_rect(Rect2(Vector2(left, bottom - ARM_LENGTH), vertical), COLOR)
	draw_rect(Rect2(Vector2(right - ARM_LENGTH, bottom - THICKNESS), horizontal), COLOR)
	draw_rect(Rect2(Vector2(right - THICKNESS, bottom - ARM_LENGTH), vertical), COLOR)

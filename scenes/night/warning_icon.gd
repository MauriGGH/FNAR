extends Control

## Aviso parpadeante de la cuerda, al lado de la barra de cámaras, como el de
## la caja musical de FNAF 2. Triángulo con signo de admiración, dibujado.

const BLINK_TIME: float = 0.4
const BODY_COLOR: Color = Color(0.93, 0.74, 0.14)
const EDGE_COLOR: Color = Color(0.3, 0.2, 0.02)
const INK_COLOR: Color = Color(0.1, 0.08, 0.02)


func _ready() -> void:
	visible = false
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.15, BLINK_TIME)
	tween.tween_property(self, "modulate:a", 1.0, BLINK_TIME)


func _draw() -> void:
	var top: Vector2 = Vector2(size.x * 0.5, 2.0)
	var right: Vector2 = Vector2(size.x - 2.0, size.y - 3.0)
	var left: Vector2 = Vector2(2.0, size.y - 3.0)
	draw_colored_polygon(PackedVector2Array([top, right, left]), BODY_COLOR)
	draw_polyline(PackedVector2Array([top, right, left, top]), EDGE_COLOR, 2.0)

	# Signo de admiración: la barra y el punto.
	var bar_width: float = 5.0
	draw_rect(Rect2(Vector2(size.x * 0.5 - bar_width * 0.5, size.y * 0.38),
		Vector2(bar_width, size.y * 0.3)), INK_COLOR)
	draw_rect(Rect2(Vector2(size.x * 0.5 - bar_width * 0.5, size.y * 0.75),
		Vector2(bar_width, bar_width)), INK_COLOR)

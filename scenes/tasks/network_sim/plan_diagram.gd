extends Control

## Diagrama del plan: cómo debe quedar la topología. Es dibujo propio, chico,
## para la tarjeta de la tarea. No es interactivo.

const BOX: Vector2 = Vector2(46.0, 24.0)
const BOX_COLOR: Color = Color(0.22, 0.26, 0.31)
const BOX_EDGE: Color = Color(0.55, 0.68, 0.72)
const LINE_COLOR: Color = Color(0.3, 0.75, 0.45)
const TEXT_COLOR: Color = Color(0.85, 0.9, 0.92)
const FONT_SIZE: int = 12


func _draw() -> void:
	var router: Vector2 = Vector2(size.x * 0.5, 16.0)
	var switch_point: Vector2 = Vector2(size.x * 0.5, size.y * 0.5)
	draw_line(router + Vector2(0.0, BOX.y * 0.5), switch_point - Vector2(0.0, BOX.y * 0.5), LINE_COLOR, 2.0)
	for i: int in 4:
		var pc: Vector2 = Vector2(size.x * (0.14 + i * 0.24), size.y - 20.0)
		draw_line(switch_point + Vector2(0.0, BOX.y * 0.5), pc - Vector2(0.0, BOX.y * 0.5), LINE_COLOR, 2.0)
		_box(pc, "LAB-0%d" % (i + 1))
	_box(switch_point, "LAB-SW")
	_box(router, "LAB-RT")


func _box(center: Vector2, label: String) -> void:
	var rect: Rect2 = Rect2(center - BOX * 0.5, BOX)
	draw_rect(rect, BOX_COLOR)
	draw_rect(rect, BOX_EDGE, false, 1.0)
	var font: Font = Fonts.terminal()
	var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
	draw_string(font, Vector2(center.x - width * 0.5, center.y + 4.0),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TEXT_COLOR)

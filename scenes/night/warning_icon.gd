extends Control

## Aviso parpadeante de la cuerda, al lado de la barra de cámaras, como el de
## la caja musical de FNAF 2. Triángulo con signo de admiración, dibujado.
## Dos niveles: amarillo tranquilo y rojo apurado.

const BLINK_TIME: float = 0.4
const CRITICAL_BLINK_TIME: float = 0.16
const BODY_COLOR: Color = Color(0.93, 0.74, 0.14)
const CRITICAL_BODY_COLOR: Color = Color(0.88, 0.16, 0.13)
const EDGE_COLOR: Color = Color(0.3, 0.2, 0.02)
const INK_COLOR: Color = Color(0.1, 0.08, 0.02)

var level: int = 0

var _blink_tween: Tween = null


func _ready() -> void:
	visible = false


## 0 lo apaga, 1 amarillo, 2 rojo y parpadeando más rápido.
func set_level(new_level: int) -> void:
	if new_level == level:
		return
	level = new_level
	visible = level > 0
	queue_redraw()
	_restart_blink()


func _restart_blink() -> void:
	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()
	modulate.a = 1.0
	if level <= 0:
		return
	var blink: float = CRITICAL_BLINK_TIME if level >= 2 else BLINK_TIME
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(self, "modulate:a", 0.15, blink)
	_blink_tween.tween_property(self, "modulate:a", 1.0, blink)


func _draw() -> void:
	var top: Vector2 = Vector2(size.x * 0.5, 2.0)
	var right: Vector2 = Vector2(size.x - 2.0, size.y - 3.0)
	var left: Vector2 = Vector2(2.0, size.y - 3.0)
	var body: Color = CRITICAL_BODY_COLOR if level >= 2 else BODY_COLOR
	draw_colored_polygon(PackedVector2Array([top, right, left]), body)
	draw_polyline(PackedVector2Array([top, right, left, top]), EDGE_COLOR, 2.0)

	# Signo de admiración: la barra y el punto.
	var bar_width: float = 5.0
	draw_rect(Rect2(Vector2(size.x * 0.5 - bar_width * 0.5, size.y * 0.38),
		Vector2(bar_width, size.y * 0.3)), INK_COLOR)
	draw_rect(Rect2(Vector2(size.x * 0.5 - bar_width * 0.5, size.y * 0.75),
		Vector2(bar_width, bar_width)), INK_COLOR)

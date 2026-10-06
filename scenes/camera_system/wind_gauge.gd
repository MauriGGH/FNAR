extends Control

## Indicador circular de la cuerda del Come Trabas: un anillo que se vacía y
## cambia de color cuando queda poca.

const TRACK_COLOR: Color = Color(0.16, 0.18, 0.21, 0.9)
const FULL_COLOR: Color = Color(0.3, 0.8, 0.45)
const LOW_COLOR: Color = Color(0.95, 0.72, 0.18)
const RING_WIDTH: float = 10.0
const SEGMENTS: int = 48
const LOW_THRESHOLD: float = 25.0

var percent: float = 100.0


func set_percent(value: float) -> void:
	percent = clampf(value, 0.0, 100.0)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - RING_WIDTH
	if radius <= 0.0:
		return
	draw_arc(center, radius, 0.0, TAU, SEGMENTS, TRACK_COLOR, RING_WIDTH, true)
	if percent <= 0.0:
		return
	# Arranca arriba y se llena en el sentido del reloj.
	var start_angle: float = -PI * 0.5
	var color: Color = FULL_COLOR if percent > LOW_THRESHOLD else LOW_COLOR
	draw_arc(center, radius, start_angle, start_angle + TAU * percent / 100.0,
		SEGMENTS, color, RING_WIDTH, true)

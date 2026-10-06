extends Control

## Reloj de pastel de la cuerda, estilo FNAF 2: un círculo blanco relleno que
## se vacía en sentido del reloj, como una manecilla que va borrando lo que
## deja atrás. Sin números y sin colores, solo un borde fino.

const FILL_COLOR: Color = Color(0.95, 0.95, 0.94)
const EDGE_COLOR: Color = Color(0.95, 0.95, 0.94, 0.55)
const EDGE_WIDTH: float = 1.5
const MARGIN: float = 3.0
## Más puntos, borde del pastel más limpio.
const SEGMENTS: int = 64

var percent: float = 100.0


func set_percent(value: float) -> void:
	var clamped: float = clampf(value, 0.0, 100.0)
	if is_equal_approx(clamped, percent):
		return
	percent = clamped
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - MARGIN
	if radius <= 0.0:
		return

	# El borde completo se queda siempre, para que se vea el hueco que falta.
	draw_arc(center, radius, 0.0, TAU, SEGMENTS, EDGE_COLOR, EDGE_WIDTH, true)
	if percent <= 0.0:
		return

	# La manecilla arranca arriba y avanza en sentido del reloj; lo que queda
	# relleno es el sector que va de la manecilla hasta las 12.
	var remaining: float = percent / 100.0
	var start_angle: float = -PI * 0.5 + TAU * (1.0 - remaining)
	var end_angle: float = -PI * 0.5 + TAU

	var points: PackedVector2Array = PackedVector2Array([center])
	var steps: int = maxi(int(ceil(SEGMENTS * remaining)), 1)
	for i: int in steps + 1:
		var angle: float = lerpf(start_angle, end_angle, float(i) / float(steps))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, FILL_COLOR)

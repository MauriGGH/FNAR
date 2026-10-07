class_name StarRow
extends Control

## Las estrellas del menú principal, debajo del título: una por pasar la noche 5,
## otra por la 6 y otra por ganar una Custom Night con todos en 20. Se dibujan,
## no son imágenes: las ganadas van rellenas y doradas, las que faltan solo con
## el contorno apagado.

const STAR_COUNT: int = 3
const STAR_RADIUS: float = 15.0
const STAR_GAP: float = 14.0
## Lo picudas que son: cuánto mide el radio interior respecto al exterior.
const INNER_RATIO: float = 0.44
const POINTS: int = 5

const EARNED_FILL: Color = Color(0.98, 0.84, 0.35)
const EARNED_LINE: Color = Color(0.45, 0.35, 0.1)
const EMPTY_LINE: Color = Color(0.5, 0.5, 0.52, 0.55)
const LINE_WIDTH: float = 2.0

var earned: int = 0:
	set(value):
		earned = clampi(value, 0, STAR_COUNT)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(
		STAR_COUNT * STAR_RADIUS * 2.0 + (STAR_COUNT - 1) * STAR_GAP, STAR_RADIUS * 2.0)
	size = custom_minimum_size


func _draw() -> void:
	var step: float = STAR_RADIUS * 2.0 + STAR_GAP
	var total: float = STAR_COUNT * STAR_RADIUS * 2.0 + (STAR_COUNT - 1) * STAR_GAP
	var left: float = (size.x - total) * 0.5
	for index: int in STAR_COUNT:
		var center: Vector2 = Vector2(
			left + STAR_RADIUS + float(index) * step, size.y * 0.5)
		_draw_star(center, index < earned)


func _draw_star(center: Vector2, filled: bool) -> void:
	var points: PackedVector2Array = _star_points(center)
	if filled:
		draw_colored_polygon(points, EARNED_FILL)
	# El contorno se cierra volviendo al primer punto.
	var outline: PackedVector2Array = points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, EARNED_LINE if filled else EMPTY_LINE, LINE_WIDTH)


## Los diez vértices de la estrella, alternando radio de fuera y de dentro.
func _star_points(center: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in POINTS * 2:
		# Se empieza arriba, por eso el cuarto de vuelta de menos.
		var angle: float = float(i) * PI / float(POINTS) - PI * 0.5
		var radius: float = STAR_RADIUS if i % 2 == 0 else STAR_RADIUS * INNER_RATIO
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

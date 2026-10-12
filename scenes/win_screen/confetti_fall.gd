class_name ConfettiFall
extends Control

## El confeti de las 6 AM: triangulitos de colores que caen despacio mientras
## suena la campana. No es un sistema de partículas: son unos cuantos papelitos
## dibujados a mano, que es más que suficiente y no pide ningún recurso.

## Cuántos papelitos caen y de qué colores son.
const COUNT: int = 90
const COLORS: Array[Color] = [
	Color("#e8c23c"), Color("#d8552f"), Color("#3f8fd0"),
	Color("#56b26a"), Color("#c45ba8"), Color("#eae4d2"),
]

## Lo grandes que son y lo rápido que caen, medido a 1080p.
const REFERENCE_HEIGHT: float = 1080.0
const MIN_SIZE: float = 10.0
const MAX_SIZE: float = 22.0
const MIN_FALL: float = 60.0
const MAX_FALL: float = 150.0
## Lo que se mecen de lado al caer y lo que giran.
const SWAY_WIDTH: float = 40.0
const MIN_SWAY_HZ: float = 0.3
const MAX_SWAY_HZ: float = 0.9
const MIN_SPIN: float = -2.2
const MAX_SPIN: float = 2.2
## Lo que tardan en apagarse al final, para que no desaparezcan de golpe.
const FADE_OUT: float = 0.8

var _pieces: Array[Dictionary] = []
var _time: float = 0.0
var _duration: float = 0.0
var _running: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(false)


## Suelta el confeti durante estos segundos. Cada papelito arranca por encima
## del borde de arriba, repartido al azar, para que no entren todos en fila.
func play(seconds: float) -> void:
	_pieces.clear()
	for i: int in COUNT:
		_pieces.append({
			"x": randf() * size.x,
			"y": randf_range(-size.y * 0.6, 0.0),
			"fall": randf_range(MIN_FALL, MAX_FALL),
			"size": randf_range(MIN_SIZE, MAX_SIZE),
			"color": COLORS[randi() % COLORS.size()],
			"spin": randf_range(MIN_SPIN, MAX_SPIN),
			"phase": randf() * TAU,
			"sway_hz": randf_range(MIN_SWAY_HZ, MAX_SWAY_HZ),
		})
	_time = 0.0
	_duration = seconds
	_running = true
	modulate.a = 1.0
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	# Al acabarse el tiempo se apagan solos y se deja de dibujar.
	if _time > _duration:
		modulate.a = maxf(0.0, 1.0 - (_time - _duration) / FADE_OUT)
		if modulate.a <= 0.0:
			_running = false
			set_process(false)
	queue_redraw()


func _draw() -> void:
	if not _running:
		return
	var scale: float = size.y / REFERENCE_HEIGHT
	for piece: Dictionary in _pieces:
		var y: float = float(piece["y"]) + float(piece["fall"]) * _time * scale
		if y > size.y + MAX_SIZE:
			continue
		var sway: float = sin(_time * TAU * float(piece["sway_hz"]) + float(piece["phase"]))
		var at: Vector2 = Vector2(float(piece["x"]) + sway * SWAY_WIDTH * scale, y)
		_draw_triangle(at, float(piece["size"]) * scale,
			float(piece["phase"]) + float(piece["spin"]) * _time, piece["color"] as Color)


## Un triangulito equilátero girado sobre su centro.
func _draw_triangle(at: Vector2, radius: float, angle: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 3:
		var corner: float = angle + float(i) * TAU / 3.0
		points.append(at + Vector2(cos(corner), sin(corner)) * radius)
	draw_colored_polygon(points, color)

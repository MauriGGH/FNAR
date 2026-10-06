extends Control

## El cortaso de Audel: chispas dibujadas sobre la pantalla, con la estática
## fuerte del shader en el hijo. Dura un instante y se va solo.

const DURATION: float = 1.3
## Cada cuánto se vuelven a sortear las chispas.
const SPARK_REFRESH: float = 0.06
const SPARK_COUNT: int = 9
const SPARK_SEGMENTS: int = 5
const SPARK_SPREAD: float = 130.0
const SPARK_WIDTH: float = 3.0
const SPARK_COLOR: Color = Color(0.85, 0.95, 1.0, 0.95)
const SPARK_GLOW: Color = Color(0.5, 0.8, 1.0, 0.35)

var _left: float = 0.0
var _refresh_left: float = 0.0
var _sparks: Array[PackedVector2Array] = []

@onready var static_overlay: ColorRect = $StaticOverlay


func _ready() -> void:
	visible = false


func play() -> void:
	_left = DURATION
	_refresh_left = 0.0
	visible = true
	# La estática se pone fuerte ya, sin esperar al primer _process.
	var material: ShaderMaterial = static_overlay.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("strength", 0.75)
	_make_sparks()
	queue_redraw()


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	if _left <= 0.0:
		visible = false
		return

	# La estática arranca fuerte y se va bajando con el resto.
	var fade: float = clampf(_left / DURATION, 0.0, 1.0)
	var material: ShaderMaterial = static_overlay.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("strength", 0.75 * fade)

	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = SPARK_REFRESH
		_make_sparks()
	queue_redraw()


## Rayos quebrados que salen de puntos al azar de la pantalla.
func _make_sparks() -> void:
	_sparks.clear()
	for i: int in SPARK_COUNT:
		var origin: Vector2 = Vector2(randf_range(0.0, size.x), randf_range(0.0, size.y))
		var direction: Vector2 = Vector2.from_angle(randf_range(0.0, TAU))
		var points: PackedVector2Array = PackedVector2Array([origin])
		var step: float = SPARK_SPREAD / float(SPARK_SEGMENTS)
		for segment: int in SPARK_SEGMENTS:
			origin += direction * step + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
			points.append(origin)
		_sparks.append(points)


func _draw() -> void:
	var fade: float = clampf(_left / DURATION, 0.0, 1.0)
	for spark: PackedVector2Array in _sparks:
		draw_polyline(spark, Color(SPARK_GLOW.r, SPARK_GLOW.g, SPARK_GLOW.b, SPARK_GLOW.a * fade),
			SPARK_WIDTH * 3.0, true)
		draw_polyline(spark, Color(SPARK_COLOR.r, SPARK_COLOR.g, SPARK_COLOR.b, SPARK_COLOR.a * fade),
			SPARK_WIDTH, true)

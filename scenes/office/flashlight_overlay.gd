extends Control

## El brillo de la linterna. Ya no oscurece nada: de eso se encarga la foto del
## pasillo a oscuras que va de fondo, y la foto iluminada que solo se ve dentro
## del cono. Aquí solo queda la luz en sí: el halo del haz donde apunta el
## jugador y el chorro que sale de la mano del guardia hasta ahí.

const FADE_SPEED: float = 14.0
const LIGHT_TINT: Color = Color(0.86, 0.88, 0.78)
## Capas del halo, de fuera hacia dentro.
const GLOW_LAYERS: int = 5
const GLOW_ALPHA: float = 0.05
## Capas del chorro, de la mano al haz.
const CONE_LAYERS: int = 4
const CONE_ALPHA: float = 0.035
## Lo ancho que sale el chorro de la mano.
const HAND_WIDTH: float = 16.0

var amount: float = 0.0

var _target: float = 0.0
var _origin: Vector2 = Vector2.ZERO
## El centro del haz, normalizado, y su radio, también normalizado.
var _center: Vector2 = Vector2(0.5, 0.5)
var _radius: float = 0.0


func set_on(is_on: bool) -> void:
	_target = 1.0 if is_on else 0.0


## De dónde sale el haz: la mano del guardia, abajo al centro.
func set_origin(origin: Vector2) -> void:
	_origin = origin
	queue_redraw()


## Dónde apunta el cono y lo ancho que es, en normalizadas de la vista.
func set_beam_center(center: Vector2, radius: float) -> void:
	_center = center
	_radius = radius
	queue_redraw()


func _process(delta: float) -> void:
	if is_equal_approx(amount, _target):
		return
	amount = lerpf(amount, _target, 1.0 - exp(-delta * FADE_SPEED))
	if absf(amount - _target) < 0.004:
		amount = _target
	queue_redraw()


func _draw() -> void:
	if amount <= 0.002 or _radius <= 0.0 or size.x <= 0.0:
		return
	# El radio va en normalizadas sobre el ancho, como en el shader.
	var at: Vector2 = Vector2(_center.x * size.x, _center.y * size.y)
	var radius: float = _radius * size.x

	# El chorro: trapecios encimados de la mano al haz.
	for i: int in CONE_LAYERS:
		var spread: float = 1.0 - float(i) / float(CONE_LAYERS) * 0.55
		var alpha: float = CONE_ALPHA * amount * (1.0 - float(i) / float(CONE_LAYERS) * 0.5)
		draw_colored_polygon(PackedVector2Array([
			_origin + Vector2(-HAND_WIDTH * spread, 0.0),
			_origin + Vector2(HAND_WIDTH * spread, 0.0),
			at + Vector2(radius * spread, 0.0),
			at + Vector2(-radius * spread, 0.0),
		]), Color(LIGHT_TINT.r, LIGHT_TINT.g, LIGHT_TINT.b, alpha))

	# El halo, anillos que se van aclarando hacia dentro.
	for i: int in GLOW_LAYERS:
		var fraction: float = float(i) / float(GLOW_LAYERS)
		DrawKit.glow(self, at, radius * (1.0 - fraction * 0.6), LIGHT_TINT,
			GLOW_ALPHA * amount * (0.4 + fraction * 0.6))

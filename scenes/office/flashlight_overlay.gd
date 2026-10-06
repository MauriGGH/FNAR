extends Control

## La linterna: oscurece la oficina y deja un cono de luz suave sobre el
## cristal, que es lo único que se alcanza a ver del pasillo.
## El hueco de luz se hace dibujando la oscuridad en cuatro rectángulos
## alrededor de la zona iluminada, no con máscara, que necesitaría shader.

const DARKNESS: float = 0.72
const FADE_SPEED: float = 14.0
## Capas del borde suave entre la oscuridad y el cono.
const EDGE_LAYERS: int = 5
const EDGE_SPREAD: float = 26.0
## Capas del cono, de la linterna hacia el cristal.
const CONE_LAYERS: int = 4
const LIGHT_TINT: Color = Color(0.86, 0.88, 0.78)

var amount: float = 0.0

var _target: float = 0.0
var _lit_rect: Rect2 = Rect2()
var _origin: Vector2 = Vector2.ZERO


func set_on(is_on: bool) -> void:
	_target = 1.0 if is_on else 0.0


## La zona que alumbra (el cristal) y de dónde sale el haz (la mano del guardia).
func set_beam(lit_rect: Rect2, origin: Vector2) -> void:
	_lit_rect = lit_rect
	_origin = origin
	queue_redraw()


func _process(delta: float) -> void:
	if is_equal_approx(amount, _target):
		return
	amount = lerpf(amount, _target, 1.0 - exp(-delta * FADE_SPEED))
	if absf(amount - _target) < 0.004:
		amount = _target
	queue_redraw()


func _draw() -> void:
	if amount <= 0.002 or _lit_rect.size.x <= 0.0:
		return
	var dark: Color = Color(0.015, 0.018, 0.028, DARKNESS * amount)
	var lit: Rect2 = _lit_rect

	# La oscuridad, en cuatro pedazos alrededor del hueco de luz.
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, lit.position.y)), dark)
	draw_rect(Rect2(Vector2(0.0, lit.end.y), Vector2(size.x, size.y - lit.end.y)), dark)
	draw_rect(Rect2(Vector2(0.0, lit.position.y), Vector2(lit.position.x, lit.size.y)), dark)
	draw_rect(Rect2(Vector2(lit.end.x, lit.position.y), Vector2(size.x - lit.end.x, lit.size.y)), dark)

	# Borde suave: anillos que se van aclarando hacia dentro.
	for i: int in EDGE_LAYERS:
		var fraction: float = float(i) / float(EDGE_LAYERS)
		var ring: Rect2 = lit.grow(EDGE_SPREAD * (1.0 - fraction))
		draw_rect(ring, Color(dark.r, dark.g, dark.b, dark.a * 0.3 * (1.0 - fraction)), false, EDGE_SPREAD / float(EDGE_LAYERS))

	# El cono: trapecios encimados de la linterna al cristal.
	for i: int in CONE_LAYERS:
		var spread: float = 1.0 - float(i) / float(CONE_LAYERS) * 0.55
		var alpha: float = 0.05 * amount * (1.0 - float(i) / float(CONE_LAYERS) * 0.5)
		draw_colored_polygon(PackedVector2Array([
			_origin + Vector2(-16.0 * spread, 0.0),
			_origin + Vector2(16.0 * spread, 0.0),
			Vector2(lit.end.x - lit.size.x * (1.0 - spread) * 0.5, lit.end.y),
			Vector2(lit.position.x + lit.size.x * (1.0 - spread) * 0.5, lit.end.y),
		]), Color(LIGHT_TINT.r, LIGHT_TINT.g, LIGHT_TINT.b, alpha))

	# Y el cristal, apenas aclarado, más fuerte abajo (donde pega el haz).
	DrawKit.gradient_rect(self, lit,
		Color(LIGHT_TINT.r, LIGHT_TINT.g, LIGHT_TINT.b, 0.04 * amount),
		Color(LIGHT_TINT.r, LIGHT_TINT.g, LIGHT_TINT.b, 0.13 * amount))

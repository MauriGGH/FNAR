extends Control

## Oscurece una vista de la oficina cuando se corta la corriente, dejando solo
## unos puntos de luz (el LED de la chapa, la luna por la ventana). El brillo
## son círculos encimados, que es lo más barato para un resplandor suave.

const DARKNESS: float = 0.93
const FADE_SPEED: float = 6.0
const GLOW_RINGS: int = 5

var amount: float = 0.0  # 0 con luz, 1 a oscuras

var _target: float = 0.0
## Cada punto: {"position": Vector2, "radius": float, "color": Color}
var _spots: Array[Dictionary] = []


func set_blackout(blackout: bool) -> void:
	_target = 1.0 if blackout else 0.0


func set_spots(spots: Array[Dictionary]) -> void:
	_spots = spots
	queue_redraw()


func _process(delta: float) -> void:
	if is_equal_approx(amount, _target):
		return
	amount = lerpf(amount, _target, 1.0 - exp(-delta * FADE_SPEED))
	if absf(amount - _target) < 0.004:
		amount = _target
	queue_redraw()


func _draw() -> void:
	if amount <= 0.001:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.012, 0.02, DARKNESS * amount))
	for spot: Dictionary in _spots:
		var center: Vector2 = spot["position"]
		var radius: float = spot["radius"]
		var color: Color = spot["color"]
		for i: int in GLOW_RINGS:
			var ring: float = radius * (1.0 - float(i) / float(GLOW_RINGS))
			draw_circle(center, ring, Color(color.r, color.g, color.b, 0.12 * amount))
		draw_circle(center, radius * 0.18, Color(color.r, color.g, color.b, 0.85 * amount))

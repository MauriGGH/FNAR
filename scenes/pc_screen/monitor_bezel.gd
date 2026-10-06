extends Control

## Bisel del monitor CRT, dibujado: plástico beige oscuro, esquinas redondeadas
## y la barbilla más gruesa abajo, con su LED de encendido.
## screen_rect() devuelve el hueco donde va el escritorio.

const BEZEL_COLOR: Color = Color(0.27, 0.25, 0.21)
const BEZEL_HIGHLIGHT: Color = Color(0.35, 0.33, 0.28)
const BEZEL_SHADOW: Color = Color(0.13, 0.12, 0.1)
const SCREEN_COLOR: Color = Color(0.015, 0.025, 0.03)
const LED_COLOR: Color = Color(0.3, 0.95, 0.45)

const MARGIN_SIDE: float = 64.0
const MARGIN_TOP: float = 48.0
const MARGIN_BOTTOM: float = 80.0
const OUTER_RADIUS: int = 26
const SCREEN_RADIUS: int = 20


func _ready() -> void:
	resized.connect(queue_redraw)


## El hueco de la pantalla, en coordenadas locales.
func screen_rect() -> Rect2:
	return Rect2(
		Vector2(MARGIN_SIDE, MARGIN_TOP),
		Vector2(maxf(size.x - MARGIN_SIDE * 2.0, 0.0), maxf(size.y - MARGIN_TOP - MARGIN_BOTTOM, 0.0)))


func _draw() -> void:
	# Cuerpo del monitor, con un borde claro arriba que simula el brillo del plástico.
	draw_style_box(_box(BEZEL_COLOR, OUTER_RADIUS, BEZEL_HIGHLIGHT, 2), Rect2(Vector2.ZERO, size))
	# Hueco de la pantalla, hundido: borde oscuro por dentro.
	draw_style_box(_box(SCREEN_COLOR, SCREEN_RADIUS, BEZEL_SHADOW, 4), screen_rect())
	# LED de encendido en la barbilla.
	var led_center: Vector2 = Vector2(size.x - MARGIN_SIDE - 18.0, size.y - MARGIN_BOTTOM * 0.5)
	draw_circle(led_center, 5.0, LED_COLOR)
	draw_circle(led_center, 10.0, Color(LED_COLOR.r, LED_COLOR.g, LED_COLOR.b, 0.18))


func _box(color: Color, radius: int, border_color: Color, border_width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border_width)
	box.border_color = border_color
	return box

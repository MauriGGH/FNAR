class_name DrawKit
extends RefCounted

## Ayudantes de dibujo para que lo hecho por código se vea como el resto del
## juego: degradados en vez de rellenos planos, sombras suaves debajo de cada
## pieza, cables con volumen y LEDs con resplandor difuso.
## Nada de contornos negros gruesos ni colores puros.

const SHADOW_TINT: Color = Color(0.0, 0.0, 0.02)
const SHADOW_ALPHA: float = 0.3
const SHADOW_OFFSET: Vector2 = Vector2(3.0, 5.0)
const SHADOW_LAYERS: int = 3

const GLOW_LAYERS: int = 6
## Hasta dónde llega el resplandor de un LED, en veces su radio.
const GLOW_REACH: float = 5.5


## Degradado vertical de verdad: cuatro vértices, cada uno con su color.
static func gradient_rect(canvas: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	canvas.draw_polygon(
		PackedVector2Array([
			rect.position, Vector2(rect.end.x, rect.position.y),
			rect.end, Vector2(rect.position.x, rect.end.y),
		]),
		PackedColorArray([top, top, bottom, bottom]))


## Sombra suave de un rectángulo: varias capas desplazadas que se abren.
static func rect_shadow(canvas: CanvasItem, rect: Rect2, offset: Vector2 = SHADOW_OFFSET) -> void:
	for i: int in SHADOW_LAYERS:
		var spread: float = float(i) * 2.5
		var alpha: float = SHADOW_ALPHA / float(SHADOW_LAYERS) * (1.0 - float(i) / float(SHADOW_LAYERS + 1))
		canvas.draw_rect(Rect2(rect.position + offset, rect.size).grow(spread),
			Color(SHADOW_TINT.r, SHADOW_TINT.g, SHADOW_TINT.b, alpha))


## Borde fino y claro, en vez del contorno negro de antes.
static func soft_outline(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(rect, Color(color.r, color.g, color.b, 0.35), false, 1.0)


## Cable con volumen: sombra, cuerpo oscuro, cuerpo y un brillo fino arriba.
## Se ve cilíndrico sin necesitar shader.
static func cable(canvas: CanvasItem, points: PackedVector2Array, width: float, color: Color) -> void:
	if points.size() < 2:
		return
	canvas.draw_polyline(_shifted(points, SHADOW_OFFSET),
		Color(SHADOW_TINT.r, SHADOW_TINT.g, SHADOW_TINT.b, SHADOW_ALPHA), width * 1.15, true)
	canvas.draw_polyline(points, color.darkened(0.55), width, true)
	canvas.draw_polyline(points, color, width * 0.74, true)
	# El brillo va un poco arriba, como si la luz viniera de los LEDs.
	var highlight: Color = color.lightened(0.35)
	highlight.a = 0.42
	canvas.draw_polyline(_shifted(points, Vector2(-0.5, -width * 0.22)), highlight, width * 0.2, true)


## Curva de un cable que cuelga por su peso: lo que sobra de cable se vuelve
## panza, y cuando queda tenso casi no cuelga.
static func hanging_points(from_point: Vector2, to_point: Vector2,
		natural_length: float, segments: int) -> PackedVector2Array:
	var span: float = from_point.distance_to(to_point)
	var sag: float = maxf(natural_length - span, 0.0) * 0.62 + 10.0
	var control: Vector2 = (from_point + to_point) * 0.5 + Vector2(0.0, sag)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in segments + 1:
		var t: float = float(i) / float(segments)
		var inverse: float = 1.0 - t
		points.append(from_point * inverse * inverse + control * 2.0 * inverse * t + to_point * t * t)
	return points


## LED con resplandor difuso alrededor, no un círculo plano.
static func led(canvas: CanvasItem, center: Vector2, radius: float,
		color: Color, intensity: float) -> void:
	if intensity > 0.01:
		for i: int in GLOW_LAYERS:
			var fraction: float = 1.0 - float(i) / float(GLOW_LAYERS)
			var glow_radius: float = radius * (1.0 + GLOW_REACH * fraction)
			var alpha: float = 0.055 * intensity * (1.0 - fraction * 0.55)
			canvas.draw_circle(center, glow_radius, Color(color.r, color.g, color.b, alpha))
	var core: Color = color if intensity > 0.01 else color.darkened(0.8)
	canvas.draw_circle(center, radius * 1.35, Color(0.07, 0.075, 0.08))
	canvas.draw_circle(center, radius, core.lerp(Color(0.1, 0.11, 0.12), 1.0 - intensity))
	if intensity > 0.3:
		canvas.draw_circle(center - Vector2(radius * 0.3, radius * 0.35), radius * 0.3,
			Color(1.0, 1.0, 1.0, 0.4 * intensity))


## El reflejo del LED sobre el metal de al lado: un degradado que se apaga.
static func led_reflection(canvas: CanvasItem, center: Vector2, size: Vector2,
		color: Color, intensity: float, upward: bool) -> void:
	if intensity <= 0.01:
		return
	var near: Color = Color(color.r, color.g, color.b, 0.13 * intensity)
	var far: Color = Color(color.r, color.g, color.b, 0.0)
	var top: Vector2 = center - Vector2(size.x * 0.5, size.y if upward else 0.0)
	var rect: Rect2 = Rect2(top, size)
	if upward:
		gradient_rect(canvas, rect, far, near)
	else:
		gradient_rect(canvas, rect, near, far)


static func _shifted(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		out.append(point + offset)
	return out

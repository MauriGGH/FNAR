class_name ClaudioLogo
extends RefCounted

## El logo de Claudio, el asistente de IA de la PC: una chispa de ocho puntas
## naranja terracota con unos lentes tipo Clark Kent encima. Dibujado a mano,
## sin calcar ningún logo de verdad; es una parodia, no una copia.
## Se usa en el ícono del escritorio y en la barra de título de su ventana.

const ORANGE: Color = Color(0.82, 0.42, 0.24)
const ORANGE_DARK: Color = Color(0.64, 0.3, 0.17)
const GLASS: Color = Color(0.99, 0.97, 0.92, 0.5)
const FRAME: Color = Color(0.17, 0.15, 0.14)

## Puntas de la chispa: cuatro largas en cruz y cuatro cortas en diagonal.
const LONG_ARMS: int = 4
const SHORT_RATIO: float = 0.52
const ARM_WIDTH: float = 0.3


## Dibuja el logo centrado en center, con radius de radio.
static func draw_logo(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	_draw_spark(canvas, center, radius)
	_draw_glasses(canvas, center, radius)


## La chispa: ocho rombos saliendo del centro, los diagonales más cortos.
static func _draw_spark(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	for i: int in LONG_ARMS * 2:
		var angle: float = TAU * float(i) / float(LONG_ARMS * 2) - PI * 0.5
		var length: float = radius if i % 2 == 0 else radius * SHORT_RATIO
		var tip: Vector2 = center + Vector2.from_angle(angle) * length
		var side: Vector2 = Vector2.from_angle(angle + PI * 0.5) * (radius * ARM_WIDTH)
		var color: Color = ORANGE if i % 2 == 0 else ORANGE_DARK
		canvas.draw_colored_polygon(PackedVector2Array([center + side, tip, center - side]), color)
	canvas.draw_circle(center, radius * 0.26, ORANGE)


## Los lentes: dos aros redondos con su puente y sus patillas.
static func _draw_glasses(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	var lens: float = radius * 0.34
	var gap: float = radius * 0.42
	var line: float = maxf(radius * 0.1, 1.0)
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = center + Vector2(gap * side, 0.0)
		canvas.draw_circle(eye, lens, GLASS)
		canvas.draw_arc(eye, lens, 0.0, TAU, 20, FRAME, line, true)
	canvas.draw_line(center + Vector2(-gap + lens, 0.0), center + Vector2(gap - lens, 0.0), FRAME, line)
	for side: float in [-1.0, 1.0]:
		var outer: Vector2 = center + Vector2((gap + lens) * side, 0.0)
		canvas.draw_line(outer, outer + Vector2(radius * 0.22 * side, -radius * 0.12), FRAME, line)

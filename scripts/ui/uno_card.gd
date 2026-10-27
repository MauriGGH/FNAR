class_name UnoCard
extends RefCounted

## Dibuja una carta de la baraja decomisada. Lo usan la mesa acercada, la
## tarjeta de la PC y el montoncito que se ve sobre el escritorio, así que la
## carta se pinta en un solo sitio.
##
## La forma es la que todo el mundo reconoce —marco blanco, óvalo blanco
## inclinado y número grande al centro, con dos chiquitos en las esquinas—
## **sin el logo ni la palabra de la marca**.
##
## El número grande va del color de la carta sobre el óvalo blanco, y los
## chiquitos en blanco sobre el color: así cada uno se lee contra su fondo.

const OVAL_POINTS: int = 28


## Una carta en su rectángulo. `tilt` son radianes y `lifted` la levanta un
## poco con más sombra, que es como se ve la que traes en la mano.
static func draw_card(canvas: CanvasItem, rect: Rect2, card: Dictionary,
		tilt: float = 0.0, lifted: bool = false) -> void:
	var color: int = int(card.get("color", UnoDeck.RED))
	var number: int = int(card.get("number", 0))
	var ink: Color = UnoDeck.ink(color)

	canvas.draw_set_transform(rect.get_center(), tilt, Vector2.ONE)
	var box: Rect2 = Rect2(-rect.size * 0.5, rect.size)
	var shadow: Vector2 = Vector2(4.0, 7.0) if lifted else Vector2(2.0, 3.0)
	_rounded(canvas, Rect2(box.position + shadow, box.size), UnoDeck.CARD_SHADOW)
	_rounded(canvas, box, UnoDeck.WHITE)
	_rounded(canvas, box.grow(-UnoDeck.CARD_BORDER), ink)
	_oval(canvas, box, ink)
	_numbers(canvas, box, number, ink)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## El dorso: el mismo óvalo inclinado sobre el color oscuro, sin número. Es lo
## que se ve de la baraja guardada sobre el escritorio.
static func draw_back(canvas: CanvasItem, rect: Rect2, tilt: float = 0.0) -> void:
	canvas.draw_set_transform(rect.get_center(), tilt, Vector2.ONE)
	var box: Rect2 = Rect2(-rect.size * 0.5, rect.size)
	_rounded(canvas, box, UnoDeck.WHITE)
	_rounded(canvas, box.grow(-maxf(rect.size.x * 0.07, 1.0)), UnoDeck.BACK)
	_oval(canvas, box, UnoDeck.BACK)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Un rectángulo con las esquinas redondeadas, del tamaño que sea: el radio se
## escala con la carta para que una miniatura no salga toda redonda.
static func _rounded(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	var radius: int = roundi(UnoDeck.CARD_RADIUS * rect.size.x / UnoDeck.CARD_SIZE.x)
	style.set_corner_radius_all(maxi(radius, 1))
	canvas.draw_style_box(style, rect)


## El óvalo blanco de en medio, inclinado.
static func _oval(canvas: CanvasItem, box: Rect2, ink: Color) -> void:
	var half: Vector2 = box.size * UnoDeck.OVAL_SIZE * 0.5
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in OVAL_POINTS:
		var angle: float = TAU * float(i) / float(OVAL_POINTS)
		points.append(Vector2(cos(angle) * half.x, sin(angle) * half.y)
			.rotated(UnoDeck.OVAL_TILT))
	canvas.draw_colored_polygon(points, UnoDeck.WHITE)
	# Un filo del color de la carta, que es lo que le da el relieve.
	canvas.draw_polyline(points + PackedVector2Array([points[0]]),
		ink.darkened(0.25), maxf(box.size.x * 0.018, 1.0), true)


## El número grande del centro y los dos chiquitos de las esquinas.
static func _numbers(canvas: CanvasItem, box: Rect2, number: int, ink: Color) -> void:
	var font: Font = Fonts.display()
	var text: String = str(number)
	var big: int = maxi(roundi(box.size.y * UnoDeck.BIG_NUMBER), 8)
	_centered(canvas, font, text, Vector2.ZERO, big, ink)
	var small: int = maxi(roundi(box.size.y * UnoDeck.SMALL_NUMBER), 6)
	var corner: Vector2 = box.size * 0.5 - box.size * UnoDeck.CORNER_INSET
	_centered(canvas, font, text, Vector2(-corner.x, -corner.y), small, UnoDeck.WHITE)
	_centered(canvas, font, text, corner, small, UnoDeck.WHITE)


## Centrado de verdad en los dos ejes. La y de draw_string es la **base** de
## la letra, así que se sube la mitad de lo que mide el trazo: medio alto de
## ascendente menos descendente, no media altura de la caja, que mete el aire
## de arriba y deja el número bajo.
static func _centered(canvas: CanvasItem, font: Font, text: String, at: Vector2,
		font_size: int, color: Color) -> void:
	var wide: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var baseline: float = (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	canvas.draw_string(font, at + Vector2(-wide * 0.5, baseline), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

extends Control

## La cortina metálica de la puerta de entrada. Al cerrar la chapa baja en
## 0.35 s con un rebote chico al tocar el piso; al abrir sube en 0.5 s.
##
## Si existe la foto de la oficina con la cortina ya cerrada, se recorta de
## ahí solo el área de la puerta y se va revelando de arriba hacia abajo. Si
## no existe, se dibuja provisionalmente una cortina de láminas metálicas.
## El nodo cubre todo el contenido de la vista central, así que la foto
## recortada cae justo encima de la de abajo.

## La misma vista con la cortina cerrada, sin extensión.
const CLOSED_IMAGE_PATH: String = "res://assets/art/office/oficina_centro_cortina"

## Qué recortar de esa foto, en coordenadas normalizadas de la vista (la foto
## está alineada con oficina_centro). El recorte incluye el cajón de la cortina.
const IMAGE_AREA: Rect2 = Rect2(0.289, 0.293, 0.122, 0.391)
## De aquí hacia abajo está la lámina, y es lo único que se anima. El cajón,
## que es lo que queda arriba, aparece de golpe al cerrar la chapa.
const CURTAIN_TOP: float = 0.335

# Bajar: 0.3 s de caída y 0.05 s de rebote, 0.35 s en total.
const CLOSE_TIME: float = 0.3
const BOUNCE_TIME: float = 0.025
## Lo que rebota hacia arriba al tocar el piso, en fracción del alto.
const BOUNCE: float = 0.06
const OPEN_TIME: float = 0.5

## Alto de cada lámina de la cortina dibujada.
const SLAT_HEIGHT: float = 13.0
## Alto de la barra del filo de abajo, la que pesa.
const BAR_HEIGHT: float = 9.0

const METAL_TOP: Color = Color(0.3, 0.31, 0.33)
const METAL_BOTTOM: Color = Color(0.17, 0.175, 0.19)
const GROOVE: Color = Color(0.06, 0.065, 0.075, 0.85)
const SLAT_EDGE: Color = Color(1.0, 1.0, 1.0, 0.1)
const RAIL: Color = Color(0.13, 0.135, 0.15)
const BAR: Color = Color(0.24, 0.245, 0.26)
## Brillo vertical, como si le pegara la luz de la oficina de un lado.
const SHEEN: Color = Color(1.0, 0.97, 0.9, 0.07)

var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()

var _door_rect: Rect2 = Rect2()
var _texture: Texture2D = null
var _tween: Tween = null


func _ready() -> void:
	_texture = GameAssets.load_texture(CLOSED_IMAGE_PATH)


## El rectángulo de la zona entrance_door, en coordenadas del contenido.
func set_door_rect(rect: Rect2) -> void:
	_door_rect = rect
	queue_redraw()


## Baja o sube la cortina. Al cerrar, el último tramo es el rebote.
func set_closed(closed: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	if not closed:
		_tween.tween_property(self, "progress", 0.0, OPEN_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		return
	_tween.tween_property(self, "progress", 1.0, CLOSE_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "progress", 1.0 - BOUNCE, BOUNCE_TIME)
	_tween.tween_property(self, "progress", 1.0, BOUNCE_TIME)


## true cuando la cortina ya no tapa nada, para no dibujar de más.
func is_hidden_away() -> bool:
	return progress <= 0.001


func _draw() -> void:
	if is_hidden_away():
		return
	if _texture != null:
		_draw_from_image()
		return
	if _door_rect.size.y <= 0.0:
		return
	# Sin foto, la cortina dibujada llena justo el hueco de la puerta.
	var shown: Rect2 = Rect2(_door_rect.position,
		Vector2(_door_rect.size.x, _door_rect.size.y * clampf(progress, 0.0, 1.0)))
	_draw_slats(shown)
	_draw_bottom_bar(shown)


## Recorta de la foto con la cortina cerrada. El cajón va completo desde el
## primer frame; la lámina se revela de arriba hacia abajo.
func _draw_from_image() -> void:
	var area: Rect2 = Rect2(IMAGE_AREA.position * size, IMAGE_AREA.size * size)
	var top: float = CURTAIN_TOP * size.y
	if top > area.position.y:
		_blit(Rect2(area.position, Vector2(area.size.x, top - area.position.y)))
	var height: float = (area.end.y - top) * clampf(progress, 0.0, 1.0)
	if height <= 0.0:
		return
	var slat: Rect2 = Rect2(Vector2(area.position.x, top), Vector2(area.size.x, height))
	_blit(slat)
	_draw_bottom_bar(slat)


## Un pedazo de la foto de la cortina, en su mismo sitio.
func _blit(rect: Rect2) -> void:
	var factor: Vector2 = _texture.get_size() / size
	draw_texture_rect_region(_texture, rect, Rect2(rect.position * factor, rect.size * factor))


## Cortina provisional: láminas con su ranura, rieles a los lados y un brillo.
func _draw_slats(shown: Rect2) -> void:
	DrawKit.rect_shadow(self, shown, Vector2(0.0, 6.0))
	var y: float = shown.position.y
	while y < shown.end.y:
		var height: float = minf(SLAT_HEIGHT, shown.end.y - y)
		var slat: Rect2 = Rect2(Vector2(shown.position.x, y), Vector2(shown.size.x, height))
		DrawKit.gradient_rect(self, slat, METAL_TOP, METAL_BOTTOM)
		draw_line(Vector2(slat.position.x, y + 0.5), Vector2(slat.end.x, y + 0.5), SLAT_EDGE, 1.0)
		draw_line(Vector2(slat.position.x, slat.end.y - 0.5), Vector2(slat.end.x, slat.end.y - 0.5), GROOVE, 1.0)
		y += SLAT_HEIGHT
	DrawKit.gradient_rect(self, Rect2(shown.position, Vector2(shown.size.x * 0.4, shown.size.y)),
		SHEEN, Color(SHEEN.r, SHEEN.g, SHEEN.b, 0.0))
	var rail: float = maxf(shown.size.x * 0.035, 3.0)
	DrawKit.gradient_rect(self, Rect2(shown.position, Vector2(rail, shown.size.y)),
		RAIL.lightened(0.18), RAIL)
	DrawKit.gradient_rect(self, Rect2(Vector2(shown.end.x - rail, shown.position.y), Vector2(rail, shown.size.y)),
		RAIL, RAIL.darkened(0.25))


## La barra del filo de abajo: marca dónde va la cortina mientras se mueve.
func _draw_bottom_bar(shown: Rect2) -> void:
	var height: float = minf(BAR_HEIGHT, shown.size.y)
	var bar: Rect2 = Rect2(Vector2(shown.position.x, shown.end.y - height),
		Vector2(shown.size.x, height))
	DrawKit.gradient_rect(self, bar, BAR, BAR.darkened(0.5))
	draw_line(bar.position, Vector2(bar.end.x, bar.position.y), SLAT_EDGE, 1.0)

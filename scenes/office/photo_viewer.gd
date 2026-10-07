extends Control

## La foto que deja Ureña, abierta en grande. Oscurece la pantalla, pone la
## foto al centro con un acercamiento corto y se cierra con un clic en
## cualquier lado o con Escape.
##
## El juego no se detiene mientras está abierta: los profes se siguen
## moviendo, así que abrirla a mitad de la noche es un riesgo del jugador.

signal closed()

## La foto en grande, sin extensión.
const PHOTO_PATH: String = "res://assets/art/office/urena_foto_recorte"

## Lo que tarda el acercamiento y de qué tamaño arranca.
const ZOOM_TIME: float = 0.18
const ZOOM_FROM: float = 0.86
## Lo alto que llega la foto, en fracción de la pantalla.
const PHOTO_HEIGHT: float = 0.82
const BACKDROP: Color = Color(0.0, 0.0, 0.0, 0.78)
## El marco blanco de la foto, como una impresión de verdad.
const FRAME_COLOR: Color = Color(0.93, 0.91, 0.86)
const FRAME_WIDTH: float = 10.0
const HINT_COLOR: Color = Color(0.82, 0.8, 0.76, 0.8)
const HINT_SIZE: int = 18
const HINT_TEXT: String = "clic o Escape para cerrar"

var is_open: bool = false

## De 0 a 1: lo que lleva del acercamiento.
var zoom: float = 0.0:
	set(value):
		zoom = value
		queue_redraw()

var _texture: Texture2D = null
var _tween: Tween = null


func _ready() -> void:
	visible = false
	# Mientras está abierta se come los clics: cualquiera la cierra.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_texture = GameAssets.load_texture(PHOTO_PATH)


## true si hay foto que enseñar. Sin imagen no vale la pena abrirla.
func has_photo() -> bool:
	return _texture != null


func open() -> void:
	if is_open or not has_photo():
		return
	is_open = true
	visible = true
	zoom = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "zoom", 1.0, ZOOM_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	closed.emit()


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed:
		close()
		accept_event()


## Escape también la cierra. Va en _input porque este nodo se come los
## botones del mouse y _unhandled_input no vería la tecla.
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if _texture == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(BACKDROP.r, BACKDROP.g, BACKDROP.b, BACKDROP.a * zoom))
	var scale: float = lerpf(ZOOM_FROM, 1.0, zoom)
	var height: float = size.y * PHOTO_HEIGHT * scale
	var photo_size: Vector2 = Vector2(height * _texture.get_size().aspect(), height)
	var rect: Rect2 = Rect2((size - photo_size) * 0.5, photo_size)

	DrawKit.rect_shadow(self, rect.grow(FRAME_WIDTH), Vector2(6.0, 10.0))
	draw_rect(rect.grow(FRAME_WIDTH), FRAME_COLOR)
	draw_texture_rect(_texture, rect, false)

	var font: Font = Fonts.terminal()
	var hint_width: float = font.get_string_size(HINT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_SIZE).x
	draw_string(font, Vector2((size.x - hint_width) * 0.5, rect.end.y + FRAME_WIDTH + 30.0),
		HINT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, HINT_SIZE, HINT_COLOR)

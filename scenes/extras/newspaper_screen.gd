class_name NewspaperScreen
extends Control

## Un recorte de periódico, como el de FNAF entre noches. Si existe su imagen
## se usa; si no, se dibuja una plantilla de periódico con el texto de
## data/newspapers.gd. Clic en cualquier lado para continuar.
##
## A dónde se va después lo decide quien la abrió: el recorte 0 va a la noche
## 1, los de después vuelven al menú o al final del juego.

## Qué recorte enseñar y a dónde ir al cerrarlo. Los pone GameManager antes
## de cambiar de escena, porque change_scene_to_file no deja pasar datos.
static var pending_index: int = Newspapers.FIRST_INDEX
static var next_scene: String = Screens.NIGHT_INTRO
## Las hojas que se entregan después del recorte, si esa noche lleva alguna.
static var pending_documents: Array[String] = []

const PAPER: Color = Color(0.85, 0.83, 0.76)
const PAPER_SHADE: Color = Color(0.76, 0.74, 0.67)
const INK: Color = Color(0.13, 0.12, 0.11)
const INK_SOFT: Color = Color(0.32, 0.3, 0.28)
const PAPER_TILT: float = -0.012

## El recorte ocupa esta parte de la pantalla.
const PAGE_WIDTH: float = 0.74
const PAGE_HEIGHT: float = 0.78
const MARGIN: float = 34.0

const MASTHEAD_SIZE: int = 22
const TITLE_SIZE: int = 34
const DATE_SIZE: int = 18
const BODY_SIZE: int = 20
const HINT_SIZE: int = 17
const HINT_COLOR: Color = Color(0.7, 0.72, 0.74, 0.85)
const HINT_TEXT: String = "clic para continuar"

## Lo que tarda en aparecer.
const FADE_IN: float = 0.45

var _clipping: Dictionary = {}
var _image: Texture2D = null
var _fade: float = 0.0:
	set(value):
		_fade = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_clipping = Newspapers.clipping(pending_index)
	_image = Newspapers.image(pending_index)
	var tween: Tween = create_tween()
	tween.tween_property(self, "_fade", 1.0, FADE_IN)
	_build_hint()


func _build_hint() -> void:
	var label: Label = Label.new()
	label.text = HINT_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", HINT_SIZE)
	label.add_theme_color_override("font_color", HINT_COLOR)
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -46.0
	label.offset_bottom = -18.0
	add_child(label)


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed:
		_continue()
		accept_event()


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo \
			and key.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		_continue()
		get_viewport().set_input_as_handled()


func _continue() -> void:
	if pending_documents.is_empty():
		get_tree().change_scene_to_file(next_scene)
		return
	var documents: Array[String] = pending_documents.duplicate()
	pending_documents = []
	DocumentScreen.show_documents(get_tree(), documents, next_scene)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.92 * _fade))
	var page: Rect2 = Rect2(Vector2.ZERO, Vector2(size.x * PAGE_WIDTH, size.y * PAGE_HEIGHT))
	page.position = (size - page.size) * 0.5
	# Un poco chueco, como un recorte pegado a mano.
	draw_set_transform(page.get_center(), PAPER_TILT, Vector2.ONE * lerpf(0.96, 1.0, _fade))
	var sheet: Rect2 = Rect2(-page.size * 0.5, page.size)
	DrawKit.rect_shadow(self, sheet, Vector2(7.0, 11.0))
	if _image != null:
		draw_texture_rect(_image, sheet, false)
	else:
		_draw_template(sheet)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## La plantilla de periódico, para mientras no haya imagen del recorte.
func _draw_template(sheet: Rect2) -> void:
	var font: Font = Fonts.typewriter()
	DrawKit.gradient_rect(self, sheet, PAPER, PAPER_SHADE)
	# Fibras del papel, siempre las mismas.
	for i: int in 40:
		var y: float = sheet.position.y + 10.0 + fmod(float(i) * 53.0, sheet.size.y - 20.0)
		var x: float = sheet.position.x + 8.0 + fmod(float(i) * 97.0, sheet.size.x - 60.0)
		draw_line(Vector2(x, y), Vector2(x + 26.0, y + 1.0), Color(0.0, 0.0, 0.0, 0.03), 1.0)

	var left: float = sheet.position.x + MARGIN
	var width: float = sheet.size.x - MARGIN * 2.0
	var y: float = sheet.position.y + MARGIN + MASTHEAD_SIZE

	_centered(font, Vector2(0.0, y), Newspapers.MASTHEAD, MASTHEAD_SIZE, INK_SOFT)
	y += 10.0
	draw_line(Vector2(left, y), Vector2(left + width, y), INK_SOFT, 2.0)
	y += 6.0
	_centered(font, Vector2(0.0, y + DATE_SIZE), str(_clipping.get("date", "")), DATE_SIZE, INK_SOFT)
	y += DATE_SIZE + 22.0

	var title: String = str(_clipping.get("title", ""))
	var title_height: float = font.get_multiline_string_size(
		title, HORIZONTAL_ALIGNMENT_CENTER, width, TITLE_SIZE).y
	draw_multiline_string(font, Vector2(left, y + TITLE_SIZE), title,
		HORIZONTAL_ALIGNMENT_CENTER, width, TITLE_SIZE, -1, INK)
	y += title_height + 16.0
	draw_line(Vector2(left, y), Vector2(left + width, y), INK_SOFT, 1.0)
	y += BODY_SIZE + 14.0

	for line: Variant in _clipping.get("body", []):
		draw_string(font, Vector2(left, y), str(line), HORIZONTAL_ALIGNMENT_LEFT,
			width, BODY_SIZE, INK)
		y += BODY_SIZE * 1.45


func _centered(font: Font, at: Vector2, text: String, font_size: int, color: Color) -> void:
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(at.x - text_width * 0.5, at.y), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

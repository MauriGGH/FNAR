class_name ArtGallery
extends Control

## Un visor de arte a pantalla completa, de uno en uno: lo usan los expedientes
## de Extras. Se pasa de hoja con las flechas de los lados, con clic, o con las
## teclas de dirección.
##
## Lo que no está desbloqueado se muestra con la misma imagen pero oscurecida y
## desenfocada por el shader, con "???" encima: se adivina la silueta y nada más.

## Cambió de hoja: el índice nuevo. Lo usa quien quiera enseñar un pie de foto.
signal page_changed(index: int)

const LOCKED_SHADER: String = "res://scenes/ui/locked_art.gdshader"
const LOCKED_TEXT: String = "???"

const ARROW_SIZE: Vector2 = Vector2(64.0, 96.0)
const ARROW_MARGIN: float = 18.0
const ARROW_FONT: int = 40
const ARROW_COLOR: Color = Color(0.93, 0.9, 0.84)
const LOCKED_LABEL_SIZE: int = 96
const CAPTION_SIZE: int = 22
const CAPTION_COLOR: Color = Color(0.93, 0.9, 0.84)
const COUNTER_SIZE: int = 17
const COUNTER_COLOR: Color = Color(0.7, 0.72, 0.74, 0.9)
## Lo que tarda en aparecer la hoja nueva.
const FADE_TIME: float = 0.18

## Una entrada por hoja: {"texture": Texture2D, "unlocked": bool,
## "caption": String}. La imagen se muestra igual si está bloqueada, solo que
## pasada por el shader.
var _pages: Array[Dictionary] = []
var _index: int = 0

var _picture: TextureRect = null
var _locked_label: Label = null
var _caption: Label = null
var _counter: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Anclas y márgenes juntos: ya está dentro del árbol, y solo con las anclas
	# se quedaría de tamaño cero.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Le pasa las hojas y enseña la primera. Hay que llamarlo después de meterlo
## al árbol, porque construye sus nodos.
func setup(pages: Array[Dictionary], start_index: int = 0) -> void:
	_pages = pages
	_index = clampi(start_index, 0, maxi(0, _pages.size() - 1))
	if _picture == null:
		_build()
	_show_page()


func page_index() -> int:
	return _index


func _build() -> void:
	_picture = TextureRect.new()
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)

	_locked_label = _make_label(LOCKED_TEXT, LOCKED_LABEL_SIZE, CAPTION_COLOR)
	_locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_locked_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_locked_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_locked_label.add_theme_constant_override("outline_size", 10)
	add_child(_locked_label)

	_caption = _make_label("", CAPTION_SIZE, CAPTION_COLOR)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_left = 140.0
	_caption.offset_right = -140.0
	_caption.offset_top = -104.0
	_caption.offset_bottom = -52.0
	_caption.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	_caption.add_theme_constant_override("outline_size", 6)
	add_child(_caption)

	_counter = _make_label("", COUNTER_SIZE, COUNTER_COLOR)
	_counter.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_counter.offset_top = 8.0
	_counter.offset_bottom = 34.0
	add_child(_counter)

	_build_arrow("‹", false)
	_build_arrow("›", true)


## Una flecha a cada lado, centrada a lo alto.
func _build_arrow(glyph: String, forward: bool) -> void:
	var arrow: Button = Button.new()
	arrow.text = glyph
	arrow.flat = true
	arrow.custom_minimum_size = ARROW_SIZE
	arrow.size = ARROW_SIZE
	arrow.focus_mode = Control.FOCUS_NONE
	arrow.add_theme_font_size_override("font_size", ARROW_FONT)
	arrow.add_theme_color_override("font_color", ARROW_COLOR)
	arrow.set_anchors_preset(Control.PRESET_CENTER_RIGHT if forward
		else Control.PRESET_CENTER_LEFT)
	arrow.offset_top = -ARROW_SIZE.y * 0.5
	arrow.offset_bottom = ARROW_SIZE.y * 0.5
	if forward:
		arrow.offset_left = -ARROW_SIZE.x - ARROW_MARGIN
		arrow.offset_right = -ARROW_MARGIN
	else:
		arrow.offset_left = ARROW_MARGIN
		arrow.offset_right = ARROW_MARGIN + ARROW_SIZE.x
	arrow.pressed.connect(_step.bind(1 if forward else -1))
	add_child(arrow)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Pasa de hoja dando la vuelta al llegar al final.
func _step(direction: int) -> void:
	if _pages.is_empty():
		return
	_index = posmod(_index + direction, _pages.size())
	_show_page()


func _show_page() -> void:
	if _pages.is_empty():
		return
	var page: Dictionary = _pages[_index]
	var unlocked: bool = bool(page.get("unlocked", false))
	_picture.texture = page.get("texture", null) as Texture2D
	_picture.material = null if unlocked else _locked_material()
	_locked_label.visible = not unlocked
	_caption.text = str(page.get("caption", "")) if unlocked else ""
	_counter.text = "%d / %d" % [_index + 1, _pages.size()]
	# Una entrada corta, para que el cambio no sea un salto seco.
	_picture.modulate.a = 0.0
	create_tween().tween_property(_picture, "modulate:a", 1.0, FADE_TIME)
	page_changed.emit(_index)


## El material de lo bloqueado. Uno nuevo por hoja no hace falta: todos usan los
## mismos valores.
func _locked_material() -> ShaderMaterial:
	if not ResourceLoader.exists(LOCKED_SHADER):
		return null
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(LOCKED_SHADER)
	return material


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	# Clic en la mitad derecha avanza, en la izquierda retrocede.
	_step(1 if click.position.x > size.x * 0.5 else -1)
	accept_event()


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_RIGHT, KEY_D:
			_step(1)
		KEY_LEFT, KEY_A:
			_step(-1)
		_:
			return
	get_viewport().set_input_as_handled()

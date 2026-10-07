extends Control

## Una pregunta de sí o no, a pantalla completa y encima de todo. La usa el
## menú principal para confirmar que de verdad se quiere borrar la partida,
## que es lo único que no tiene vuelta atrás.

signal confirmed()
signal cancelled()

const BACKDROP: Color = Color(0.0, 0.0, 0.02, 0.88)
const TITLE_SIZE: int = 30
const BODY_SIZE: int = 19
const TITLE_COLOR: Color = Color(0.95, 0.93, 0.9)
const BODY_COLOR: Color = Color(0.74, 0.76, 0.78)
const BUTTON_SIZE: Vector2 = Vector2(200.0, 48.0)
const BUTTON_GAP: int = 14

var is_open: bool = false

var _title: Label = null
var _body: Label = null
var _row: HBoxContainer = null


func _ready() -> void:
	# Tiene que responder aunque el árbol esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = BACKDROP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_title = _make_label(TITLE_SIZE, TITLE_COLOR)
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 0.0
	_title.offset_bottom = 48.0
	add_child(_title)

	_body = _make_label(BODY_SIZE, BODY_COLOR)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_body.offset_left = 160.0
	_body.offset_right = -160.0
	add_child(_body)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", BUTTON_GAP)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_row)

	var yes: Button = UiButton.make("Sí, borrar")
	yes.custom_minimum_size = BUTTON_SIZE
	yes.pressed.connect(_on_yes)
	_row.add_child(yes)

	var no: Button = UiButton.make("Cancelar")
	no.custom_minimum_size = BUTTON_SIZE
	no.pressed.connect(close)
	_row.add_child(no)


func _make_label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Abre la pregunta. Hasta que se conteste no deja hacer nada más.
func ask(question: String, detail: String = "") -> void:
	_title.text = question
	_body.text = detail
	is_open = true
	visible = true
	_layout()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	cancelled.emit()


func _layout() -> void:
	_title.offset_top = size.y * 0.38
	_title.offset_bottom = _title.offset_top + 48.0
	_body.offset_top = size.y * 0.38 + 54.0
	_body.offset_bottom = _body.offset_top + 70.0
	_row.position = Vector2(
		(size.x - (BUTTON_SIZE.x * 2.0 + float(BUTTON_GAP))) * 0.5, size.y * 0.56)


func _on_yes() -> void:
	is_open = false
	visible = false
	confirmed.emit()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

extends Control

## Una pregunta de sí o no, a pantalla completa y encima de todo. La usa el
## menú principal para confirmar que de verdad se quiere borrar la partida,
## que es lo único que no tiene vuelta atrás.
##
## Mismo acabado que el resto: negro, VT323 y la lista de MenuList.

signal confirmed()
signal cancelled()

const HINT: String = "Esc para cancelar"
## Dónde cae la pregunta y dónde la lista, en fracción del alto.
const QUESTION_TOP: float = 0.36
const LIST_TOP: float = 0.52

var is_open: bool = false

var _question: Label = null
var _detail: Label = null
var _hint: Label = null
var _list: MenuList = null


func _ready() -> void:
	# Tiene que responder aunque el árbol esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()
	_layout()
	resized.connect(_layout)


func _build() -> void:
	MenuStyle.backdrop(self, Color(0.0, 0.0, 0.0, 0.94))
	_question = MenuStyle.label("", MenuStyle.TEXT)
	add_child(_question)
	_detail = MenuStyle.label("", MenuStyle.DIM)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_detail)

	_list = MenuList.new()
	_list.top = LIST_TOP
	add_child(_list)
	_list.add_action("Sí, borrar", _on_yes)
	_list.add_action("Cancelar", close)
	_list.build()

	_hint = MenuStyle.hint(self, HINT)


func _layout() -> void:
	MenuStyle.place_hint(_hint, size)
	var left: float = size.x * MenuStyle.LEFT_MARGIN
	if _question != null:
		_question.add_theme_font_size_override("font_size",
			MenuStyle.font_size(MenuStyle.TITLE_SIZE * 0.72, size.y))
		_question.position = Vector2(left, size.y * QUESTION_TOP)
		_question.size = Vector2(size.x * 0.85, size.y * 0.08)
	if _detail != null:
		_detail.add_theme_font_size_override("font_size",
			MenuStyle.font_size(MenuStyle.SMALL_SIZE * 1.2, size.y))
		_detail.position = Vector2(left, size.y * (QUESTION_TOP + 0.07))
		_detail.size = Vector2(size.x * 0.6, size.y * 0.1)
	if _list != null:
		_list.layout()


## Abre la pregunta. Hasta que se conteste no deja hacer nada más.
func ask(question: String, detail: String = "") -> void:
	_question.text = question.to_upper()
	_detail.text = detail
	is_open = true
	visible = true
	_layout()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	cancelled.emit()


func _on_yes() -> void:
	is_open = false
	visible = false
	confirmed.emit()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.keycode == KEY_ESCAPE and not key.echo:
		close()
		get_viewport().set_input_as_handled()
		return
	if _list.handle_key(key):
		get_viewport().set_input_as_handled()

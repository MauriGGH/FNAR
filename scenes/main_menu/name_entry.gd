extends Control

## Al empezar una partida nueva se pide el nombre del guardia. Lo dicen Ureña
## cuando llama y Rochis cuando te atrapa, así que vale la pena escribirlo.

const PROMPT: String = "¿Cómo te llamas, guardia?"
const HINT: String = "máximo %d caracteres · Enter para empezar"
const PROMPT_SIZE: int = 30
const HINT_SIZE: int = 17
const FIELD_SIZE: Vector2 = Vector2(460.0, 64.0)
const FIELD_FONT: int = 32
const TEXT_COLOR: Color = Color(0.93, 0.9, 0.84)
const HINT_COLOR: Color = Color(0.68, 0.7, 0.72, 0.85)

## Dónde van las piezas, en fracción del alto.
const PROMPT_TOP: float = 0.3
const FIELD_TOP: float = 0.41
const COLUMN_TOP: float = 0.58

var _field: LineEdit = null
var _prompt: Label = null
var _hint: Label = null
var _column: VBoxContainer = null


## Todo se centra a mano, así que se recoloca si cambia la ventana.
func _layout() -> void:
	if _prompt != null:
		_prompt.offset_top = size.y * PROMPT_TOP
		_prompt.offset_bottom = _prompt.offset_top + 48.0
	if _field != null:
		_field.size = FIELD_SIZE
		_field.position = Vector2((size.x - FIELD_SIZE.x) * 0.5, size.y * FIELD_TOP)
	if _hint != null:
		_hint.offset_top = size.y * FIELD_TOP + FIELD_SIZE.y + 10.0
		_hint.offset_bottom = _hint.offset_top + 28.0
	if _column != null:
		_column.position = Vector2((size.x - UiButton.SIZE.x) * 0.5, size.y * COLUMN_TOP)


func _ready() -> void:
	MenuBackdrop.build(self)
	_build_prompt()
	_build_field()
	_build_buttons()
	_layout()
	resized.connect(_layout)


func _build_prompt() -> void:
	var label: Label = Label.new()
	label.text = PROMPT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", PROMPT_SIZE)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(label)
	_prompt = label


func _build_field() -> void:
	_field = LineEdit.new()
	_field.max_length = NightConfig.MAX_NAME_LENGTH
	_field.text = SaveGame.player_name
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.add_theme_font_size_override("font_size", FIELD_FONT)
	_field.text_submitted.connect(_on_submitted)
	add_child(_field)
	_field.grab_focus()
	_field.select_all()

	var hint: Label = Label.new()
	hint.text = HINT % NightConfig.MAX_NAME_LENGTH
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", HINT_SIZE)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(hint)
	_hint = hint


func _build_buttons() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	_column = column

	var start: Button = UiButton.make("Empezar la noche 1")
	start.pressed.connect(_on_start)
	column.add_child(start)

	var back: Button = UiButton.make("Volver")
	back.pressed.connect(_on_back)
	column.add_child(back)


func _on_submitted(_text: String) -> void:
	_on_start()


## Partida nueva: se borra el progreso anterior y se guarda el nombre.
func _on_start() -> void:
	SaveGame.reset()
	SaveGame.set_player_name(_field.text)
	SaveGame.unlock_newspaper(Newspapers.FIRST_INDEX)
	GameManager.prepare_night(1)
	# El recorte 0 sale antes de la primera noche.
	get_tree().change_scene_to_file(Screens.NEWSPAPER)


func _on_back() -> void:
	get_tree().change_scene_to_file(Screens.MAIN_MENU)

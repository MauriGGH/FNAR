class_name OptionsPanel
extends Control

## El menú de opciones: el volumen de cada bus de audio y la pantalla completa.
## Es una capa que se abre encima de lo que haya, así que sirve igual en el menú
## principal y en la pausa de una noche, sin cambiar de escena.
##
## Todo lo que se toca aquí se guarda al momento en save.cfg; no hay botón de
## aceptar ni de cancelar.

## Se cerró: quien lo abrió puede volver a lo suyo.
signal closed()

const BACKDROP: Color = Color(0.0, 0.0, 0.02, 0.88)
const TITLE: String = "OPCIONES"
const TITLE_SIZE: int = 36
const LABEL_SIZE: int = 19
const VALUE_SIZE: int = 17
const TEXT: Color = Color(0.93, 0.9, 0.84)
const DIM: Color = Color(0.7, 0.72, 0.74)
const HINT: String = "Escape para volver"
const HINT_SIZE: int = 17

## El ancho de la columna y lo largo del deslizador.
const COLUMN_WIDTH: float = 520.0
const SLIDER_WIDTH: float = 300.0
const ROW_HEIGHT: float = 38.0
const ROW_GAP: int = 8

var is_open: bool = false

var _column: VBoxContainer = null
var _value_labels: Dictionary = {}   # bus -> Label del porcentaje
var _fullscreen_button: Button = null


## Lo mete en una pantalla y lo deja cerrado, listo para open().
static func build(parent: Control) -> OptionsPanel:
	var panel: OptionsPanel = OptionsPanel.new()
	panel.name = "OptionsPanel"
	parent.add_child(panel)
	return panel


func _ready() -> void:
	# Con el árbol pausado (la pausa de la noche) tiene que seguir respondiendo.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()
	AudioManager.bus_volume_changed.connect(_on_bus_volume_changed)
	DisplayManager.fullscreen_changed.connect(_on_fullscreen_changed)


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_layout()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = BACKDROP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var title: Label = Label.new()
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	title.add_theme_color_override("font_color", TEXT)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 70.0
	title.offset_bottom = 120.0
	add_child(title)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", ROW_GAP)
	_column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0.0)
	add_child(_column)

	for bus: String in Sounds.MIXER_BUSES:
		_column.add_child(_make_slider_row(bus))

	_fullscreen_button = UiButton.make(_fullscreen_text())
	_fullscreen_button.pressed.connect(DisplayManager.toggle)
	_column.add_child(_fullscreen_button)

	var back: Button = UiButton.make("Volver")
	back.pressed.connect(close)
	_column.add_child(back)

	var hint: Label = Label.new()
	hint.text = HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", HINT_SIZE)
	hint.add_theme_color_override("font_color", DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -56.0
	hint.offset_bottom = -24.0
	add_child(hint)


## Una fila: el nombre del bus, el deslizador y el porcentaje.
func _make_slider_row(bus: String) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(COLUMN_WIDTH, ROW_HEIGHT)

	var name_label: Label = Label.new()
	name_label.text = bus
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(110.0, ROW_HEIGHT)
	name_label.add_theme_font_size_override("font_size", LABEL_SIZE)
	name_label.add_theme_color_override("font_color", TEXT)
	row.add_child(name_label)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = AudioManager.bus_volume(bus)
	slider.custom_minimum_size = Vector2(SLIDER_WIDTH, ROW_HEIGHT)
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(_on_slider_changed.bind(bus))
	row.add_child(slider)

	var value: Label = Label.new()
	value.text = _percent_text(AudioManager.bus_volume(bus))
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(60.0, ROW_HEIGHT)
	value.add_theme_font_size_override("font_size", VALUE_SIZE)
	value.add_theme_color_override("font_color", DIM)
	row.add_child(value)
	_value_labels[bus] = value
	return row


func _percent_text(value: float) -> String:
	return "%d %%" % roundi(value * 100.0)


func _fullscreen_text() -> String:
	return "Pantalla completa: %s  (F11)" % ("sí" if DisplayManager.is_fullscreen() else "no")


func _layout() -> void:
	if _column != null:
		_column.position = Vector2((size.x - COLUMN_WIDTH) * 0.5, size.y * 0.26)


func _on_slider_changed(value: float, bus: String) -> void:
	AudioManager.set_bus_volume(bus, value)


## El AudioManager avisa del cambio: así el porcentaje también se actualiza si lo
## cambió otra cosa (el menú de pruebas, por ejemplo).
func _on_bus_volume_changed(bus: String, value: float) -> void:
	var label: Label = _value_labels.get(bus, null) as Label
	if label != null:
		label.text = _percent_text(value)


func _on_fullscreen_changed(_is_fullscreen: bool) -> void:
	if _fullscreen_button != null:
		_fullscreen_button.text = _fullscreen_text()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

extends Control

## La pausa de la noche. Se abre con Escape, siempre que Escape no esté
## ocupado en otra cosa (la PC, el breaker, la sala de servidores o la foto de
## Ureña abierta): de eso se encarga el night.gd, que es quien sabe qué hay
## arriba. Con la pausa puesta el reloj y los profes se detienen.

signal resumed()
signal menu_requested()

const TITLE: String = "PAUSA"
const TITLE_SIZE: int = 40
const TEXT_COLOR: Color = Color(0.93, 0.9, 0.84)
const BACKDROP: Color = Color(0.0, 0.0, 0.02, 0.8)
const HINT_SIZE: int = 17
const HINT_COLOR: Color = Color(0.68, 0.7, 0.72, 0.85)
const HINT: String = "Escape para continuar"

var is_open: bool = false
## El night.gd lo mantiene al día: true cuando Escape ya lo usa otra cosa.
var blocked: bool = false

## Dónde empieza la columna de botones, en fracción del alto.
const COLUMN_TOP: float = 0.44

var _column: VBoxContainer = null
var _fullscreen_button: Button = null


func _ready() -> void:
	# Con el árbol pausado este nodo tiene que seguir respondiendo.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	# Se come los clics: con la pausa puesta no se juega por abajo.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


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
	title.add_theme_color_override("font_color", TEXT_COLOR)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 180.0
	title.offset_bottom = 240.0
	add_child(title)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	_column = column

	var resume: Button = UiButton.make("Continuar")
	resume.pressed.connect(close)
	column.add_child(resume)

	_fullscreen_button = UiButton.make(_fullscreen_text())
	_fullscreen_button.pressed.connect(DisplayManager.toggle)
	column.add_child(_fullscreen_button)
	DisplayManager.fullscreen_changed.connect(_on_fullscreen_changed)

	var menu: Button = UiButton.make("Volver al menú")
	menu.pressed.connect(func() -> void: menu_requested.emit())
	column.add_child(menu)

	var hint: Label = Label.new()
	hint.text = HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", HINT_SIZE)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -60.0
	hint.offset_bottom = -28.0
	add_child(hint)


func _fullscreen_text() -> String:
	return "Pantalla completa: %s  (F11)" % ("sí" if DisplayManager.is_fullscreen() else "no")


func _on_fullscreen_changed(_is_fullscreen: bool) -> void:
	if _fullscreen_button != null:
		_fullscreen_button.text = _fullscreen_text()


## Escape abre y cierra la pausa. Si otra cosa ya usa Escape, no abre.
func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	if is_open:
		close()
	elif not blocked:
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	if _column != null:
		_column.position = Vector2((size.x - UiButton.SIZE.x) * 0.5, size.y * COLUMN_TOP)
	get_tree().paused = true


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	resumed.emit()

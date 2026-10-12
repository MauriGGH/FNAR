extends Control

## El recuadro de controles: sale solo la primera vez que se juega la noche 1,
## arriba a la izquierda, y se puede volver a abrir desde la pausa.
##
## No pausa el juego: se puede mirar la oficina y moverse con él puesto. Pero
## **la primera vez el reloj no avanza** mientras esté abierto, para que nadie
## pierda media noche leyendo. Si se abre después desde la pausa, el reloj ya
## corre como siempre (de pararlo se encarga la pausa misma).

## Se cerró. Lo escucha la noche para soltar el reloj.
signal closed()

const TITLE: String = "CONTROLES"
const TITLE_SIZE: int = 24
const KEY_SIZE: int = 19
const TEXT_SIZE: int = 18
const TITLE_COLOR: Color = Color(0.96, 0.94, 0.88)
const KEY_COLOR: Color = Color(0.98, 0.84, 0.35)
const TEXT_COLOR: Color = Color(0.85, 0.86, 0.88)
const BACKDROP: Color = Color(0.0, 0.0, 0.02, 0.72)
const HINT: String = "Esc o la X para cerrar"
const HINT_SIZE: int = 15
const HINT_COLOR: Color = Color(0.62, 0.64, 0.66)

## Dónde se apoya, en fracción de la pantalla, y lo ancho que es.
const MARGIN: Vector2 = Vector2(0.025, 0.045)
const WIDTH: float = 0.42
## Lo ancho de la columna de teclas, en fracción del recuadro.
const KEY_COLUMN: float = 0.34
const PADDING: Vector2 = Vector2(18.0, 14.0)
const ROW_GAP: int = 4
const FADE_TIME: float = 0.2

var is_open: bool = false
## true si es la primera vez: entonces el reloj se queda quieto.
var holds_clock: bool = false

var _panel: PanelContainer = null


func _ready() -> void:
	# Tiene que responder también con el árbol pausado: desde la pausa se abre.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false
	modulate.a = 0.0


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Card"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = BACKDROP
	box.set_corner_radius_all(4)
	box.content_margin_left = PADDING.x
	box.content_margin_right = PADDING.x
	box.content_margin_top = PADDING.y
	box.content_margin_bottom = PADDING.y
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", ROW_GAP)
	_panel.add_child(column)

	# Título y la X, en la misma fila.
	var header: HBoxContainer = HBoxContainer.new()
	column.add_child(header)
	var title: Label = _make_label(TITLE, TITLE_SIZE, TITLE_COLOR)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = Button.new()
	close.text = "X"
	close.flat = true
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(30.0, 26.0)
	Fonts.apply(close, Fonts.terminal(), TITLE_SIZE)
	close.add_theme_color_override("font_color", TITLE_COLOR)
	close.pressed.connect(close_card)
	header.add_child(close)

	for line: Dictionary in Controls.lines():
		column.add_child(_make_row(str(line["keys"]), str(line["what"])))

	column.add_child(_make_label(HINT, HINT_SIZE, HINT_COLOR))


## Una fila: la tecla a la izquierda, para qué sirve a la derecha.
func _make_row(keys: String, what: String) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var key_label: Label = _make_label(keys, KEY_SIZE, KEY_COLOR)
	key_label.custom_minimum_size = Vector2(WIDTH * KEY_COLUMN * 1000.0, 0.0)
	row.add_child(key_label)
	var what_label: Label = _make_label(what, TEXT_SIZE, TEXT_COLOR)
	what_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(what_label)
	return row


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(label, Fonts.terminal(), font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Lo abre. `hold_clock` solo va en true la primera vez, la del tutorial.
func open(hold_clock: bool = false) -> void:
	if is_open:
		return
	is_open = true
	holds_clock = hold_clock
	visible = true
	_layout()
	if holds_clock:
		GameManager.set_clock_held(true)
	create_tween().tween_property(self, "modulate:a", 1.0, FADE_TIME)


func close_card() -> void:
	if not is_open:
		return
	is_open = false
	if holds_clock:
		GameManager.set_clock_held(false)
		holds_clock = false
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(func() -> void: visible = false)
	closed.emit()


func _layout() -> void:
	if _panel == null:
		return
	var width: float = size.x * WIDTH
	_panel.custom_minimum_size = Vector2(width, 0.0)
	_panel.size = Vector2(width, 0.0)
	_panel.position = Vector2(size.x * MARGIN.x, size.y * MARGIN.y)
	for row: Node in _panel.get_child(0).get_children():
		var box: HBoxContainer = row as HBoxContainer
		if box != null and box.get_child_count() == 2:
			(box.get_child(0) as Control).custom_minimum_size.x = width * KEY_COLUMN


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == Controls.PAUSE_KEY:
		close_card()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()

extends Control

## El menú principal. El fondo es la foto de los profes, que tiene toda la mitad
## izquierda en negro: ahí van el título y las opciones, alineados a la
## izquierda y en VT323 blanco, como un letrero de pantalla vieja.
##
## Se mueve con las flechas o con el mouse; la opción elegida lleva ">>" al
## lado. Abajo a la izquierda, la versión; abajo al centro, el aviso de que
## manteniendo Supr se borra la partida (y luego hay que confirmar).

const MENU_CONFIRM: GDScript = preload("res://scenes/main_menu/confirm_box.gd")

const TITLE_TEXT: String = "FIVE NIGHTS AT ROCHA'S"
const TEXT_COLOR: Color = Color(0.95, 0.95, 0.93)
const DIM_COLOR: Color = Color(0.52, 0.53, 0.55)
const MARKER: String = ">>"
const MARKER_COLOR: Color = Color(0.98, 0.84, 0.35)

## Todo medido a 1080p y escalado con el alto de la ventana.
const REFERENCE_HEIGHT: float = 1080.0
const TITLE_SIZE: float = 62.0
const OPTION_SIZE: float = 36.0
const SMALL_SIZE: float = 20.0

## La columna de texto, en fracción de la pantalla: cae sobre la zona negra.
const LEFT_MARGIN: float = 0.055
const TEXT_INDENT: float = 0.105
const TITLE_TOP: float = 0.10
const STARS_TOP: float = 0.345
const OPTIONS_TOP: float = 0.45
const LINE_HEIGHT: float = 0.072

## Borrar la partida: lo que hay que mantener Supr y lo que dice el aviso.
const WIPE_KEY: Key = KEY_DELETE
const WIPE_HOLD: float = 1.5
const WIPE_HINT: String = "Mantén Supr para borrar el progreso"
const WIPE_BAR_WIDTH: float = 260.0
const WIPE_BAR_HEIGHT: float = 6.0
const WIPE_BAR_COLOR: Color = Color(0.85, 0.25, 0.22)

var _options: Array[Dictionary] = []
var _rows: Array[Control] = []
var _selected: int = 0
var _marker: Label = null
var _title: Label = null
var _stars: StarRow = null
var _version: Label = null
var _wipe_hint: Label = null
var _confirm: Control = null
var _options_panel: OptionsPanel = null
## Lo que lleva apretada la tecla de borrar.
var _wipe_held: float = 0.0


func _ready() -> void:
	MenuBackdrop.build(self)
	_build_title()
	_build_stars()
	_build_options()
	_build_footer()
	_build_confirm()
	_options_panel = OptionsPanel.build(self)
	_layout()
	resized.connect(_layout)
	_select(_first_enabled())


func _font_size(base: float) -> int:
	return maxi(10, roundi(base * size.y / REFERENCE_HEIGHT))


# --- Montaje ------------------------------------------------------------------

func _build_title() -> void:
	_title = _make_label(TITLE_TEXT, TITLE_SIZE, TEXT_COLOR)
	_title.add_theme_constant_override("line_spacing", 0)
	add_child(_title)


## Las tres estrellas del progreso, debajo del título y alineadas con él.
func _build_stars() -> void:
	_stars = StarRow.new()
	add_child(_stars)
	_stars.earned = SaveGame.star_count()


func _build_options() -> void:
	var locked: bool = not SaveGame.is_extras_unlocked()
	_options = [
		{"text": "Nueva partida", "enabled": true, "action": _on_new_game},
		{"text": "Continuar — noche %d" % SaveGame.night_reached,
			"enabled": SaveGame.has_progress(), "action": _on_continue},
		{"text": "Custom Night", "enabled": not locked, "action": _on_custom_night},
		{"text": "Extras", "enabled": not locked, "action": _on_extras},
		{"text": "Opciones", "enabled": true, "action": _on_options},
		{"text": "Salir", "enabled": true, "action": _on_quit},
	]
	_marker = _make_label(MARKER, OPTION_SIZE, MARKER_COLOR)
	add_child(_marker)
	for i: int in _options.size():
		var entry: Dictionary = _options[i]
		var row: Label = _make_label(str(entry["text"]), OPTION_SIZE,
			TEXT_COLOR if bool(entry["enabled"]) else DIM_COLOR)
		# Las filas sí reciben mouse: pasar por encima las elige.
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(_select.bind(i))
		row.gui_input.connect(_on_row_input.bind(i))
		add_child(row)
		_rows.append(row)


func _build_footer() -> void:
	_version = _make_label("v%s" % _version_text(), SMALL_SIZE, DIM_COLOR)
	add_child(_version)

	_wipe_hint = _make_label(WIPE_HINT, SMALL_SIZE, DIM_COLOR)
	_wipe_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_wipe_hint)


func _version_text() -> String:
	var value: String = str(ProjectSettings.get_setting("application/config/version", ""))
	return value if not value.is_empty() else "0.0.0"


## El aviso de confirmación, que solo sale al completar el mantener pulsado.
func _build_confirm() -> void:
	_confirm = MENU_CONFIRM.new()
	_confirm.name = "WipeConfirm"
	add_child(_confirm)
	_confirm.confirmed.connect(_wipe_progress)


func _make_label(text: String, base_size: float, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(label, Fonts.terminal(), _font_size(base_size))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	return label


# --- Colocación ---------------------------------------------------------------

## Todo se coloca a mano sobre la zona negra, y se vuelve a colocar si cambia
## el tamaño de la ventana.
func _layout() -> void:
	var left: float = size.x * LEFT_MARGIN
	var indent: float = size.x * TEXT_INDENT
	var line: float = size.y * LINE_HEIGHT

	if _title != null:
		Fonts.apply(_title, Fonts.terminal(), _font_size(TITLE_SIZE))
		_title.position = Vector2(left, size.y * TITLE_TOP)
		_title.size = Vector2(size.x * 0.45, size.y * 0.24)
	if _stars != null:
		_stars.position = Vector2(left, size.y * STARS_TOP)
	for i: int in _rows.size():
		var row: Label = _rows[i] as Label
		Fonts.apply(row, Fonts.terminal(), _font_size(OPTION_SIZE))
		row.position = Vector2(indent, size.y * OPTIONS_TOP + float(i) * line)
		row.size = Vector2(size.x * 0.4, line)
	if _marker != null:
		Fonts.apply(_marker, Fonts.terminal(), _font_size(OPTION_SIZE))
		_marker.size = Vector2(indent - left, line)
	_place_marker()
	if _version != null:
		Fonts.apply(_version, Fonts.terminal(), _font_size(SMALL_SIZE))
		_version.position = Vector2(size.x * 0.02, size.y * 0.945)
		_version.size = Vector2(size.x * 0.2, size.y * 0.05)
	if _wipe_hint != null:
		Fonts.apply(_wipe_hint, Fonts.terminal(), _font_size(SMALL_SIZE))
		_wipe_hint.position = Vector2(size.x * 0.3, size.y * 0.945)
		_wipe_hint.size = Vector2(size.x * 0.4, size.y * 0.05)


func _place_marker() -> void:
	if _marker == null or _selected < 0 or _selected >= _rows.size():
		return
	_marker.position = Vector2(size.x * LEFT_MARGIN, _rows[_selected].position.y)


# --- Selección ----------------------------------------------------------------

func _first_enabled() -> int:
	for i: int in _options.size():
		if bool(_options[i]["enabled"]):
			return i
	return 0


func _select(index: int) -> void:
	if index < 0 or index >= _options.size() or not bool(_options[index]["enabled"]):
		return
	_selected = index
	_place_marker()


## Salta a la siguiente opción que se pueda usar, dando la vuelta.
func _step(direction: int) -> void:
	if _options.is_empty():
		return
	var index: int = _selected
	for _i: int in _options.size():
		index = posmod(index + direction, _options.size())
		if bool(_options[index]["enabled"]):
			_select(index)
			return


func _activate() -> void:
	if _selected < 0 or _selected >= _options.size():
		return
	var entry: Dictionary = _options[_selected]
	if not bool(entry["enabled"]):
		return
	(entry["action"] as Callable).call()


func _on_row_input(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	_select(index)
	_activate()


func _input(event: InputEvent) -> void:
	if _options_panel != null and _options_panel.is_open:
		return
	if _confirm != null and _confirm.is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_UP, KEY_W:
			_step(-1)
		KEY_DOWN, KEY_S:
			_step(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_activate()
		_:
			return
	get_viewport().set_input_as_handled()


# --- Borrar el progreso -------------------------------------------------------

func _process(delta: float) -> void:
	var blocked: bool = (_confirm != null and _confirm.is_open) \
		or (_options_panel != null and _options_panel.is_open)
	if blocked or not Input.is_key_pressed(WIPE_KEY):
		if _wipe_held > 0.0:
			_wipe_held = 0.0
			queue_redraw()
		return
	_wipe_held += delta
	queue_redraw()
	if _wipe_held >= WIPE_HOLD:
		_wipe_held = 0.0
		_confirm.ask("¿Borrar todo el progreso?",
			"Se pierden las noches, los recortes, los expedientes y los retos.")


func _draw() -> void:
	if _wipe_held <= 0.0:
		return
	# La barrita de "mantén pulsado", justo encima del aviso.
	var fraction: float = clampf(_wipe_held / WIPE_HOLD, 0.0, 1.0)
	var width: float = WIPE_BAR_WIDTH * size.y / REFERENCE_HEIGHT
	var height: float = maxf(2.0, WIPE_BAR_HEIGHT * size.y / REFERENCE_HEIGHT)
	var at: Vector2 = Vector2((size.x - width) * 0.5, size.y * 0.935)
	draw_rect(Rect2(at, Vector2(width, height)), Color(0.2, 0.2, 0.22, 0.8))
	draw_rect(Rect2(at, Vector2(width * fraction, height)), WIPE_BAR_COLOR)


func _wipe_progress() -> void:
	SaveGame.reset()
	# El menú se rearma solo: así "Continuar", las estrellas y los bloqueos
	# vuelven a su estado de partida nueva sin tener que repintarlos a mano.
	get_tree().reload_current_scene()


# --- Opciones del menú --------------------------------------------------------

func _on_new_game() -> void:
	get_tree().change_scene_to_file(Screens.NAME_ENTRY)


func _on_continue() -> void:
	GameManager.prepare_night(SaveGame.night_reached)
	LoadingScreen.go_to(get_tree(), Screens.NIGHT_INTRO)


func _on_custom_night() -> void:
	get_tree().change_scene_to_file(Screens.CUSTOM_NIGHT)


func _on_extras() -> void:
	get_tree().change_scene_to_file(Screens.EXTRAS_MENU)


func _on_options() -> void:
	_options_panel.open()


func _on_quit() -> void:
	get_tree().quit()

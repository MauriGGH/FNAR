extends Control

## El menú principal. El fondo es la foto de los profes, que tiene toda la mitad
## izquierda en negro: ahí van el título y las opciones, alineados a la
## izquierda y en VT323 blanco, como un letrero de pantalla vieja.
##
## Se mueve con las flechas o con el mouse; la opción elegida lleva ">>" al
## lado. Abajo a la izquierda, la versión; abajo al centro, el aviso de que
## manteniendo Supr se borra la partida (y luego hay que confirmar).

const MENU_CONFIRM: GDScript = preload("res://scenes/main_menu/confirm_box.gd")

## El título va en cuatro renglones, como el logo de los juegos originales.
const TITLE_TEXT: String = "FIVE\nNIGHTS\nAT\nROCHA'S"
const TEXT_COLOR: Color = Color(0.95, 0.95, 0.93)
const DIM_COLOR: Color = Color(0.52, 0.53, 0.55)

## Todo medido a 1080p y escalado con el alto de la ventana.
const REFERENCE_HEIGHT: float = 1080.0
const TITLE_SIZE: float = 72.0
const OPTION_SIZE: float = 44.0
const SMALL_SIZE: float = 22.0

## La columna de texto, en fracción de la pantalla: cae sobre la zona negra.
const LEFT_MARGIN: float = 0.055
const TEXT_INDENT: float = 0.105
const TITLE_TOP: float = 0.055
const STARS_TOP: float = 0.40
const OPTIONS_TOP: float = 0.47
const LINE_HEIGHT: float = 0.072

## Borrar la partida: lo que hay que mantener Supr y lo que dice el aviso.
const WIPE_KEY: Key = KEY_DELETE
const WIPE_HOLD: float = 1.5
const WIPE_HINT: String = "Mantén Supr para borrar el progreso"
const WIPE_BAR_WIDTH: float = 260.0
const WIPE_BAR_HEIGHT: float = 6.0
const WIPE_BAR_COLOR: Color = Color(0.85, 0.25, 0.22)

var _list: MenuList = null
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
	# Mientras haya una capa encima, la lista del menú se esconde: si no, se
	# lee por detrás del negro.
	_options_panel.closed.connect(_show_list)
	_layout()
	resized.connect(_layout)
	# El menú tiene su propio ambiente: la pista principal, sus dos capas de
	# ambiente encima (las tres a la vez) y un hilo de estática.
	AudioManager.play_loop(Sounds.MENU_MUSIC)
	for layer: String in Sounds.MENU_LAYERS:
		AudioManager.play_loop(layer)
	AudioManager.play_loop(Sounds.CAMERA_STATIC)


## Al salir del menú se lleva su audio con él, que si no se cuela en la noche.
func _exit_tree() -> void:
	AudioManager.stop(Sounds.MENU_MUSIC)
	for layer: String in Sounds.MENU_LAYERS:
		AudioManager.stop(layer)
	AudioManager.stop(Sounds.CAMERA_STATIC)


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
	_list = MenuList.new()
	_list.top = OPTIONS_TOP
	_list.line_height = LINE_HEIGHT
	_list.option_size = OPTION_SIZE
	_list.left_margin = LEFT_MARGIN
	_list.text_indent = TEXT_INDENT
	add_child(_list)
	_list.add_action("Nueva partida", _on_new_game)
	_list.add_action("Continuar — noche %d" % SaveGame.night_reached, _on_continue,
		SaveGame.has_progress())
	_list.add_action("Custom Night", _on_custom_night, not locked)
	_list.add_action("Extras", _on_extras, not locked)
	_list.add_action("Opciones", _on_options)
	_list.add_action("Salir", _on_quit)
	_list.build()


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
	_confirm.cancelled.connect(_show_list)


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

	if _title != null:
		Fonts.apply(_title, Fonts.terminal(), _font_size(TITLE_SIZE))
		_title.position = Vector2(left, size.y * TITLE_TOP)
		_title.size = Vector2(size.x * 0.45, size.y * 0.34)
	if _stars != null:
		_stars.position = Vector2(left, size.y * STARS_TOP)
	if _list != null:
		_list.layout()
	if _version != null:
		Fonts.apply(_version, Fonts.terminal(), _font_size(SMALL_SIZE))
		_version.position = Vector2(size.x * 0.02, size.y * 0.945)
		_version.size = Vector2(size.x * 0.2, size.y * 0.05)
	if _wipe_hint != null:
		Fonts.apply(_wipe_hint, Fonts.terminal(), _font_size(SMALL_SIZE))
		_wipe_hint.position = Vector2(size.x * 0.3, size.y * 0.945)
		_wipe_hint.size = Vector2(size.x * 0.4, size.y * 0.05)


# --- Teclas -------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _options_panel != null and _options_panel.is_open:
		return
	if _confirm != null and _confirm.is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and _list.handle_key(key):
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
		_hide_list()
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


## Las capas de encima (opciones, confirmación) esconden la lista mientras
## están abiertas.
func _show_list() -> void:
	if _list != null:
		_list.visible = true


func _hide_list() -> void:
	if _list != null:
		_list.visible = false


func _on_options() -> void:
	_hide_list()
	_options_panel.open()


func _on_quit() -> void:
	get_tree().quit()

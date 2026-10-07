extends Control

## Custom Night: un nivel de 0 a 20 por profe, con su expediente de miniatura.
## No guarda récords: se elige, se juega y se vuelve.

const TITLE: String = "CUSTOM NIGHT"
const TITLE_SIZE: int = 34
const TEXT_COLOR: Color = Color(0.93, 0.9, 0.84)
const NAME_SIZE: int = 19
const LEVEL_SIZE: int = 26

const ROW_COLUMNS: int = 4
const ROW_SIZE: Vector2 = Vector2(232.0, 168.0)
const ROW_GAP: int = 12
const THUMB: Vector2 = Vector2(74.0, 74.0)
const ROW_FILL: Color = Color(0.1, 0.11, 0.13, 0.8)
const ROW_BORDER: Color = Color(0.72, 0.74, 0.76, 0.55)

## Los profes que se pueden configurar, con su clave en la tabla de noches.
const ENTRIES: Array[Dictionary] = [
	{"id": "barcosa", "key": Nights.BARCOSA, "name": "Barcosa"},
	{"id": "mamador", "key": Nights.MAMADOR, "name": "Mamador"},
	{"id": "urena", "key": Nights.URENA, "name": "Ureña"},
	{"id": "rochis", "key": Nights.ROCHIS, "name": "Rochis"},
	{"id": "audel", "key": Nights.AUDEL, "name": "Mago Eléctrico"},
	{"id": "juan", "key": Nights.JUAN_EXE, "name": "Juan.exe"},
	{"id": "armando", "key": Nights.ARMANDO, "name": "Armando Prompts"},
	{"id": "come_trabas", "key": Nights.COME_TRABAS, "name": "Come Trabas"},
]

## El tamaño de los botones de reto y de su nota de abajo.
const CHALLENGE_SIZE: Vector2 = Vector2(214.0, 40.0)
const CHALLENGE_FONT: int = 15
const CHALLENGE_LINE_SIZE: int = 15
const CHALLENGE_LINE_COLOR: Color = Color(0.7, 0.72, 0.74)
## Dónde empieza la rejilla de profes: por debajo de la fila de retos y su nota.
const GRID_TOP: float = 146.0

var _levels: Dictionary = {}
## El reto elegido, o cadena vacía si los niveles se pusieron a mano.
var _challenge: String = ""
var _level_labels: Dictionary = {}   # clave del profe -> Label de su nivel
var _challenge_line: Label = null


func _ready() -> void:
	MenuBackdrop.build(self)
	for entry: Dictionary in ENTRIES:
		_levels[str(entry["key"])] = 0
	_build_title()
	_build_challenges()
	_build_grid()
	_build_footer()


func _build_title() -> void:
	var label: Label = Label.new()
	label.text = TITLE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", TITLE_SIZE)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 24.0
	label.offset_bottom = 68.0
	add_child(label)


func _build_grid() -> void:
	var grid: GridContainer = GridContainer.new()
	grid.columns = ROW_COLUMNS
	grid.add_theme_constant_override("h_separation", ROW_GAP)
	grid.add_theme_constant_override("v_separation", ROW_GAP)
	grid.position = Vector2(
		(size.x - (ROW_SIZE.x + ROW_GAP) * ROW_COLUMNS + ROW_GAP) * 0.5, GRID_TOP)
	add_child(grid)
	for entry: Dictionary in ENTRIES:
		grid.add_child(_make_row(entry))


## Una fila: su expediente de miniatura, su nombre y el nivel con − y +.
func _make_row(entry: Dictionary) -> Control:
	var key: String = str(entry["key"])
	var row: Panel = Panel.new()
	row.custom_minimum_size = ROW_SIZE
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = ROW_FILL
	box.set_border_width_all(2)
	box.border_color = ROW_BORDER
	box.set_corner_radius_all(3)
	row.add_theme_stylebox_override("panel", box)

	var texture: Texture2D = Extras.dossier_texture(str(entry["id"]))
	if texture != null:
		var thumb: TextureRect = TextureRect.new()
		thumb.texture = texture
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.clip_contents = true
		thumb.position = Vector2((ROW_SIZE.x - THUMB.x) * 0.5, 8.0)
		thumb.size = THUMB
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(thumb)

	var name_label: Label = Label.new()
	name_label.text = str(entry["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", NAME_SIZE)
	name_label.add_theme_color_override("font_color", TEXT_COLOR)
	name_label.clip_text = true
	name_label.position = Vector2(6.0, 86.0)
	name_label.size = Vector2(ROW_SIZE.x - 12.0, 26.0)
	row.add_child(name_label)

	var level_label: Label = Label.new()
	level_label.name = "Level"
	level_label.text = "0"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.add_theme_font_size_override("font_size", LEVEL_SIZE)
	level_label.add_theme_color_override("font_color", TEXT_COLOR)
	level_label.position = Vector2(ROW_SIZE.x * 0.5 - 36.0, 118.0)
	level_label.size = Vector2(72.0, 38.0)
	row.add_child(level_label)

	_level_labels[key] = level_label
	row.add_child(_make_step(key, level_label, -1, Vector2(14.0, 118.0)))
	row.add_child(_make_step(key, level_label, 1, Vector2(ROW_SIZE.x - 54.0, 118.0)))
	return row


func _make_step(key: String, level_label: Label, step: int, at: Vector2) -> Button:
	var button: Button = UiButton.make("−" if step < 0 else "+")
	button.custom_minimum_size = Vector2(40.0, 38.0)
	button.add_theme_font_size_override("font_size", 24)
	button.position = at
	button.size = Vector2(40.0, 38.0)
	button.pressed.connect(_on_step.bind(key, level_label, step))
	return button


func _on_step(key: String, level_label: Label, step: int) -> void:
	var level: int = clampi(int(_levels.get(key, 0)) + step, 0, Nights.MAX_AI_LEVEL)
	_levels[key] = level
	level_label.text = str(level)
	# Cambiar un nivel a mano ya no es el reto: pasa a ser una noche cualquiera.
	_set_challenge("")


## La fila de retos: cada botón deja los niveles como pide, y lleva una palomita
## si ya se ganó.
func _build_challenges() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.offset_top = 74.0
	row.offset_bottom = 74.0 + CHALLENGE_SIZE.y
	add_child(row)
	for entry: Dictionary in CustomChallenges.LIST:
		var challenge_id: String = str(entry["id"])
		var button: Button = UiButton.make(_challenge_text(challenge_id))
		button.name = "Challenge_" + challenge_id
		button.custom_minimum_size = CHALLENGE_SIZE
		button.add_theme_font_size_override("font_size", CHALLENGE_FONT)
		button.pressed.connect(_on_challenge.bind(challenge_id))
		row.add_child(button)

	_challenge_line = Label.new()
	_challenge_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_challenge_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_challenge_line.add_theme_font_size_override("font_size", CHALLENGE_LINE_SIZE)
	_challenge_line.add_theme_color_override("font_color", CHALLENGE_LINE_COLOR)
	_challenge_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_challenge_line.offset_top = 74.0 + CHALLENGE_SIZE.y + 2.0
	_challenge_line.offset_bottom = _challenge_line.offset_top + 24.0
	add_child(_challenge_line)


## El nombre del reto, con palomita si ya se ganó.
func _challenge_text(challenge_id: String) -> String:
	var name: String = CustomChallenges.display_name(challenge_id)
	if SaveGame.has_won_challenge(challenge_id):
		return "%s  %s" % [CustomChallenges.DONE_MARK, name]
	return name


func _on_challenge(challenge_id: String) -> void:
	for key: String in Nights.ALL_KEYS:
		var level: int = int(CustomChallenges.levels_of(challenge_id).get(key, 0))
		_levels[key] = level
		var label: Label = _level_labels.get(key, null) as Label
		if label != null:
			label.text = str(level)
	_set_challenge(challenge_id)


func _set_challenge(challenge_id: String) -> void:
	_challenge = challenge_id
	if _challenge_line != null:
		_challenge_line.text = CustomChallenges.line(challenge_id)


func _build_footer() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.offset_top = -72.0
	row.offset_bottom = -20.0
	add_child(row)

	var play: Button = UiButton.make("Jugar")
	play.custom_minimum_size = Vector2(260.0, 48.0)
	play.pressed.connect(_on_play)
	row.add_child(play)

	var back: Button = UiButton.make("Volver")
	back.custom_minimum_size = Vector2(260.0, 48.0)
	back.pressed.connect(_on_back)
	row.add_child(back)


func _on_play() -> void:
	GameManager.prepare_custom_night(_levels, _challenge)
	LoadingScreen.go_to(get_tree(), Screens.NIGHT_INTRO)


func _on_back() -> void:
	get_tree().change_scene_to_file(
		Screens.EXTRAS_MENU if SaveGame.is_extras_unlocked() else Screens.MAIN_MENU)


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()

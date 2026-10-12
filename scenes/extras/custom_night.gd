extends Control

## Custom Night: un nivel de 0 a 20 por profe, con el retrato de cada uno como
## en los juegos originales. La cara sale recortada de su expediente (de su
## jumpscare si no tiene), en blanco y negro y oscura; la del profe elegido se
## ve a color y a todo brillo. Debajo de cada cara, el nombre en VT323 y el
## nivel entre flechas: `<  12  >`.
##
## Abajo, en texto como el resto de los menús, los retos y las dos salidas.
##
## El cursor vive en uno de dos sitios: la rejilla de retratos o la lista de
## abajo. Arriba y abajo lo pasan de uno a otro; izquierda y derecha siempre
## cambian el nivel del profe elegido, que es lo que dicen sus flechas.
##
## No guarda récords: se elige, se juega y se vuelve.

const TITLE: String = "CUSTOM NIGHT"
const HINT: String = "arriba y abajo para moverte · izquierda y derecha para el nivel · Enter · Esc"

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

const GREYSCALE_SHADER: String = "res://scenes/ui/greyscale.gdshader"
## Lo apagado que se ve un retrato que no está elegido.
const DIM_GREY: float = 1.0
const DIM_DARKEN: float = 0.55

## La rejilla, medida a 1080p y escalada con el alto de la ventana.
const COLUMNS: int = 4
const PORTRAIT: float = 150.0
const COLUMN_GAP: float = 58.0
const ROW_GAP: float = 26.0
const NAME_SIZE: float = 22.0
const LEVEL_SIZE: float = 30.0
## Lo que hay entre la cara, el nombre y el nivel, y lo que ocupa cada uno.
const NAME_TOP: float = 8.0
const NAME_HEIGHT: float = 30.0
const LEVEL_HEIGHT: float = 38.0
## Dónde empieza la rejilla y dónde la lista de abajo, en fracción del alto.
const GRID_TOP: float = 0.17
const LIST_TOP: float = 0.645
const LIST_LINE: float = 0.04
const LIST_SIZE: float = 26.0

const LEFT_ARROW: String = "<"
const RIGHT_ARROW: String = ">"

## Dónde está el cursor: en los retratos o en la lista de abajo.
enum Zone { GRID, LIST }

var _levels: Dictionary = {}
## El reto elegido, o cadena vacía si los niveles se pusieron a mano.
var _challenge: String = ""
var _zone: Zone = Zone.GRID
var _selected: int = 0
## Un diccionario por retrato: sus nodos, para pintarlos y moverlos.
var _cells: Array[Dictionary] = []

var _title: Label = null
var _hint: Label = null
var _challenge_line: Label = null
var _list: MenuList = null


func _ready() -> void:
	MenuBackdrop.build(self)
	for entry: Dictionary in ENTRIES:
		_levels[str(entry["key"])] = 0
	_title = MenuStyle.title(self, TITLE)
	_build_grid()
	_build_list()
	_challenge_line = MenuStyle.label("", MenuStyle.DIM)
	add_child(_challenge_line)
	_hint = MenuStyle.hint(self, HINT)
	_layout()
	resized.connect(_layout)
	_refresh_cells()


# --- Los retratos -------------------------------------------------------------

func _build_grid() -> void:
	for i: int in ENTRIES.size():
		_cells.append(_make_cell(i, ENTRIES[i]))


## Un retrato: la cara, el nombre debajo y el nivel entre sus dos flechas.
func _make_cell(index: int, entry: Dictionary) -> Dictionary:
	var character_id: String = str(entry["id"])

	var face: TextureRect = TextureRect.new()
	face.texture = _face_of(character_id)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Con el recorte ya cuadrado esto no recorta nada; al profe que se cae a su
	# jumpscare sí le saca el cuadro del centro.
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.clip_contents = true
	face.mouse_filter = Control.MOUSE_FILTER_STOP
	face.mouse_entered.connect(_on_cell_entered.bind(index))
	face.gui_input.connect(_on_cell_input.bind(index))
	if ResourceLoader.exists(GREYSCALE_SHADER):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load(GREYSCALE_SHADER)
		face.material = material
	add_child(face)

	var name_label: Label = MenuStyle.label(str(entry["name"]), MenuStyle.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	add_child(name_label)

	var level: Label = MenuStyle.label("0", MenuStyle.TEXT)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(level)

	return {
		"id": character_id, "key": str(entry["key"]), "face": face,
		"name": name_label, "level": level,
		"left": _make_arrow(index, LEFT_ARROW, -1),
		"right": _make_arrow(index, RIGHT_ARROW, 1),
	}


## Una de las dos flechas del nivel. Se puede picar con el mouse.
func _make_arrow(index: int, text: String, step: int) -> Label:
	var arrow: Label = MenuStyle.label(text, MenuStyle.DIM)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_STOP
	arrow.mouse_entered.connect(_on_cell_entered.bind(index))
	arrow.gui_input.connect(_on_arrow_input.bind(index, step))
	add_child(arrow)
	return arrow


## La cara: el recorte de su expediente y, si no tiene, su jumpscare entero,
## que ya es un primer plano.
func _face_of(character_id: String) -> Texture2D:
	var face: Texture2D = CustomNightFaces.face_texture(character_id)
	return face if face != null else Extras.jumpscare_texture(character_id)


## Colores y niveles de los ocho: el elegido a color, los demás apagados.
func _refresh_cells() -> void:
	for i: int in _cells.size():
		var cell: Dictionary = _cells[i]
		var chosen: bool = _zone == Zone.GRID and i == _selected
		var material: ShaderMaterial = (cell["face"] as TextureRect).material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("amount", 0.0 if chosen else DIM_GREY)
			material.set_shader_parameter("darken", 0.0 if chosen else DIM_DARKEN)
		var tint: Color = MenuStyle.TEXT if chosen else MenuStyle.DIM
		(cell["name"] as Label).add_theme_color_override("font_color", tint)
		(cell["level"] as Label).add_theme_color_override("font_color", tint)
		(cell["level"] as Label).text = str(_levels.get(str(cell["key"]), 0))
		# Las flechas solo se marcan en el que está elegido.
		for side: String in ["left", "right"]:
			(cell[side] as Label).add_theme_color_override("font_color",
				MenuStyle.MARKER_COLOR if chosen else MenuStyle.DISABLED)


# --- La lista de abajo --------------------------------------------------------

func _build_list() -> void:
	_list = MenuList.new()
	_list.top = LIST_TOP
	_list.option_size = LIST_SIZE
	_list.line_height = LIST_LINE
	add_child(_list)
	for entry: Dictionary in CustomChallenges.LIST:
		var challenge_id: String = str(entry["id"])
		_list.add_action(_challenge_text(challenge_id), _on_challenge.bind(challenge_id))
	_list.add_action("Jugar", _on_play)
	_list.add_action("Volver", _on_back)
	_list.build()
	_list.set_active(false)
	# Picar o pasar por la lista trae el cursor aquí.
	_list.selection_changed.connect(func(_index: int) -> void: _focus_list())


## El nombre del reto, con palomita si ya se ganó.
func _challenge_text(challenge_id: String) -> String:
	var name: String = CustomChallenges.display_name(challenge_id)
	if SaveGame.has_won_challenge(challenge_id):
		return "%s  %s" % [CustomChallenges.DONE_MARK, name]
	return "Reto: %s" % name


func _on_challenge(challenge_id: String) -> void:
	for key: String in Nights.ALL_KEYS:
		_levels[key] = int(CustomChallenges.levels_of(challenge_id).get(key, 0))
	_set_challenge(challenge_id)
	_refresh_cells()


func _set_challenge(challenge_id: String) -> void:
	_challenge = challenge_id
	if _challenge_line != null:
		_challenge_line.text = CustomChallenges.line(challenge_id)


# --- Colocación ---------------------------------------------------------------

func _layout() -> void:
	MenuStyle.place_title(_title, size, 0.055)
	MenuStyle.place_hint(_hint, size)
	if _list != null:
		_list.layout()
	_layout_grid()
	if _challenge_line != null:
		# A la derecha de la lista, que es corta y deja todo ese hueco libre.
		_challenge_line.add_theme_font_size_override("font_size",
			MenuStyle.font_size(MenuStyle.SMALL_SIZE, size.y))
		_challenge_line.position = Vector2(size.x * 0.46, size.y * (LIST_TOP + 0.02))
		_challenge_line.size = Vector2(size.x * 0.5, size.y * 0.05)


func _layout_grid() -> void:
	var scale: float = size.y / MenuStyle.REFERENCE_HEIGHT
	var portrait: float = PORTRAIT * scale
	var column_gap: float = COLUMN_GAP * scale
	var row_gap: float = ROW_GAP * scale
	var name_top: float = NAME_TOP * scale
	var name_height: float = NAME_HEIGHT * scale
	var level_height: float = LEVEL_HEIGHT * scale
	var cell_height: float = portrait + name_top + name_height + level_height
	var grid_width: float = portrait * float(COLUMNS) + column_gap * float(COLUMNS - 1)
	var left: float = (size.x - grid_width) * 0.5
	var top: float = size.y * GRID_TOP
	var name_size: int = MenuStyle.font_size(NAME_SIZE, size.y)
	var level_size: int = MenuStyle.font_size(LEVEL_SIZE, size.y)

	for i: int in _cells.size():
		var cell: Dictionary = _cells[i]
		var at: Vector2 = Vector2(
			left + float(i % COLUMNS) * (portrait + column_gap),
			top + float(i / COLUMNS) * (cell_height + row_gap))

		var face: TextureRect = cell["face"]
		face.position = at
		face.size = Vector2(portrait, portrait)

		# El nombre se sale un poco del retrato por los dos lados, porque
		# "Armando Prompts" no cabe en 150 px y se cortaría.
		var overhang: float = column_gap * 0.8
		var name_label: Label = cell["name"]
		name_label.add_theme_font_size_override("font_size", name_size)
		name_label.position = Vector2(at.x - overhang * 0.5, at.y + portrait + name_top)
		name_label.size = Vector2(portrait + overhang, name_height)

		var level: Label = cell["level"]
		level.add_theme_font_size_override("font_size", level_size)
		level.position = Vector2(at.x, at.y + portrait + name_top + name_height)
		level.size = Vector2(portrait, level_height)

		# Las flechas, pegadas a los lados del número.
		var arrow_width: float = portrait * 0.3
		var left_arrow: Label = cell["left"]
		left_arrow.add_theme_font_size_override("font_size", level_size)
		left_arrow.position = Vector2(at.x, level.position.y)
		left_arrow.size = Vector2(arrow_width, level_height)
		var right_arrow: Label = cell["right"]
		right_arrow.add_theme_font_size_override("font_size", level_size)
		right_arrow.position = Vector2(at.x + portrait - arrow_width, level.position.y)
		right_arrow.size = Vector2(arrow_width, level_height)


# --- Cursor y niveles ---------------------------------------------------------

func _focus_grid(index: int) -> void:
	_zone = Zone.GRID
	_selected = clampi(index, 0, _cells.size() - 1)
	_list.set_active(false)
	_refresh_cells()


func _focus_list() -> void:
	if _zone == Zone.LIST:
		return
	_zone = Zone.LIST
	_list.set_active(true)
	_refresh_cells()


## Sube o baja el nivel del profe elegido. Tocarlo a mano deja de contar como
## reto, aunque los niveles sigan siendo los suyos.
func _change_level(step: int) -> void:
	if _zone != Zone.GRID or _cells.is_empty():
		return
	var key: String = str(_cells[_selected]["key"])
	var level: int = clampi(int(_levels.get(key, 0)) + step, 0, Nights.MAX_AI_LEVEL)
	if level == int(_levels.get(key, 0)):
		return
	_levels[key] = level
	_set_challenge("")
	MenuStyle.blip()
	_refresh_cells()


## Se mueve entre retratos; pasado el último se baja a la lista.
func _move_in_grid(step: int) -> void:
	var next: int = _selected + step
	if next < 0:
		next = _cells.size() - 1
	elif next >= _cells.size():
		_focus_list()
		_list.select(0)
		MenuStyle.blip()
		return
	_focus_grid(next)
	MenuStyle.blip()


func _on_cell_entered(index: int) -> void:
	if _zone == Zone.GRID and _selected == index:
		return
	_focus_grid(index)
	MenuStyle.blip()


func _on_cell_input(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed:
		_focus_grid(index)


## Picar una flecha mueve el nivel de ese profe, esté elegido o no.
func _on_arrow_input(event: InputEvent, index: int, step: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	_focus_grid(index)
	_change_level(step)


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.keycode == KEY_ESCAPE and not key.echo:
		_on_back()
		get_viewport().set_input_as_handled()
		return
	if _zone == Zone.GRID:
		_grid_key(key)
		return
	# En la lista, subir desde el primer renglón regresa a los retratos.
	if key.keycode in [KEY_UP, KEY_W] and _list.selected() == 0:
		_focus_grid(_cells.size() - 1)
		MenuStyle.blip()
		get_viewport().set_input_as_handled()
		return
	if _list.handle_key(key):
		get_viewport().set_input_as_handled()


func _grid_key(key: InputEventKey) -> void:
	match key.keycode:
		KEY_LEFT, KEY_A:
			_change_level(-1)
		KEY_RIGHT, KEY_D:
			_change_level(1)
		KEY_UP, KEY_W:
			_move_in_grid(-1)
		KEY_DOWN, KEY_S:
			_move_in_grid(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			# Aceptar en un retrato es subirle el nivel, como en la lista.
			if not key.echo:
				_change_level(1)
		_:
			return
	get_viewport().set_input_as_handled()


func _on_play() -> void:
	GameManager.prepare_custom_night(_levels, _challenge)
	LoadingScreen.go_to(get_tree(), Screens.NIGHT_INTRO)


func _on_back() -> void:
	get_tree().change_scene_to_file(
		Screens.EXTRAS_MENU if SaveGame.is_extras_unlocked() else Screens.MAIN_MENU)

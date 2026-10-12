extends Control

## Custom Night: un nivel de 0 a 20 por profe. Todo es texto, con el mismo
## acabado que los demás menús: VT323 blanco a la izquierda y ">>" en el
## renglón elegido. El nivel se sube y se baja con izquierda y derecha (o con
## clic), y los retos de abajo dejan los ocho niveles puestos de un golpe.
##
## No guarda récords: se elige, se juega y se vuelve.

const TITLE: String = "CUSTOM NIGHT"
const HINT: String = "flechas o W/S para moverte · izquierda y derecha para el nivel · Enter · Esc"
## Son muchos renglones, así que van más chicos y más juntos que en otros menús.
const OPTION_SIZE: float = 27.0
const LINE_HEIGHT: float = 0.045
const LIST_TOP: float = 0.17

## Los profes que se pueden configurar, con su clave en la tabla de noches.
const ENTRIES: Array[Dictionary] = [
	{"key": Nights.BARCOSA, "name": "Barcosa"},
	{"key": Nights.MAMADOR, "name": "Mamador"},
	{"key": Nights.URENA, "name": "Ureña"},
	{"key": Nights.ROCHIS, "name": "Rochis"},
	{"key": Nights.AUDEL, "name": "Mago Eléctrico"},
	{"key": Nights.JUAN_EXE, "name": "Juan.exe"},
	{"key": Nights.ARMANDO, "name": "Armando Prompts"},
	{"key": Nights.COME_TRABAS, "name": "Come Trabas"},
]

var _levels: Dictionary = {}
## El reto elegido, o cadena vacía si los niveles se pusieron a mano.
var _challenge: String = ""
var _title: Label = null
var _hint: Label = null
var _challenge_line: Label = null
var _list: MenuList = null


func _ready() -> void:
	MenuBackdrop.build(self)
	for entry: Dictionary in ENTRIES:
		_levels[str(entry["key"])] = 0
	_title = MenuStyle.title(self, TITLE)
	_build_list()
	_challenge_line = MenuStyle.label("", MenuStyle.DIM)
	add_child(_challenge_line)
	_hint = MenuStyle.hint(self, HINT)
	_layout()
	resized.connect(_layout)


func _build_list() -> void:
	_list = MenuList.new()
	_list.top = LIST_TOP
	_list.option_size = OPTION_SIZE
	_list.line_height = LINE_HEIGHT
	add_child(_list)

	# Un renglón por profe, con su nivel como número.
	for entry: Dictionary in ENTRIES:
		var key: String = str(entry["key"])
		_list.add_value(str(entry["name"]),
			func() -> float: return float(_levels.get(key, 0)),
			func(value: float) -> void: _on_level_changed(key, value),
			1.0, 0.0, float(Nights.MAX_AI_LEVEL), false)

	# Los retos, con palomita si ya se ganaron.
	for entry: Dictionary in CustomChallenges.LIST:
		var challenge_id: String = str(entry["id"])
		_list.add_action(_challenge_text(challenge_id), _on_challenge.bind(challenge_id))

	_list.add_action("Jugar", _on_play)
	_list.add_action("Volver", _on_back)
	_list.build()


## Tocar un nivel a mano deja de contar como reto.
func _on_level_changed(key: String, value: float) -> void:
	_levels[key] = roundi(value)
	_set_challenge("")


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
	_list.refresh()


func _set_challenge(challenge_id: String) -> void:
	_challenge = challenge_id
	if _challenge_line != null:
		_challenge_line.text = CustomChallenges.line(challenge_id)


func _layout() -> void:
	MenuStyle.place_title(_title, size, 0.055)
	MenuStyle.place_hint(_hint, size)
	if _list != null:
		_list.layout()
	if _challenge_line != null:
		_challenge_line.add_theme_font_size_override("font_size",
			MenuStyle.font_size(MenuStyle.SMALL_SIZE, size.y))
		_challenge_line.position = Vector2(size.x * MenuStyle.TEXT_INDENT, size.y * 0.9)
		_challenge_line.size = Vector2(size.x * 0.8, size.y * 0.05)


func _on_play() -> void:
	GameManager.prepare_custom_night(_levels, _challenge)
	LoadingScreen.go_to(get_tree(), Screens.NIGHT_INTRO)


func _on_back() -> void:
	get_tree().change_scene_to_file(
		Screens.EXTRAS_MENU if SaveGame.is_extras_unlocked() else Screens.MAIN_MENU)


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.keycode == KEY_ESCAPE and not key.echo:
		_on_back()
		get_viewport().set_input_as_handled()
		return
	if _list.handle_key(key):
		get_viewport().set_input_as_handled()

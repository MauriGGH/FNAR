extends Control

## El final del juego, al pasar la noche 6. Sencillo a propósito: el gancho de
## verdad lo deja el último recorte de periódico.

const TITLE: String = "SOBREVIVISTE LAS SEIS NOCHES"
const BODY: String = "La coordinación quedó clausurada.\nEl responsable sigue sin ser identificado."
const HINT: String = "flechas o W/S · Enter para elegir"
const BODY_TOP: float = 0.3
const LIST_TOP: float = 0.52

var _title: Label = null
var _body: Label = null
var _hint: Label = null
var _list: MenuList = null


func _ready() -> void:
	MenuBackdrop.build(self)
	_title = MenuStyle.title(self, TITLE)
	_body = MenuStyle.label(BODY, MenuStyle.DIM)
	add_child(_body)

	_list = MenuList.new()
	_list.top = LIST_TOP
	add_child(_list)
	_list.add_action("Extras",
		func() -> void: get_tree().change_scene_to_file(Screens.EXTRAS_MENU),
		SaveGame.is_extras_unlocked())
	_list.add_action("Volver al menú",
		func() -> void: get_tree().change_scene_to_file(Screens.MAIN_MENU))
	_list.build()

	_hint = MenuStyle.hint(self, HINT)
	_layout()
	resized.connect(_layout)


func _layout() -> void:
	MenuStyle.place_title(_title, size, 0.16)
	MenuStyle.place_hint(_hint, size)
	if _body != null:
		_body.add_theme_font_size_override("font_size",
			MenuStyle.font_size(MenuStyle.SMALL_SIZE * 1.4, size.y))
		_body.position = Vector2(size.x * MenuStyle.LEFT_MARGIN, size.y * BODY_TOP)
		_body.size = Vector2(size.x * 0.7, size.y * 0.15)
	if _list != null:
		_list.layout()


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.keycode == KEY_ESCAPE and not key.echo:
		get_tree().change_scene_to_file(Screens.MAIN_MENU)
		get_viewport().set_input_as_handled()
		return
	if _list.handle_key(key):
		get_viewport().set_input_as_handled()

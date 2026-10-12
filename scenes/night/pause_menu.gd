extends Control

## La pausa de la noche. Se abre con Escape, siempre que Escape no esté
## ocupado en otra cosa (la PC, el breaker, la sala de servidores o la foto de
## Ureña abierta): de eso se encarga el night.gd, que es quien sabe qué hay
## arriba. Con la pausa puesta el reloj y los profes se detienen.
##
## El acabado es el de todos los menús: negro, VT323 y la lista de MenuList.

signal resumed()
signal menu_requested()
## Pidió volver a ver el recuadro de controles.
signal controls_requested()

const TITLE: String = "PAUSA"
const HINT: String = "flechas o W/S · Enter para elegir · Esc para continuar"
## Dónde empieza la lista, en fracción del alto.
const LIST_TOP: float = 0.38

var is_open: bool = false
## El night.gd lo mantiene al día: true cuando Escape ya lo usa otra cosa.
var blocked: bool = false

var _title: Label = null
var _hint: Label = null
var _list: MenuList = null
var _options: OptionsPanel = null


func _ready() -> void:
	# Con el árbol pausado este nodo tiene que seguir respondiendo.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	# Se come los clics: con la pausa puesta no se juega por abajo.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_layout()
	resized.connect(_layout)


func _build() -> void:
	MenuStyle.backdrop(self)
	_title = MenuStyle.title(self, TITLE)

	_list = MenuList.new()
	_list.top = LIST_TOP
	add_child(_list)
	_list.add_action("Continuar", close)
	_list.add_action("Controles", func() -> void: controls_requested.emit())
	_list.add_action("Opciones", func() -> void: _options.open())
	_list.add_action("Volver al menú", func() -> void: menu_requested.emit())
	_list.build()

	_hint = MenuStyle.hint(self, HINT)
	# Encima de todo lo demás de la pausa.
	_options = OptionsPanel.build(self)


func _layout() -> void:
	MenuStyle.place_title(_title, size)
	MenuStyle.place_hint(_hint, size)
	if _list != null:
		_list.layout()


## Escape abre y cierra la pausa, salvo que las opciones estén abiertas: ahí
## Escape es para cerrarlas, y de eso se encarga el propio panel. El resto de
## las teclas se las queda la lista.
func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if _options != null and _options.is_open:
		return
	if key.keycode == Controls.PAUSE_KEY:
		if key.echo:
			return
		if is_open:
			close()
		elif not blocked:
			open()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if is_open and _list.handle_key(key):
		get_viewport().set_input_as_handled()


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_layout()
	get_tree().paused = true


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	resumed.emit()

class_name OptionsPanel
extends Control

## El menú de opciones: el volumen de cada bus de audio y la pantalla completa.
## Es una capa que se abre encima de lo que haya, así que sirve igual en el menú
## principal y en la pausa de una noche, sin cambiar de escena.
##
## Los volúmenes son barras de bloques "■■■■■□□□□□" que se mueven con izquierda
## y derecha o con un clic en el punto de la barra. Todo lo que se toca aquí se
## guarda al momento en save.cfg; no hay botón de aceptar ni de cancelar.

## Se cerró: quien lo abrió puede volver a lo suyo.
signal closed()

const TITLE: String = "OPCIONES"
const HINT: String = "izquierda y derecha para el volumen · Esc para volver"
const LIST_TOP: float = 0.3
## El salto de cada paso del volumen: una décima, como los bloques de la barra.
const VOLUME_STEP: float = 0.1

var is_open: bool = false

var _title: Label = null
var _hint: Label = null
var _list: MenuList = null
## En qué renglón de la lista está la pantalla completa, para refrescar su texto.
var _fullscreen_row: int = -1


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
	_layout()
	resized.connect(_layout)
	AudioManager.bus_volume_changed.connect(_on_bus_volume_changed)
	DisplayManager.fullscreen_changed.connect(_on_fullscreen_changed)


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_refresh()
	_layout()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


func _build() -> void:
	MenuStyle.backdrop(self)
	_title = MenuStyle.title(self, TITLE)

	_list = MenuList.new()
	_list.top = LIST_TOP
	add_child(_list)
	for bus: String in Sounds.MIXER_BUSES:
		_list.add_value(bus,
			func() -> float: return AudioManager.bus_volume(bus),
			func(value: float) -> void: AudioManager.set_bus_volume(bus, value),
			VOLUME_STEP, 0.0, 1.0)
	_fullscreen_row = Sounds.MIXER_BUSES.size()
	_list.add_action(_fullscreen_text(), DisplayManager.toggle)
	_list.add_action("Volver", close)
	_list.build()

	_hint = MenuStyle.hint(self, HINT)


func _layout() -> void:
	MenuStyle.place_title(_title, size)
	MenuStyle.place_hint(_hint, size)
	if _list != null:
		_list.layout()


func _refresh() -> void:
	if _list != null:
		_list.refresh()


func _fullscreen_text() -> String:
	return "Pantalla completa: %s  (F11)" % ("sí" if DisplayManager.is_fullscreen() else "no")


## El AudioManager avisa del cambio: así la barra también se mueve si lo cambió
## otra cosa (el menú de pruebas, por ejemplo).
func _on_bus_volume_changed(_bus: String, _value: float) -> void:
	_refresh()


func _on_fullscreen_changed(_is_fullscreen: bool) -> void:
	if _list != null and _fullscreen_row >= 0:
		_list.set_text(_fullscreen_row, _fullscreen_text())


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.keycode == KEY_ESCAPE and not key.echo:
		close()
		get_viewport().set_input_as_handled()
		return
	if _list.handle_key(key):
		get_viewport().set_input_as_handled()

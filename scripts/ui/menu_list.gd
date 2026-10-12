class_name MenuList
extends Control

## La lista de opciones de todos los menús, como la del menú principal: texto
## en VT323 blanco alineado a la izquierda, con ">>" al lado de la elegida. No
## hay botones con caja en ninguna parte.
##
## Se mueve con las flechas o con W/S, se acepta con Enter o espacio y también
## funciona con el mouse (pasar por encima elige, clic acepta). Cada movimiento
## y cada aceptación suenan.
##
## Hay dos clases de renglón:
##   - **acción**: hace algo al aceptarlo (su Callable).
##   - **valor**: se cambia con izquierda y derecha, y se enseña como barra de
##     bloques (los volúmenes) o como número (los niveles de la Custom Night).

enum Kind { ACTION, VALUE }

## Una barra de bloques: "■■■■■□□□□□".
const BLOCKS: int = 10
const BLOCK_FULL: String = "■"
const BLOCK_EMPTY: String = "□"
const MARKER: String = ">>"

## Lo alto de un renglón, en fracción del alto de la pantalla, y el tamaño de
## letra. Las pantallas con muchos renglones (la Custom Night) los bajan.
var line_height: float = 0.072
var option_size: float = MenuStyle.OPTION_SIZE
## Dónde cae la columna, en fracción del ancho.
var left_margin: float = MenuStyle.LEFT_MARGIN
var text_indent: float = MenuStyle.TEXT_INDENT
## Dónde empieza la lista, en fracción del alto.
var top: float = 0.45
## Lo que se separa el valor del nombre, en fracción del ancho.
var value_gap: float = 0.30

var _options: Array[Dictionary] = []
var _rows: Array[Label] = []
var _values: Array[Label] = []
var _marker: Label = null
var _selected: int = 0


func _ready() -> void:
	# Las capas que se abren con el juego pausado (la pausa, las opciones)
	# tienen que seguir respondiendo.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# --- Armado -------------------------------------------------------------------

## Un renglón que hace algo. enabled en false lo deja apagado y el cursor se lo
## salta, como las opciones bloqueadas del menú principal.
func add_action(text: String, action: Callable, enabled: bool = true) -> void:
	_options.append({
		"kind": Kind.ACTION, "text": text, "action": action, "enabled": enabled,
	})


## Un renglón con un valor que se cambia con izquierda y derecha. get_value y
## set_value son los que mandan: la lista no guarda el valor, lo pregunta.
## blocks dibuja la barra de bloques; sin él se enseña el número pelón.
func add_value(text: String, get_value: Callable, set_value: Callable,
		step: float, minimum: float, maximum: float, blocks: bool = true) -> void:
	_options.append({
		"kind": Kind.VALUE, "text": text, "enabled": true, "blocks": blocks,
		"get_value": get_value, "set_value": set_value,
		"step": step, "min": minimum, "max": maximum,
	})


## Cambia el texto de un renglón ya armado (la pantalla completa, que dice si
## está puesta o no).
func set_text(index: int, text: String) -> void:
	if index < 0 or index >= _options.size():
		return
	_options[index]["text"] = text
	if index < _rows.size():
		_rows[index].text = text


## Tira la lista de antes. La usan las pantallas que se rearman (Extras).
func clear_options() -> void:
	_options.clear()
	for row: Label in _rows:
		row.queue_free()
	for value: Label in _values:
		value.queue_free()
	_rows.clear()
	_values.clear()


## Arma los renglones. Hay que llamarla después de meter las opciones.
func build() -> void:
	for row: Label in _rows:
		row.queue_free()
	for value: Label in _values:
		value.queue_free()
	_rows.clear()
	_values.clear()

	if _marker == null:
		_marker = MenuStyle.label(MARKER, MenuStyle.MARKER_COLOR)
		add_child(_marker)

	for i: int in _options.size():
		var entry: Dictionary = _options[i]
		var row: Label = MenuStyle.label(str(entry["text"]), _color_of(entry))
		# Los renglones sí reciben mouse: pasar por encima los elige.
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(_on_row_entered.bind(i))
		row.gui_input.connect(_on_row_input.bind(i))
		add_child(row)
		_rows.append(row)

		var value: Label = MenuStyle.label("", MenuStyle.DIM)
		value.mouse_filter = Control.MOUSE_FILTER_STOP
		value.mouse_entered.connect(_on_row_entered.bind(i))
		value.gui_input.connect(_on_value_input.bind(i))
		add_child(value)
		_values.append(value)

	_selected = _first_enabled()
	refresh()
	layout()


func _color_of(entry: Dictionary) -> Color:
	return MenuStyle.TEXT if bool(entry["enabled"]) else MenuStyle.DISABLED


# --- Colocación ---------------------------------------------------------------

## Recoloca todo con el tamaño de la ventana. La pantalla la llama en resized.
func layout() -> void:
	var left: float = size.x * left_margin
	var indent: float = size.x * text_indent
	var line: float = size.y * line_height
	var font: int = MenuStyle.font_size(option_size, size.y)

	if _marker != null:
		_marker.add_theme_font_size_override("font_size", font)
		_marker.size = Vector2(indent - left, line)
	for i: int in _rows.size():
		var row: Label = _rows[i]
		row.add_theme_font_size_override("font_size", font)
		row.position = Vector2(indent, size.y * top + float(i) * line)
		row.size = Vector2(size.x * value_gap, line)
		var value: Label = _values[i]
		value.add_theme_font_size_override("font_size", font)
		value.position = Vector2(indent + size.x * value_gap, row.position.y)
		value.size = Vector2(size.x * 0.3, line)
	_place_marker()


func _place_marker() -> void:
	if _marker == null or _selected < 0 or _selected >= _rows.size():
		return
	_marker.visible = _rows.size() > 0
	_marker.position = Vector2(size.x * left_margin, _rows[_selected].position.y)


## Vuelve a escribir los textos: los valores y el color de cada renglón.
func refresh() -> void:
	for i: int in _options.size():
		var entry: Dictionary = _options[i]
		_rows[i].text = str(entry["text"])
		_rows[i].add_theme_color_override("font_color", _color_of(entry))
		_values[i].text = _value_text(entry)
	_place_marker()


## Lo que se enseña a la derecha de un renglón de valor.
func _value_text(entry: Dictionary) -> String:
	if int(entry["kind"]) != Kind.VALUE:
		return ""
	var value: float = float((entry["get_value"] as Callable).call())
	if not bool(entry["blocks"]):
		return "%d" % roundi(value)
	var span: float = maxf(float(entry["max"]) - float(entry["min"]), 0.0001)
	var filled: int = clampi(roundi((value - float(entry["min"])) / span * float(BLOCKS)),
		0, BLOCKS)
	return "%s%s  %d %%" % [BLOCK_FULL.repeat(filled),
		BLOCK_EMPTY.repeat(BLOCKS - filled), roundi(value / span * 100.0)]


# --- Selección ----------------------------------------------------------------

func _first_enabled() -> int:
	for i: int in _options.size():
		if bool(_options[i]["enabled"]):
			return i
	return 0


func selected() -> int:
	return _selected


func select(index: int, quiet: bool = true) -> void:
	if index < 0 or index >= _options.size() or not bool(_options[index]["enabled"]):
		return
	if index == _selected:
		return
	_selected = index
	_place_marker()
	if not quiet:
		MenuStyle.blip()


## Se mueve saltándose lo apagado, y da la vuelta al llegar al final.
func move(step: int) -> void:
	if _options.is_empty():
		return
	var index: int = _selected
	for _i: int in _options.size():
		index = wrapi(index + step, 0, _options.size())
		if bool(_options[index]["enabled"]):
			select(index, false)
			return


## Acepta el renglón elegido: su acción, o nada si es de valor.
func accept() -> void:
	if _selected < 0 or _selected >= _options.size():
		return
	var entry: Dictionary = _options[_selected]
	if not bool(entry["enabled"]):
		return
	if int(entry["kind"]) != Kind.ACTION:
		# En un renglón de valor, aceptar es subirlo: así también se puede con
		# el mouse sin tener que atinarle a un bloque.
		change(1)
		return
	MenuStyle.blip(true)
	(entry["action"] as Callable).call()


## Sube o baja el valor del renglón elegido.
func change(step: int) -> void:
	if _selected < 0 or _selected >= _options.size():
		return
	var entry: Dictionary = _options[_selected]
	if int(entry["kind"]) != Kind.VALUE:
		return
	var value: float = float((entry["get_value"] as Callable).call())
	var next: float = clampf(value + float(step) * float(entry["step"]),
		float(entry["min"]), float(entry["max"]))
	if is_equal_approx(next, value):
		return
	(entry["set_value"] as Callable).call(next)
	MenuStyle.blip()
	refresh()


# --- Teclas y mouse -----------------------------------------------------------

## Las teclas las lee la pantalla y nos las pasa, para que cada una decida si le
## tocan a la lista o a otra cosa (Esc, por ejemplo). Devuelve true si la usó.
func handle_key(key: InputEventKey) -> bool:
	if key == null or not key.pressed:
		return false
	match key.keycode:
		KEY_UP, KEY_W:
			move(-1)
			return true
		KEY_DOWN, KEY_S:
			move(1)
			return true
		KEY_LEFT, KEY_A:
			change(-1)
			return true
		KEY_RIGHT, KEY_D:
			change(1)
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if not key.echo:
				accept()
			return true
	return false


func _on_row_entered(index: int) -> void:
	select(index, false)


func _on_row_input(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	select(index)
	if click.button_index == MOUSE_BUTTON_RIGHT:
		# Clic derecho en un renglón de valor lo baja.
		change(-1)
		return
	if click.button_index == MOUSE_BUTTON_LEFT:
		accept()


## Clic sobre la barra de bloques: se va justo al punto donde se le dio. El
## ancho que ocupa la barra se saca de la propia fuente, no se adivina.
func _on_value_input(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	select(index)
	var entry: Dictionary = _options[index]
	if int(entry["kind"]) != Kind.VALUE or click.button_index != MOUSE_BUTTON_LEFT:
		_on_row_input(event, index)
		return
	if not bool(entry["blocks"]):
		change(1)
		return
	var bar: float = _bar_width(index)
	var fraction: float = clampf(click.position.x / maxf(bar, 1.0), 0.0, 1.0)
	var span: float = float(entry["max"]) - float(entry["min"])
	(entry["set_value"] as Callable).call(float(entry["min"]) + fraction * span)
	MenuStyle.blip()
	refresh()


## Lo que mide la barra de bloques en pantalla, para saber dónde se dio el clic.
func _bar_width(index: int) -> float:
	var font: Font = Fonts.terminal()
	var size_px: int = MenuStyle.font_size(option_size, size.y)
	if font == null:
		return _values[index].size.x
	return font.get_string_size(BLOCK_FULL.repeat(BLOCKS),
		HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x

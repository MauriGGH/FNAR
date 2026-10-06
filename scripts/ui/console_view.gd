class_name ConsoleView
extends Control

## Base de cualquier consola del juego: el historial en pantalla, la línea que
## se está escribiendo, el cursor que parpadea, las flechas del historial y la
## escritura automática del asistente.
## Quien herede de aquí solo implementa prompt() y _run(); la escena necesita
## un Label llamado OutputLabel.

signal typing_finished()

## Cuántas líneas se guardan en el historial de la pantalla.
const MAX_LINES: int = 220
const CURSOR_BLINK_TIME: float = 0.5
const CURSOR_CHAR: String = "_"

# Escritura automática del asistente.
const TYPE_CHARS_PER_SECOND: float = 22.0
## Pausa entre un comando y el siguiente, para que se alcance a leer.
const TYPE_COMMAND_PAUSE: float = 0.45

var _lines: PackedStringArray = PackedStringArray()
var _input: String = ""
var _history: PackedStringArray = PackedStringArray()
var _history_index: int = -1

var _cursor_on: bool = true
var _cursor_elapsed: float = 0.0

# Cola de la escritura automática.
var _type_queue: PackedStringArray = PackedStringArray()
var _type_target: String = ""
var _type_progress: float = 0.0
var _type_pause: float = 0.0
var _type_total: int = 0
var _type_done: int = 0

@onready var output_label: Label = $OutputLabel


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh()


# --- Para implementar en quien herede ----------------------------------------

## Lo que se dibuja antes de lo que escribe el jugador.
func prompt() -> String:
	return "> "


## Ejecuta un comando ya escrito. Las líneas se agregan con append_lines().
func _run(_command: String) -> void:
	pass


# --- Pantalla -----------------------------------------------------------------

## Escribe líneas en la consola, como si las hubiera sacado un comando.
func print_lines(lines: PackedStringArray) -> void:
	append_lines(lines)
	_trim()
	_refresh()


## Igual, pero sin repintar: para usarse dentro de _run().
func append_lines(lines: PackedStringArray) -> void:
	for line: String in lines:
		_lines.append(line)


func append_line(line: String) -> void:
	_lines.append(line)


func clear_screen() -> void:
	_lines.clear()
	_refresh()


func line_count() -> int:
	return _lines.size()


func last_lines(count: int) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for i: int in range(maxi(_lines.size() - count, 0), _lines.size()):
		out.append(_lines[i])
	return out


func current_input() -> String:
	return _input


func _trim() -> void:
	while _lines.size() > MAX_LINES:
		_lines.remove_at(0)


## Arma el texto visible: el historial, la línea que se escribe y el cursor.
## Solo se muestran las últimas líneas que caben.
func _refresh() -> void:
	if output_label == null:
		return
	var rows: int = _visible_rows()
	var shown: PackedStringArray = PackedStringArray()
	for i: int in range(maxi(_lines.size() - (rows - 1), 0), _lines.size()):
		shown.append(_lines[i])
	shown.append(prompt() + _input + (CURSOR_CHAR if _cursor_on else " "))
	output_label.text = "\n".join(shown)


func _visible_rows() -> int:
	var font_size: int = output_label.get_theme_font_size("font_size")
	var line_height: float = output_label.get_theme_font("font").get_height(font_size)
	if line_height <= 0.0:
		return 20
	return maxi(int(size.y / line_height), 4)


func _process(delta: float) -> void:
	# El cursor solo parpadea si la consola tiene el foco; así se ve cuándo
	# está lista para escribir.
	var should_blink: bool = has_focus() or is_typing()
	_cursor_elapsed += delta
	if _cursor_elapsed >= CURSOR_BLINK_TIME:
		_cursor_elapsed = 0.0
		_cursor_on = not _cursor_on if should_blink else false
		_refresh()
	_process_typing(delta)


# --- Teclado ------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	# Solo el clic izquierdo toma el foco: el derecho tiene que llegar a la PC,
	# que es la que cierra con él.
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null:
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()
			accept_event()
		return

	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	# Mientras el asistente escribe, el teclado del jugador no estorba.
	if is_typing():
		accept_event()
		return

	match key.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			submit()
		KEY_BACKSPACE:
			_input = _input.substr(0, maxi(_input.length() - 1, 0))
			_refresh()
		KEY_UP:
			_recall_history(-1)
		KEY_DOWN:
			_recall_history(1)
		KEY_ESCAPE:
			return  # Escape sale de la PC; no se consume aquí.
		_:
			# unicode trae el carácter ya resuelto por la distribución del
			# teclado. Las teclas que no escriben nada (F3, F4...) se dejan
			# pasar para que sigan funcionando los atajos de depuración.
			if key.unicode < 32:
				return
			_input += String.chr(key.unicode)
			_refresh()
	accept_event()


func _recall_history(direction: int) -> void:
	if _history.is_empty():
		return
	if _history_index < 0:
		_history_index = _history.size()
	_history_index = clampi(_history_index + direction, 0, _history.size())
	_input = "" if _history_index >= _history.size() else _history[_history_index]
	_refresh()


func submit() -> void:
	var command: String = _input
	_lines.append(prompt() + command)
	_input = ""
	if not command.strip_edges().is_empty():
		_history.append(command)
	_history_index = -1
	_run(command)
	_trim()
	_refresh()


# --- Escritura automática del asistente --------------------------------------

## El asistente teclea estos comandos uno por uno, letra por letra.
func queue_commands(commands: PackedStringArray) -> void:
	cancel_typing()
	_type_queue = commands.duplicate()
	_type_total = 0
	for command: String in commands:
		_type_total += command.length()
	_type_done = 0
	_next_typed_command()


func cancel_typing() -> void:
	_type_queue.clear()
	_type_target = ""
	_type_progress = 0.0
	_type_pause = 0.0
	_type_total = 0
	_type_done = 0


func is_typing() -> bool:
	return not _type_target.is_empty() or not _type_queue.is_empty()


## De 0 a 1, para la barra de progreso del asistente.
func typing_progress() -> float:
	if _type_total <= 0:
		return 0.0
	return clampf(float(_type_done + int(_type_progress)) / float(_type_total), 0.0, 1.0)


func _next_typed_command() -> void:
	if _type_queue.is_empty():
		_type_target = ""
		typing_finished.emit()
		return
	_type_target = _type_queue[0]
	_type_queue.remove_at(0)
	_type_progress = 0.0
	_input = ""
	_refresh()


func _process_typing(delta: float) -> void:
	if _type_pause > 0.0:
		_type_pause -= delta
		if _type_pause <= 0.0:
			_next_typed_command()
		return
	if _type_target.is_empty():
		return

	_type_progress = minf(_type_progress + TYPE_CHARS_PER_SECOND * delta, float(_type_target.length()))
	var shown: int = int(_type_progress)
	if shown != _input.length():
		_input = _type_target.substr(0, shown)
		_refresh()
	if shown < _type_target.length():
		return

	_type_done += _type_target.length()
	_type_target = ""
	submit()
	_type_pause = TYPE_COMMAND_PAUSE
	if _type_queue.is_empty():
		_type_pause = 0.0
		_next_typed_command()

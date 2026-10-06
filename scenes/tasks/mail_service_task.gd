class_name MailServiceTask
extends Control

## Tarea "Reiniciar el servicio de correo". El panel es el ticket: dice los
## pasos y el estado que va reportando la consola. El trabajo se hace en la
## Terminal, así que esta tarea solo escucha lo que pasa ahí.
## Se da por terminada cuando un sc query muestra el servicio RUNNING.

signal completed()

const HINT: String = "Usa: net stop correo, luego net start correo, y comprueba con sc query correo."

var task_id: String = ""
var is_completed: bool = false

var _service: String = "correo"
var _terminal: PcTerminal = null

@onready var state_label: Label = $StateLabel
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	_service = str(data.get("service", "correo"))
	_refresh()


## La PC le pasa la consola para poder escuchar los comandos del jugador.
func bind_terminal(terminal: PcTerminal) -> void:
	_terminal = terminal
	_terminal.service_queried.connect(_on_service_queried)
	_terminal.service_state_changed.connect(_on_service_state_changed)
	_refresh()


## Lo que el asistente teclea en la consola si le pides que la resuelva.
func solve_commands() -> PackedStringArray:
	return PackedStringArray([
		"net stop " + _service,
		"net start " + _service,
		"sc query " + _service,
	])


func hint() -> String:
	return HINT


func _on_service_state_changed(service: String, _state: String) -> void:
	if service == _service:
		_refresh()


## Solo cuenta si el jugador lo comprueba: tiene que verlo en RUNNING.
func _on_service_queried(service: String, state: String) -> void:
	if service != _service:
		return
	_refresh()
	if is_completed or state != CampusNetwork.STATE_RUNNING:
		return
	is_completed = true
	status_label.text = "LISTO: el servicio quedo arriba."
	completed.emit()


func _refresh() -> void:
	if _terminal == null:
		state_label.text = "Servicio %s: sin consultar" % _service
		return
	var state: String = _terminal.service_state(_service)
	var error_code: int = int(_terminal.service_errors.get(_service, 0))
	var suffix: String = "" if error_code == 0 else "  (error %d)" % error_code
	state_label.text = "Servicio %s: %s%s" % [_service, state, suffix]
	if not is_completed:
		status_label.text = "Falta verlo en RUNNING con sc query."

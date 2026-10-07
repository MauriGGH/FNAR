class_name RouterInterfaceTask
extends Control

## Tarea "Activar la interfaz del router". La interfaz g0/0 viene apagada y sin
## dirección, así que todos los enlaces al router salen en rojo.
## Se termina cuando por la CLI queda con la IP correcta y levantada.

signal completed()

## El paso que tarda de esta tarea y lo que dice al acabar.
const WAIT_TEXT: String = "Levantando la interfaz"
const DONE_TEXT: String = "LISTO: g0/0 arriba y con direccion."

const HINT: String = "En la CLI del router: enable, configure terminal, interface g0/0, ip address 192.168.30.1 255.255.255.0 y no shutdown."

var task_id: String = ""
var is_completed: bool = false
var _wait: TaskWaitBar = null

var _sim: Node = null

@onready var instructions_label: Label = $InstructionsLabel
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	instructions_label.text = "La interfaz g0/0 del router esta apagada.\nDejala con esta direccion y levantada:\n\nIP %s\nMascara %s" % [
		NetworkScenarios.LAB_GATEWAY, NetworkScenarios.LAB_MASK]


func bind_network(sim: Node) -> void:
	_sim = sim
	_sim.load_scenario(NetworkScenarios.SCENARIO_ROUTER_DOWN)
	_sim.model_changed.connect(_check)
	_check()


## El asistente entra a la CLI y teclea los cinco comandos, uno por uno.
func solve_actions() -> Array[Dictionary]:
	return [{
		"type": "cli", "id": "rt",
		"commands": PackedStringArray([
			"enable",
			"configure terminal",
			"interface g0/0",
			"ip address %s %s" % [NetworkScenarios.LAB_GATEWAY, NetworkScenarios.LAB_MASK],
			"no shutdown",
		]),
	}]


func hint() -> String:
	return HINT


func _check() -> void:
	if is_completed or _sim == null:
		return
	var router: NetDevice = _sim.model.router()
	if router == null:
		return
	var has_address: bool = router.ip == NetworkScenarios.LAB_GATEWAY and router.mask == NetworkScenarios.LAB_MASK
	if not has_address:
		status_label.text = "Falta la direccion en g0/0."
		return
	if not router.interface_up:
		status_label.text = "Ya tiene IP; ahora levantala con no shutdown."
		return
	_begin_wait()
	return

# --- El paso que tarda --------------------------------------------------------

## La barra se crea la primera vez que hace falta y se pone arriba del estado.
func _wait_bar() -> TaskWaitBar:
	if _wait == null:
		_wait = TaskWaitBar.new()
		_wait.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_wait.offset_top = -112.0
		_wait.offset_bottom = -68.0
		_wait.finished.connect(_on_wait_finished)
		add_child(_wait)
	return _wait


## Lo de "hacer" ya está: ahora hay que esperar, y la barra solo corre con la
## PC arriba.
func _begin_wait() -> void:
	if is_completed or _wait_bar().is_running or _wait_bar().is_done:
		return
	status_label.text = "%s..." % WAIT_TEXT
	_wait_bar().start(WAIT_TEXT)


func _on_wait_finished() -> void:
	is_completed = true
	status_label.text = DONE_TEXT
	completed.emit()

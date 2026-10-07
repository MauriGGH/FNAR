class_name ConnectivityTask
extends Control

## Tarea "Prueba de conectividad": hacer ping al servidor desde la consola de
## una PC. En modo Simulación se ve el sobre recorriendo los cables.
## Se termina cuando el ping responde.

signal completed()

## El paso que tarda de esta tarea y lo que dice al acabar.
const WAIT_TEXT: String = "Esperando las respuestas del ping"
const DONE_TEXT: String = "LISTO: el servidor responde."

const HINT: String = "Abre una PC, pestaña Consola, y escribe: ping 192.168.30.50. Prueba el modo Simulación para ver el paquete."

var task_id: String = ""
var is_completed: bool = false
var _wait: TaskWaitBar = null

var _sim: Node = null

@onready var instructions_label: Label = $InstructionsLabel
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	instructions_label.text = "Comprueba que el laboratorio alcanza al servidor.\nDesde la consola de cualquier PC:\n\nping %s" % NetworkScenarios.LAB_SERVER_IP


func bind_network(sim: Node) -> void:
	_sim = sim
	_sim.load_scenario(NetworkScenarios.SCENARIO_WITH_SERVER)
	_sim.ping_result.connect(_on_ping_result)


## El asistente abre una PC y teclea el ping en su consola.
func solve_actions() -> Array[Dictionary]:
	return [{
		"type": "console", "id": "pc1",
		"commands": PackedStringArray(["ping " + NetworkScenarios.LAB_SERVER_IP]),
	}]


func hint() -> String:
	return HINT


func _on_ping_result(_device_id: String, target_ip: String, ok: bool) -> void:
	if is_completed:
		return
	if target_ip != NetworkScenarios.LAB_SERVER_IP:
		status_label.text = "Ese no es el servidor; el ping va a %s." % NetworkScenarios.LAB_SERVER_IP
		return
	if not ok:
		status_label.text = "El ping no respondio; revisa cables y configuracion."
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

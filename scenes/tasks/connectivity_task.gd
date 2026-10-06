class_name ConnectivityTask
extends Control

## Tarea "Prueba de conectividad": hacer ping al servidor desde la consola de
## una PC. En modo Simulación se ve el sobre recorriendo los cables.
## Se termina cuando el ping responde.

signal completed()

const HINT: String = "Abre una PC, pestaña Consola, y escribe: ping 192.168.30.50. Prueba el modo Simulación para ver el paquete."

var task_id: String = ""
var is_completed: bool = false

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
	is_completed = true
	status_label.text = "LISTO: el servidor responde."
	completed.emit()

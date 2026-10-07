class_name ClassroomVlanTask
extends Control

## Tarea "Cambiar la VLAN del salón E". El puerto del switch donde está la
## computadora del salón quedó en la VLAN equivocada, así que el equipo está
## cableado y con IP pero aislado: su enlace sale en rojo.
## Se termina cuando ese puerto queda en la VLAN del salón.

signal completed()

const HINT: String = "Abre el switch, entra a su CLI: enable, configure terminal, interface f0/%d y switchport access vlan %d."

var task_id: String = ""
var is_completed: bool = false

var _sim: Node = null

@onready var instructions_label: Label = $InstructionsLabel
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	instructions_label.text = "La %s esta cableada y con IP, pero no llega a nada.\nSu puerto del switch (f0/%d) quedo en la VLAN %d.\nDejalo en la VLAN %d." % [
		NetworkScenarios.CLASSROOM_LABEL, NetworkScenarios.CLASSROOM_PORT + 1,
		NetworkScenarios.WRONG_VLAN, NetworkScenarios.CLASSROOM_VLAN]


func bind_network(sim: Node) -> void:
	_sim = sim
	_sim.load_scenario(NetworkScenarios.SCENARIO_VLAN_MISMATCH)
	_sim.model_changed.connect(_check)
	_check()


## El asistente entra a la CLI del switch y teclea los cuatro comandos.
func solve_actions() -> Array[Dictionary]:
	return [{
		"type": "cli", "id": "sw",
		"commands": PackedStringArray([
			"enable",
			"configure terminal",
			"interface f0/%d" % (NetworkScenarios.CLASSROOM_PORT + 1),
			"switchport access vlan %d" % NetworkScenarios.CLASSROOM_VLAN,
		]),
	}]


func hint() -> String:
	return HINT % [NetworkScenarios.CLASSROOM_PORT + 1, NetworkScenarios.CLASSROOM_VLAN]


func _check() -> void:
	if is_completed or _sim == null:
		return
	var switch: NetDevice = _sim.model.device("sw")
	if switch == null:
		return
	var port_vlan: int = switch.vlan_of_port(NetworkScenarios.CLASSROOM_PORT)
	if port_vlan != NetworkScenarios.CLASSROOM_VLAN:
		status_label.text = "El puerto f0/%d sigue en la VLAN %d." % [
			NetworkScenarios.CLASSROOM_PORT + 1, port_vlan]
		return
	is_completed = true
	status_label.text = "LISTO: el salon ya esta en su VLAN."
	completed.emit()

class_name PrinterDhcpTask
extends Control

## Tarea "Reservar la IP de la impresora". La impresora quedó fuera del rango
## que reparte el DHCP, así que arranca sin dirección. Hay que entrar al
## router, abrirle un pool con su nombre y fijarle la dirección de la tarjeta.
## Se termina cuando la reserva existe con la IP correcta.

signal completed()

const HINT: String = "En la CLI del router: enable, configure terminal, ip dhcp pool %s y host %s %s."

var task_id: String = ""
var is_completed: bool = false

var _sim: Node = null

@onready var instructions_label: Label = $InstructionsLabel
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	instructions_label.text = "La %s quedo fuera del rango del DHCP y sin direccion.\nReservasela en el router:\n\nPool    %s\nIP      %s\nMascara %s" % [
		NetworkScenarios.PRINTER_LABEL, NetworkScenarios.PRINTER_POOL,
		NetworkScenarios.PRINTER_IP, NetworkScenarios.LAB_MASK]


func bind_network(sim: Node) -> void:
	_sim = sim
	_sim.load_scenario(NetworkScenarios.SCENARIO_PRINTER_DHCP)
	_sim.model_changed.connect(_check)
	_check()


## El asistente abre la CLI del router y crea la reserva.
func solve_actions() -> Array[Dictionary]:
	return [{
		"type": "cli", "id": "rt",
		"commands": PackedStringArray([
			"enable",
			"configure terminal",
			"ip dhcp pool %s" % NetworkScenarios.PRINTER_POOL,
			"host %s %s" % [NetworkScenarios.PRINTER_IP, NetworkScenarios.LAB_MASK],
		]),
	}]


func hint() -> String:
	return HINT % [NetworkScenarios.PRINTER_POOL, NetworkScenarios.PRINTER_IP,
		NetworkScenarios.LAB_MASK]


func _check() -> void:
	if is_completed or _sim == null:
		return
	var router: NetDevice = _sim.model.router()
	if router == null:
		return
	var entry: Dictionary = router.reservations.get(NetworkScenarios.PRINTER_POOL, {})
	if entry.is_empty():
		status_label.text = "Todavia no hay reserva para el pool %s." % NetworkScenarios.PRINTER_POOL
		return
	if str(entry.get("ip", "")) != NetworkScenarios.PRINTER_IP:
		status_label.text = "La reserva quedo en %s; tiene que ser %s." % [
			entry.get("ip", ""), NetworkScenarios.PRINTER_IP]
		return
	is_completed = true
	status_label.text = "LISTO: la impresora ya tiene su direccion."
	completed.emit()

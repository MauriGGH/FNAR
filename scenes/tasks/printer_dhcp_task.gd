class_name PrinterDhcpTask
extends Control

## Tarea "Reservar la IP de la impresora". La impresora quedó fuera del rango
## que reparte el DHCP, así que arranca sin dirección. Hay que entrar al
## router, abrirle un pool con su nombre y fijarle la dirección de la tarjeta.
## Se termina cuando la reserva existe con la IP correcta.

signal completed()

## El paso que tarda de esta tarea y lo que dice al acabar.
const WAIT_TEXT: String = "Esperando que la impresora pida su direccion"
const DONE_TEXT: String = "LISTO: la impresora ya tiene su direccion."

const HINT: String = "En la CLI del router: enable, configure terminal, ip dhcp pool %s y host %s %s."

var task_id: String = ""
var is_completed: bool = false
var _wait: TaskWaitBar = null

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

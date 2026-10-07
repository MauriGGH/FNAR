class_name NetIpConfigTask
extends Control

## Tarea "Configurar IPs". La tarjeta trae la tabla; el jugador abre cada PC en
## el simulador y escribe su IP, su máscara y su puerta de enlace.
## Si repite una IP o pone mal la puerta, el enlace se marca en rojo con el
## motivo, tanto en el lienzo como en la ventana del equipo.

signal completed()

## El paso que tarda de esta tarea y lo que dice al acabar.
const WAIT_TEXT: String = "Propagando la configuracion"
const DONE_TEXT: String = "LISTO: las cuatro quedaron bien."

const HINT: String = "Abre cada PC, pestaña Configuración, y escribe la IP de la tabla con la mascara y la puerta. No repitas IPs."

var task_id: String = ""
var is_completed: bool = false
var _wait: TaskWaitBar = null

var _sim: Node = null

@onready var header_label: Label = $HeaderLabel
@onready var rows: VBoxContainer = $Rows
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	header_label.text = "Mascara %s\nPuerta de enlace %s" % [
		NetworkScenarios.LAB_MASK, NetworkScenarios.LAB_GATEWAY]


func bind_network(sim: Node) -> void:
	_sim = sim
	_sim.load_scenario(NetworkScenarios.SCENARIO_NO_IPS)
	_sim.model_changed.connect(_refresh)
	_build_rows()
	_refresh()


## El asistente abre cada PC, llena los tres campos y aplica.
func solve_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for i: int in NetworkScenarios.LAB_PC_IPS.size():
		var device_id: String = "pc%d" % (i + 1)
		actions.append({"type": "open", "id": device_id})
		actions.append({"type": "field", "field": "ip", "value": NetworkScenarios.LAB_PC_IPS[i]})
		actions.append({"type": "field", "field": "mask", "value": NetworkScenarios.LAB_MASK})
		actions.append({"type": "field", "field": "gateway", "value": NetworkScenarios.LAB_GATEWAY})
		actions.append({"type": "apply"})
	return actions


func hint() -> String:
	return HINT


func _build_rows() -> void:
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	for i: int in NetworkScenarios.LAB_PC_IPS.size():
		var label: Label = Label.new()
		label.add_theme_font_size_override("font_size", 17)
		rows.add_child(label)


func _refresh() -> void:
	if _sim == null:
		return
	var labels: Array[Node] = rows.get_children()
	var done: int = 0
	for i: int in mini(labels.size(), NetworkScenarios.LAB_PC_IPS.size()):
		var device: NetDevice = _sim.model.device("pc%d" % (i + 1))
		var wanted: String = NetworkScenarios.LAB_PC_IPS[i]
		var mark: String = "[ ]"
		if device != null and _is_right(device, wanted):
			mark = "[X]"
			done += 1
		(labels[i] as Label).text = "%s %s  %s" % [mark, "LAB-0%d" % (i + 1), wanted]

	if is_completed:
		return
	var problem: String = _first_problem()
	if not problem.is_empty():
		status_label.text = problem
		return
	if done < NetworkScenarios.LAB_PC_IPS.size():
		status_label.text = "Configuradas: %d de %d" % [done, NetworkScenarios.LAB_PC_IPS.size()]
		return
	_begin_wait()
	return


func _is_right(device: NetDevice, wanted_ip: String) -> bool:
	return device.ip == wanted_ip \
		and device.mask == NetworkScenarios.LAB_MASK \
		and device.gateway == NetworkScenarios.LAB_GATEWAY


## El primer enlace en rojo, para que el motivo también salga en la tarjeta.
func _first_problem() -> String:
	for link: NetLink in _sim.model.links:
		if not link.ok:
			return link.reason
	return ""

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

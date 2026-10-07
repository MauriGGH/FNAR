class_name ConnectLabTask
extends Control

## Tarea "Conectar el laboratorio". La tarjeta enseña el diagrama de cómo debe
## quedar; el trabajo se hace arrastrando cables en el simulador.
## Se termina cuando los cinco enlaces del plan existen y están en verde.

signal completed()

## El paso que tarda de esta tarea y lo que dice al acabar.
const WAIT_TEXT: String = "Levantando los enlaces"
const DONE_TEXT: String = "LISTO: el laboratorio quedo cableado."

const HINT: String = "Usa cable recto: del router al puerto 0 del switch, y cada PC a los puertos 2 a 5."

var task_id: String = ""
var is_completed: bool = false
var _wait: TaskWaitBar = null

var _sim: Node = null

@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))


## La PC le pasa el simulador; la tarea carga su escenario y se pone a escuchar.
func bind_network(sim: Node) -> void:
	_sim = sim
	_sim.load_scenario(NetworkScenarios.SCENARIO_UNCABLED)
	_sim.model_changed.connect(_check)
	_check()


## Los pasos que el asistente hace a la vista: cinco cables, uno por uno.
func solve_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for required: Dictionary in NetworkScenarios.required_lab_links():
		actions.append({
			"type": "link", "a": required["a"], "ap": required["ap"],
			"b": required["b"], "bp": required["bp"], "cable": NetModel.CABLE_STRAIGHT,
		})
	return actions


func hint() -> String:
	return HINT


func _check() -> void:
	if is_completed or _sim == null:
		return
	var done: int = 0
	var required: Array[Dictionary] = NetworkScenarios.required_lab_links()
	for item: Dictionary in required:
		var link: NetLink = _sim.model.link_between(str(item["a"]), str(item["b"]))
		if link != null and link.ok:
			done += 1
	if done < required.size():
		status_label.text = "Enlaces en verde: %d de %d" % [done, required.size()]
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

extends Control

## La PC de la oficina: un escritorio viejo con la lista de tareas de la noche,
## la tarea abierta y el Asistente IA. La ventana del asistente sigue abierta
## aunque el jugador baje la PC, y eso es justo lo que lo delata ante Mamador.

signal opened()
signal closed()

## Lo que tarda el asistente en resolver una tarea.
const AI_SOLVE_TIME: float = 8.0
const AI_CHAT_LINES: int = 5

var is_open: bool = false
var is_ai_window_open: bool = false

var _task_buttons: Array[Button] = []
var _open_task_index: int = -1
var _task_instance: Node = null
var _solving: bool = false
var _solve_elapsed: float = 0.0
var _chat: PackedStringArray = PackedStringArray()

@onready var close_pc_button: Button = $ClosePcButton
@onready var ai_toggle_button: Button = $AiToggleButton
@onready var task_list: VBoxContainer = $TasksWindow/TaskList
@onready var task_progress_label: Label = $TasksWindow/ProgressLabel
@onready var task_window: Control = $TaskWindow
@onready var task_window_title: Label = $TaskWindow/TitleLabel
@onready var task_content: Control = $TaskWindow/Content
@onready var task_close_button: Button = $TaskWindow/CloseButton
@onready var ai_window: Control = $AiWindow
@onready var ai_close_button: Button = $AiWindow/CloseButton
@onready var ai_chat_label: Label = $AiWindow/ChatLabel
@onready var ai_solve_button: Button = $AiWindow/SolveButton
@onready var ai_progress: ProgressBar = $AiWindow/SolveProgress


func _ready() -> void:
	visible = false
	close_pc_button.pressed.connect(close)
	ai_toggle_button.pressed.connect(_toggle_ai_window)
	ai_close_button.pressed.connect(_close_ai_window)
	task_close_button.pressed.connect(_close_task)
	ai_solve_button.pressed.connect(_request_solve)

	GameManager.night_started.connect(_on_night_started)
	GameManager.task_completed.connect(_on_any_task_completed)

	_set_ai_window_open(false)
	task_window.visible = false
	ai_progress.value = 0.0
	_chat.append("Asistente IA v0.9 (Coordinación de Sistemas)")
	_chat.append("Abre una tarea y pulsa Resolver tarea.")
	_refresh_chat()


# --- Abrir y cerrar la PC -----------------------------------------------------

func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


# --- Lista de tareas ----------------------------------------------------------

func _on_night_started(_night: int) -> void:
	_close_task()
	_set_ai_window_open(false)
	_build_task_list()


## Un botón por tarea de la noche, con casilla [ ] o [X].
func _build_task_list() -> void:
	for child: Node in task_list.get_children():
		child.queue_free()
	_task_buttons.clear()

	var tasks: Array = GameManager.night_tasks()
	for i: int in tasks.size():
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_open_task.bind(i))
		task_list.add_child(button)
		_task_buttons.append(button)
	_refresh_task_list()


func _refresh_task_list() -> void:
	var tasks: Array = GameManager.night_tasks()
	for i: int in _task_buttons.size():
		var task: Dictionary = tasks[i]
		var done: bool = GameManager.is_task_completed(str(task.get("id", "")))
		_task_buttons[i].text = "%s %s" % ["[X]" if done else "[ ]", task.get("title", "Tarea")]
	task_progress_label.text = "%d de %d terminadas" % [GameManager.completed_task_count(), tasks.size()]


func _open_task(index: int) -> void:
	var tasks: Array = GameManager.night_tasks()
	if index < 0 or index >= tasks.size():
		return
	if index == _open_task_index:
		return

	_close_task()
	var task: Dictionary = tasks[index]
	var scene_path: String = Tasks.scene_for_type(str(task.get("type", "")))
	if scene_path.is_empty():
		_log("Esa tarea todavía no está programada.")
		return

	var scene: PackedScene = load(scene_path)
	_task_instance = scene.instantiate()
	task_content.add_child(_task_instance)
	if _task_instance.has_method("setup"):
		_task_instance.setup(task)
	if _task_instance.has_signal("completed"):
		_task_instance.completed.connect(_on_open_task_completed)

	_open_task_index = index
	task_window_title.text = str(task.get("title", "Tarea"))
	task_window.visible = true


func _close_task() -> void:
	_cancel_solve("")
	if _task_instance != null:
		_task_instance.queue_free()
		_task_instance = null
	_open_task_index = -1
	task_window.visible = false


func _on_open_task_completed() -> void:
	var tasks: Array = GameManager.night_tasks()
	if _open_task_index < 0 or _open_task_index >= tasks.size():
		return
	GameManager.complete_task(str(tasks[_open_task_index].get("id", "")))


func _on_any_task_completed(_task_id: String) -> void:
	_refresh_task_list()


# --- Asistente IA -------------------------------------------------------------

func _toggle_ai_window() -> void:
	_set_ai_window_open(not is_ai_window_open)


func _close_ai_window() -> void:
	_set_ai_window_open(false)


## Abrir o cerrar la ventana del asistente. GameManager tiene que saberlo
## siempre, porque Mamador lo revisa cuando llega al cristal.
func _set_ai_window_open(is_window_open: bool) -> void:
	is_ai_window_open = is_window_open
	ai_window.visible = is_window_open
	ai_toggle_button.text = "Asistente IA [abierto]" if is_window_open else "Asistente IA"
	GameManager.set_ai_window_open(is_window_open)
	if not is_window_open:
		_cancel_solve("Resolución cancelada: cerraste el asistente.")


func _request_solve() -> void:
	if _task_instance == null:
		_log("Abre una tarea primero.")
		return
	if _task_instance.get("is_completed") == true:
		_log("Esa tarea ya está lista.")
		return
	if _solving:
		return
	_solving = true
	_solve_elapsed = 0.0
	ai_progress.value = 0.0
	_log("Resolviendo... no cierres esta ventana.")


func _cancel_solve(message: String) -> void:
	if not _solving:
		return
	_solving = false
	_solve_elapsed = 0.0
	ai_progress.value = 0.0
	if not message.is_empty():
		_log(message)


func _finish_solve() -> void:
	_solving = false
	ai_progress.value = 100.0
	if _task_instance != null and _task_instance.has_method("solve"):
		_task_instance.solve()
	_log("Tarea resuelta. De nada.")


## El asistente trabaja aunque la PC esté bajada, pero solo mientras su
## propia ventana siga abierta.
func _process(delta: float) -> void:
	if not _solving:
		return
	if not is_ai_window_open:
		_cancel_solve("Resolución cancelada: cerraste el asistente.")
		return
	_solve_elapsed += delta
	ai_progress.value = _solve_elapsed / AI_SOLVE_TIME * 100.0
	if _solve_elapsed >= AI_SOLVE_TIME:
		_finish_solve()


func _log(line: String) -> void:
	_chat.append(line)
	while _chat.size() > AI_CHAT_LINES:
		_chat.remove_at(0)
	_refresh_chat()


func _refresh_chat() -> void:
	ai_chat_label.text = "\n".join(_chat)

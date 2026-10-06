extends Control

## La PC de la oficina. La pantalla va enmarcada por el bisel del monitor CRT y
## adentro hay un escritorio retro con cuatro íconos: Terminal, Simulador de
## red, Tareas y Asistente IA. La tarea de IPs se abre desde el simulador.
## La ventana del asistente sigue trabajando aunque el jugador baje la PC, y
## eso es justo lo que lo delata ante Mamador.

signal opened()
signal closed()

## Lo que tarda el asistente en resolver una tarea.
const AI_SOLVE_TIME: float = 8.0
const AI_CHAT_LINES: int = 5

const ICON_LEFT: float = 20.0
const ICON_TOP: float = 48.0
const ICON_GAP: float = 6.0

var is_open: bool = false
var is_ai_window_open: bool = false

var _open_task_index: int = -1
var _task_instance: Node = null
var _solving: bool = false
var _solve_elapsed: float = 0.0
var _chat: PackedStringArray = PackedStringArray()
var _icons: Array[DesktopIcon] = []

@onready var bezel: Control = $Bezel
@onready var screen: Control = $Screen
@onready var crt_overlay: ColorRect = $Screen/CrtOverlay
@onready var close_pc_button: Button = $Screen/ClosePcButton
@onready var icons_holder: Control = $Screen/Icons

@onready var tasks_window: PcWindow = $Screen/TasksWindow
@onready var task_list: VBoxContainer = $Screen/TasksWindow/TaskList
@onready var task_progress_label: Label = $Screen/TasksWindow/ProgressLabel

@onready var terminal_window: PcWindow = $Screen/TerminalWindow
@onready var network_window: PcWindow = $Screen/NetworkWindow
@onready var network_list: VBoxContainer = $Screen/NetworkWindow/DeviceList

@onready var task_window: PcWindow = $Screen/TaskWindow
@onready var task_content: Control = $Screen/TaskWindow/Content

@onready var ai_window: PcWindow = $Screen/AiWindow
@onready var ai_chat_label: Label = $Screen/AiWindow/ChatLabel
@onready var ai_solve_button: Button = $Screen/AiWindow/SolveButton
@onready var ai_progress: ProgressBar = $Screen/AiWindow/SolveProgress


func _ready() -> void:
	visible = false
	_fit_screen()
	bezel.resized.connect(_fit_screen)

	close_pc_button.pressed.connect(close)
	ai_solve_button.pressed.connect(_request_solve)
	ai_window.close_requested.connect(_close_ai_window)
	task_window.close_requested.connect(_close_task)
	tasks_window.close_requested.connect(func() -> void: tasks_window.visible = false)
	terminal_window.close_requested.connect(func() -> void: terminal_window.visible = false)
	network_window.close_requested.connect(func() -> void: network_window.visible = false)

	GameManager.night_started.connect(_on_night_started)
	GameManager.task_completed.connect(_on_any_task_completed)

	_build_icons()
	_set_ai_window_open(false)
	task_window.visible = false
	terminal_window.visible = false
	ai_progress.value = 0.0
	_chat.append("Asistente IA v0.9 (Coordinación de Sistemas)")
	_chat.append("Abre una tarea y pulsa Resolver tarea.")
	_refresh_chat()


## El escritorio ocupa el hueco que deja el bisel del monitor.
func _fit_screen() -> void:
	var hole: Rect2 = bezel.screen_rect()
	screen.position = hole.position
	screen.size = hole.size
	crt_overlay.size = hole.size


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
	PowerManager.set_pc_open(true)
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	PowerManager.set_pc_open(false)
	closed.emit()


# --- Escritorio ---------------------------------------------------------------

func _build_icons() -> void:
	_add_icon("terminal", DesktopIcon.Glyph.TERMINAL, "Terminal")
	_add_icon("network", DesktopIcon.Glyph.NETWORK, "Simulador de red")
	_add_icon("tasks", DesktopIcon.Glyph.TASKS, "Tareas")
	_add_icon("ai", DesktopIcon.Glyph.AI, "Asistente IA")


func _add_icon(icon_id: String, glyph: DesktopIcon.Glyph, text: String) -> void:
	var icon: DesktopIcon = DesktopIcon.new()
	icon.setup(icon_id, glyph, text)
	icon.position = Vector2(ICON_LEFT, ICON_TOP + _icons.size() * (DesktopIcon.ICON_SIZE.y + ICON_GAP))
	icon.pressed.connect(_on_icon_pressed)
	icons_holder.add_child(icon)
	_icons.append(icon)


func _on_icon_pressed(icon_id: String) -> void:
	match icon_id:
		"terminal":
			terminal_window.visible = true
		"network":
			network_window.visible = true
		"tasks":
			tasks_window.visible = true
		"ai":
			_set_ai_window_open(true)


# --- Lista de tareas y simulador de red ---------------------------------------

func _on_night_started(_night: int) -> void:
	_close_task()
	_set_ai_window_open(false)
	_build_task_list()
	_build_network_list()


## La ventana de Tareas es solo la lista con casillas [ ] o [X].
func _build_task_list() -> void:
	for child: Node in task_list.get_children():
		child.queue_free()
	for task: Dictionary in GameManager.night_tasks():
		var label: Label = Label.new()
		label.add_theme_font_size_override("font_size", 17)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		task_list.add_child(label)
	_refresh_task_list()


func _refresh_task_list() -> void:
	var tasks: Array = GameManager.night_tasks()
	var labels: Array[Node] = task_list.get_children()
	for i: int in mini(labels.size(), tasks.size()):
		var done: bool = GameManager.is_task_completed(str(tasks[i].get("id", "")))
		(labels[i] as Label).text = "%s %s" % ["[X]" if done else "[ ]", tasks[i].get("title", "Tarea")]
	task_progress_label.text = "%d de %d terminadas" % [GameManager.completed_task_count(), tasks.size()]


## El simulador de red lista los equipos configurables de la noche.
func _build_network_list() -> void:
	for child: Node in network_list.get_children():
		child.queue_free()
	var tasks: Array = GameManager.night_tasks()
	for i: int in tasks.size():
		if str(tasks[i].get("type", "")) != Tasks.TYPE_IP_CONFIG:
			continue
		var button: Button = Button.new()
		button.text = str(tasks[i].get("title", "Segmento"))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_open_task.bind(i))
		network_list.add_child(button)


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
	task_window.set_window_title("Configuración de equipos: %s" % task.get("title", "Tarea"))
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

func _close_ai_window() -> void:
	_set_ai_window_open(false)


## Abrir o cerrar la ventana del asistente. GameManager tiene que saberlo
## siempre, porque Mamador lo revisa cuando llega al cristal.
func _set_ai_window_open(is_window_open: bool) -> void:
	is_ai_window_open = is_window_open
	ai_window.visible = is_window_open
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

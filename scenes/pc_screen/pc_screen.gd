extends Control

## La PC de la oficina. La pantalla va enmarcada por el bisel del monitor CRT y
## adentro hay un escritorio retro con cuatro íconos: Terminal, Simulador de
## red, Tareas y Claudio (el asistente de IA). Las ventanas se pueden tapar
## entre ellas y la que se clica pasa al frente, como en un escritorio de
## verdad. La ventana de Claudio sigue trabajando aunque el jugador baje la PC,
## y eso es justo lo que lo delata ante Mamador.

signal opened()
signal closed()
## Armando no logró ser echado: hay que quitarle energía al guardia.
signal armando_won()

## Lo que tarda Claudio en resolver una tarea.
const AI_SOLVE_TIME: float = 8.0
const AI_CHAT_LINES: int = 5
const CLAUDIO_GREETING: String = "Claudio v0.9 — asistente de la Coordinación"

const ICON_LEFT: float = 20.0
const ICON_TOP: float = 48.0
const ICON_GAP: float = 6.0

var is_open: bool = false
var is_ai_window_open: bool = false

var _open_task_index: int = -1
var _task_instance: Node = null
## Cómo está resolviendo el asistente: tecleando en la consola o con su
## barra de progreso de siempre.
enum SolveMode { NONE, TIMER, TYPING, ACTIONS }

var _solving: bool = false
var _solve_mode: SolveMode = SolveMode.NONE
var _solve_elapsed: float = 0.0
var _chat: PackedStringArray = PackedStringArray()
var _icons: Array[DesktopIcon] = []
var _armando: ArmandoPrompts = null

@onready var bezel: Control = $Bezel
@onready var screen: Control = $Screen
@onready var crt_overlay: ColorRect = $Screen/CrtOverlay
@onready var close_pc_button: Button = $Screen/ClosePcButton
@onready var icons_holder: Control = $Screen/Icons

@onready var tasks_window: PcWindow = $Screen/Windows/TasksWindow
@onready var task_list: VBoxContainer = $Screen/Windows/TasksWindow/TaskList
@onready var task_progress_label: Label = $Screen/Windows/TasksWindow/ProgressLabel

@onready var windows: Control = $Screen/Windows
@onready var terminal_window: PcWindow = $Screen/Windows/TerminalWindow
@onready var terminal: PcTerminal = $Screen/Windows/TerminalWindow/Terminal
@onready var network_window: PcWindow = $Screen/Windows/NetworkWindow
@onready var network_sim: Control = $Screen/Windows/NetworkWindow/NetworkSim

@onready var task_window: PcWindow = $Screen/Windows/TaskWindow
@onready var task_content: Control = $Screen/Windows/TaskWindow/Content

@onready var ai_window: PcWindow = $Screen/Windows/AiWindow
@onready var ai_chat_label: Label = $Screen/Windows/AiWindow/ChatLabel
@onready var ai_solve_button: Button = $Screen/Windows/AiWindow/SolveButton
@onready var ai_hint_button: Button = $Screen/Windows/AiWindow/HintButton
@onready var ai_progress: ProgressBar = $Screen/Windows/AiWindow/SolveProgress
@onready var armando_takeover: Control = $Screen/ArmandoTakeover


func _ready() -> void:
	visible = false
	_fit_screen()
	bezel.resized.connect(_fit_screen)

	close_pc_button.pressed.connect(close)
	ai_solve_button.pressed.connect(_request_solve)
	ai_hint_button.pressed.connect(_request_hint)
	terminal.typing_finished.connect(_on_typing_finished)
	network_sim.actions_finished.connect(_on_actions_finished)
	for window: PcWindow in [tasks_window, terminal_window, network_window, task_window, ai_window]:
		window.focused.connect(_bring_to_front.bind(window))
	ai_window.close_requested.connect(_close_ai_window)
	task_window.close_requested.connect(_close_task)
	tasks_window.close_requested.connect(func() -> void: tasks_window.visible = false)
	terminal_window.close_requested.connect(func() -> void: terminal_window.visible = false)
	network_window.close_requested.connect(func() -> void: network_window.visible = false)

	armando_takeover.survived.connect(_on_armando_survived)
	armando_takeover.failed.connect(_on_armando_failed)
	GameManager.night_started.connect(_on_night_started)
	GameManager.task_completed.connect(_on_any_task_completed)
	GameManager.ticket_arrived.connect(func(_index: int) -> void: _refresh_task_list())
	GameManager.ticket_expired.connect(func(_index: int) -> void: _refresh_task_list())
	_solve_mode = SolveMode.NONE

	_build_icons()
	_set_ai_window_open(false)
	task_window.visible = false
	terminal_window.visible = false
	ai_progress.value = 0.0
	_chat.append(CLAUDIO_GREETING)
	_chat.append(Claudio.say("Abre una tarea y pulsa Resolver tarea."))
	_refresh_chat()


## El escritorio ocupa el hueco que deja el bisel del monitor.
func _fit_screen() -> void:
	var hole: Rect2 = bezel.screen_rect()
	screen.position = hole.position
	screen.size = hole.size
	crt_overlay.size = hole.size
	armando_takeover.size = hole.size


# --- Abrir y cerrar la PC -----------------------------------------------------

func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open or PowerManager.is_blackout or GameManager.is_in_server_room:
		return  # Sin corriente, la PC no prende.
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


## De la PC se sale por el botón, con Escape o con clic derecho.
## Va en _input y no en _unhandled_input porque un Control en STOP (la raíz de
## la PC lo es, para no dejar pasar clics a la oficina) se queda con los
## botones del mouse aunque no los use, y el clic derecho nunca llegaría.
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		close()
		get_viewport().set_input_as_handled()


# --- Escritorio ---------------------------------------------------------------

func _build_icons() -> void:
	_add_icon("terminal", DesktopIcon.Glyph.TERMINAL, "Terminal")
	_add_icon("network", DesktopIcon.Glyph.NETWORK, "Simulador de red")
	_add_icon("tasks", DesktopIcon.Glyph.TASKS, "Tareas")
	_add_icon("claudio", DesktopIcon.Glyph.CLAUDIO, "Claudio")


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
			_show_window(terminal_window)
			terminal.grab_focus()  # Para poder escribir de inmediato.
		"network":
			_show_window(network_window)
		"tasks":
			_show_window(tasks_window)
		"claudio":
			_set_ai_window_open(true)
			_bring_to_front(ai_window)


func _show_window(window: PcWindow) -> void:
	window.visible = true
	_bring_to_front(window)


## La ventana clicada se dibuja encima de las demás.
func _bring_to_front(window: PcWindow) -> void:
	windows.move_child(window, -1)


# --- Lista de tareas y simulador de red ---------------------------------------

func _on_night_started(_night: int) -> void:
	_close_task()
	_set_ai_window_open(false)
	terminal.reset_for_night()
	_build_task_list()


## Cada tarea es un botón de tres líneas: nombre, en qué app se hace con su
## estado, y la descripción corta. Al clicarlo se abre su panel.
func _build_task_list() -> void:
	_clear_children(task_list)
	for i: int in GameManager.night_tasks().size():
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_open_task.bind(i))
		task_list.add_child(button)
	_refresh_task_list()


func _refresh_task_list() -> void:
	var tasks: Array = GameManager.night_tasks()
	var buttons: Array[Node] = task_list.get_children()
	for i: int in mini(buttons.size(), tasks.size()):
		var task: Dictionary = tasks[i]
		var done: bool = GameManager.is_task_completed(str(task.get("id", "")))
		var arrived: bool = GameManager.is_ticket_arrived(i)
		var expired: bool = GameManager.is_ticket_expired(i)
		var state: String = "pendiente"
		if done:
			state = "terminada"
		elif expired:
			state = "VENCIDA"
		elif not arrived:
			state = "sin llegar"
		var mark: String = "[ ]"
		if done:
			mark = "[X]"
		elif expired:
			mark = "[!]"
		elif not arrived:
			mark = "[ · ]"
		var button: Button = buttons[i] as Button
		button.disabled = not arrived
		button.text = "%s %s\n    %s - %s\n    %s" % [
			mark,
			task.get("title", "Tarea") if arrived else "Ticket sin llegar",
			task.get("app", "?") if arrived else "-",
			state,
			task.get("description", "") if arrived else "Llega mas tarde en la noche.",
		]
	task_progress_label.text = "%d de %d pagadas · %d tickets llegados" % [
		GameManager.paid_task_count(), tasks.size(), GameManager.arrived_ticket_count()]


## queue_free() es diferido, así que los hijos viejos seguirían en el árbol
## este frame y las listas se llenarían en los nodos equivocados. Hay que
## sacarlos del árbol de inmediato.
func _clear_children(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _open_task(index: int) -> void:
	var tasks: Array = GameManager.night_tasks()
	if index < 0 or index >= tasks.size():
		return
	if index == _open_task_index:
		return
	# Las tareas llegan como tickets: lo que no ha llegado no se abre.
	if not GameManager.is_ticket_arrived(index):
		_log(Claudio.sorry("Ese ticket todavia no ha llegado."))
		return

	_close_task()
	var task: Dictionary = tasks[index]
	var scene_path: String = Tasks.scene_for_type(str(task.get("type", "")))
	if scene_path.is_empty():
		_log(Claudio.sorry("Esa tarea todavía no está programada."))
		return

	var scene: PackedScene = load(scene_path)
	_task_instance = scene.instantiate()
	task_content.add_child(_task_instance)
	if _task_instance.has_method("setup"):
		_task_instance.setup(task)
	# Las tareas de consola escuchan lo que el jugador teclea, y las de red
	# cargan su escenario en el simulador.
	if _task_instance.has_method("bind_terminal"):
		_task_instance.bind_terminal(terminal)
	if _task_instance.has_method("bind_network"):
		_task_instance.bind_network(network_sim)
	if _task_instance.has_signal("completed"):
		_task_instance.completed.connect(_on_open_task_completed)

	_open_task_index = index
	task_window.set_window_title(str(task.get("title", "Tarea")))
	_show_window(task_window)
	# La app donde se hace la tarea se abre junto con su tarjeta.
	match str(task.get("app", "")):
		Tasks.APP_TERMINAL:
			_show_window(terminal_window)
			terminal.grab_focus()
		Tasks.APP_NETWORK:
			_show_window(network_window)
	_bring_to_front(task_window)


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


# --- Armando en la pantalla ---------------------------------------------------

## El night.gd le pasa a Armando para poder tirar su dado y escucharlo.
func set_armando(armando: ArmandoPrompts) -> void:
	_armando = armando
	if _armando != null:
		_armando.takeover_requested.connect(_on_armando_takeover)


func _on_armando_takeover(phrase: String) -> void:
	armando_takeover.play(phrase)
	_bring_to_front_of_screen()


## La cara se dibuja encima de todo el escritorio, ventanas incluidas.
func _bring_to_front_of_screen() -> void:
	screen.move_child(armando_takeover, -1)


func _on_armando_survived() -> void:
	_log(Claudio.say("No sé cómo entró a mi ventana. Perdón."))


## Se le acabó el tiempo al jugador: la tarea abierta vuelve a empezar y la
## señal avisa al night.gd para que le quite energía.
func _on_armando_failed() -> void:
	var index: int = _open_task_index
	_cancel_solve("")
	if index >= 0:
		_close_task()
		_open_task(index)
	_log(Claudio.sorry("Armando borró tu progreso. Yo no fui."))
	armando_won.emit()


# --- Claudio -------------------------------------------------------------

func _close_ai_window() -> void:
	_set_ai_window_open(false)


## Abrir o cerrar la ventana del asistente. GameManager tiene que saberlo
## siempre, porque Mamador lo revisa cuando llega al cristal.
func _set_ai_window_open(is_window_open: bool) -> void:
	is_ai_window_open = is_window_open
	ai_window.visible = is_window_open
	GameManager.set_ai_window_open(is_window_open)
	if not is_window_open:
		_cancel_solve(Claudio.sorry("Cancelé la resolución: cerraste mi ventana."))


func _request_solve() -> void:
	if not is_ai_window_open:
		return
	if _task_instance == null:
		_log(Claudio.say("Abre una tarea primero."))
		return
	if _task_instance.get("is_completed") == true:
		_log(Claudio.say("Esa tarea ya está lista."))
		return
	if _solving:
		return
	# Antes de empezar, Armando puede aparecerse y tomar la pantalla.
	if _armando != null and _armando.roll_takeover():
		return

	_solving = true
	_solve_elapsed = 0.0
	ai_progress.value = 0.0
	# Las de red se resuelven haciendo los pasos en el simulador, a la vista.
	if _task_instance.has_method("solve_actions"):
		_solve_mode = SolveMode.ACTIONS
		_show_window(network_window)
		network_sim.queue_actions(_task_instance.solve_actions())
		_log(Claudio.sorry("Haciendo los pasos en el simulador, no cierres esta ventana."))
		return
	# Las de consola se resuelven tecleando los comandos a la vista.
	if _task_instance.has_method("solve_commands"):
		_solve_mode = SolveMode.TYPING
		_show_window(terminal_window)
		terminal.queue_commands(_task_instance.solve_commands())
		_log(Claudio.sorry("Tecleando los comandos, no cierres esta ventana."))
		return
	_solve_mode = SolveMode.TIMER
	_log(Claudio.sorry("Ya casi termino tu tarea, no cierres esta ventana."))


## Explica qué comandos usar, sin resolver nada.
func _request_hint() -> void:
	if not is_ai_window_open:
		return
	if _task_instance == null:
		_log(Claudio.say("Abre una tarea primero."))
		return
	if not _task_instance.has_method("hint"):
		_log(Claudio.sorry("De esa tarea no tengo pistas."))
		return
	_log(Claudio.say(str(_task_instance.hint())))


func _cancel_solve(message: String) -> void:
	if not _solving:
		return
	if _solve_mode == SolveMode.TYPING:
		terminal.cancel_typing()
	elif _solve_mode == SolveMode.ACTIONS:
		network_sim.cancel_actions()
	_solving = false
	_solve_mode = SolveMode.NONE
	_solve_elapsed = 0.0
	ai_progress.value = 0.0
	if not message.is_empty():
		_log(message)


func _finish_solve() -> void:
	_solving = false
	_solve_mode = SolveMode.NONE
	ai_progress.value = 100.0
	if _task_instance != null and _task_instance.has_method("solve"):
		_task_instance.solve()
	_log(Claudio.done("Tarea resuelta."))


## El simulador terminó todos los pasos que le pasó el asistente.
func _on_actions_finished() -> void:
	if not _solving or _solve_mode != SolveMode.ACTIONS:
		return
	_solving = false
	_solve_mode = SolveMode.NONE
	ai_progress.value = 100.0
	_log(Claudio.done("Pasos terminados."))


## La consola terminó de teclear todo lo que le pasó el asistente.
func _on_typing_finished() -> void:
	if not _solving or _solve_mode != SolveMode.TYPING:
		return
	_solving = false
	_solve_mode = SolveMode.NONE
	ai_progress.value = 100.0
	_log(Claudio.done("Comandos enviados."))


## El asistente trabaja aunque la PC esté bajada, pero solo mientras su
## propia ventana siga abierta.
func _process(delta: float) -> void:
	if not _solving:
		return
	if not is_ai_window_open:
		_cancel_solve(Claudio.sorry("Cancelé la resolución: cerraste mi ventana."))
		return
	if _solve_mode == SolveMode.TYPING:
		ai_progress.value = terminal.typing_progress() * 100.0
		return
	if _solve_mode == SolveMode.ACTIONS:
		ai_progress.value = network_sim.automation_progress() * 100.0
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

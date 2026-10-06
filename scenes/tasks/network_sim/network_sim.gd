extends Control

## Simulador de topologías: el lienzo, la barra de equipos y cables, el
## interruptor Tiempo real / Simulación y la ventana de cada equipo.
## Es uno solo, compartido: las tareas le piden un escenario y escuchan lo que
## hace el jugador, igual que las tareas de consola con la Terminal.

signal ping_result(device_id: String, target_ip: String, ok: bool)
signal model_changed()
signal actions_finished()

## Lo que tarda el asistente entre un paso y el siguiente, para que se vea.
const ACTION_DELAY: float = 0.55
## Y entre cada campo cuando llena una configuración.
const FIELD_DELAY: float = 0.3

var model: NetModel = null
var is_simulation: bool = false

var _open_device: String = ""
var _packet_callback: Callable = Callable()
var _actions: Array[Dictionary] = []
var _action_total: int = 0
var _action_timer: float = 0.0
var _waiting_console: ConsoleView = null

@onready var canvas: NetworkCanvas = $Canvas
@onready var mode_toggle: CheckButton = $ModeToggle
@onready var status_label: Label = $BottomBar/StatusLabel
@onready var cable_buttons: Dictionary = {
	NetModel.CABLE_STRAIGHT: $BottomBar/StraightButton,
	NetModel.CABLE_CROSSOVER: $BottomBar/CrossButton,
	NetModel.CABLE_FIBER: $BottomBar/FiberButton,
}

@onready var device_window: Control = $DeviceWindow
@onready var device_title: Label = $DeviceWindow/TitleLabel
@onready var tabs: TabContainer = $DeviceWindow/Tabs
@onready var config_tab: Control = $DeviceWindow/Tabs/Config
@onready var ip_field: LineEdit = $DeviceWindow/Tabs/Config/IpField
@onready var mask_field: LineEdit = $DeviceWindow/Tabs/Config/MaskField
@onready var gateway_field: LineEdit = $DeviceWindow/Tabs/Config/GatewayField
@onready var apply_button: Button = $DeviceWindow/Tabs/Config/ApplyButton
@onready var config_status: Label = $DeviceWindow/Tabs/Config/StatusLabel
@onready var console_tab: DeviceConsole = $DeviceWindow/Tabs/Console
@onready var cli_tab: RouterCli = $DeviceWindow/Tabs/Cli
@onready var info_label: Label = $DeviceWindow/Tabs/Info/InfoLabel


func _ready() -> void:
	model = NetModel.new()
	model.changed.connect(_on_model_changed)
	canvas.set_model(model)
	canvas.device_clicked.connect(open_device)
	canvas.link_rejected.connect(_on_link_rejected)
	canvas.link_created.connect(_on_link_created)
	canvas.packet_arrived.connect(_on_packet_arrived)

	mode_toggle.toggled.connect(_on_mode_toggled)
	apply_button.pressed.connect(_on_apply_pressed)
	$DeviceWindow/CloseButton.pressed.connect(close_device)
	for kind_id: String in ["Router", "Switch", "Pc", "Server"]:
		var button: Button = $BottomBar.get_node(kind_id + "Button")
		button.pressed.connect(_on_add_device.bind(kind_id))
	for cable: String in cable_buttons:
		(cable_buttons[cable] as Button).pressed.connect(set_cable.bind(cable))

	tabs.set_tab_title(0, "Configuración")
	tabs.set_tab_title(1, "Consola")
	tabs.set_tab_title(2, "CLI")
	tabs.set_tab_title(3, "Información")

	device_window.visible = false
	set_cable(NetModel.CABLE_STRAIGHT)
	_refresh_mode_label()


## Carga un escenario de data/network_scenarios.gd y limpia lo anterior.
func load_scenario(scenario: String) -> void:
	cancel_actions()
	close_device()
	model.clear()
	NetworkScenarios.build(scenario, model)
	canvas.queue_redraw()
	status_label.text = "Elige un cable y arrastra de un puerto a otro."


# --- Barra de abajo -----------------------------------------------------------

func set_cable(cable: String) -> void:
	canvas.set_cable(cable)
	for name: String in cable_buttons:
		(cable_buttons[name] as Button).button_pressed = name == cable
	status_label.text = "Cable seleccionado: " + cable


## Los botones de equipos agregan uno nuevo al lienzo, por si hace falta.
func _on_add_device(kind_id: String) -> void:
	var device: NetDevice = NetDevice.new()
	match kind_id:
		"Router":
			device.kind = NetDevice.Kind.ROUTER
			device.port_count = 2
			device.top_ports = 0
		"Switch":
			device.kind = NetDevice.Kind.SWITCH
			device.port_count = 6
			device.top_ports = 2
		"Server":
			device.kind = NetDevice.Kind.SERVER
			device.port_count = 1
			device.top_ports = 0
		_:
			device.kind = NetDevice.Kind.PC
			device.port_count = 1
			device.top_ports = 1
	var index: int = model.device_order.size() + 1
	device.id = "%s%d" % [kind_id.to_lower(), index]
	device.label = "%s-%d" % [device.kind_name().to_upper(), index]
	device.position = Vector2(0.08 + 0.12 * float(index % 7), 0.33)
	model.add_device(device)
	model.validate()
	canvas.queue_redraw()
	status_label.text = "Agregado: " + device.label


func _on_mode_toggled(pressed: bool) -> void:
	is_simulation = pressed
	_refresh_mode_label()


func _refresh_mode_label() -> void:
	mode_toggle.text = "Simulación" if is_simulation else "Tiempo real"


func _on_link_rejected(reason: String) -> void:
	status_label.text = reason


func _on_link_created(_device_id: String) -> void:
	status_label.text = "Enlace creado."


func _on_model_changed() -> void:
	if not _open_device.is_empty():
		_refresh_device_window()
	model_changed.emit()


# --- Ventana del equipo -------------------------------------------------------

## Abre la ventana del equipo con las pestañas que le tocan.
func open_device(device_id: String) -> void:
	var device: NetDevice = model.device(device_id)
	if device == null:
		return
	_open_device = device_id
	device_title.text = "%s  (%s)" % [device.label, device.kind_name()]

	var is_pc: bool = device.is_configurable()
	var is_router: bool = device.kind == NetDevice.Kind.ROUTER
	tabs.set_tab_hidden(0, not is_pc)
	tabs.set_tab_hidden(1, not is_pc)
	tabs.set_tab_hidden(2, not is_router)
	tabs.set_tab_hidden(3, is_pc or is_router)

	if is_pc:
		console_tab.bind(self, device_id)
		tabs.current_tab = 0
	elif is_router:
		cli_tab.bind(self, device_id)
		tabs.current_tab = 2
	else:
		tabs.current_tab = 3

	_refresh_device_window()
	device_window.visible = true


func close_device() -> void:
	_open_device = ""
	device_window.visible = false


func _refresh_device_window() -> void:
	var device: NetDevice = model.device(_open_device)
	if device == null:
		return
	if device.is_configurable():
		if not ip_field.has_focus():
			ip_field.text = device.ip
		if not mask_field.has_focus():
			mask_field.text = device.mask
		if not gateway_field.has_focus():
			gateway_field.text = device.gateway
		config_status.text = _link_problem_for(device.id)
	else:
		info_label.text = "%s\nPuertos: %d\nEnlaces: %d" % [
			device.label, device.port_count, _link_count_for(device.id)]


## El motivo del enlace en rojo, para enseñarlo en la ventana del equipo.
func _link_problem_for(device_id: String) -> String:
	for link: NetLink in model.links:
		if link.touches(device_id) and not link.ok:
			return link.reason
	return "Enlace correcto." if _link_count_for(device_id) > 0 else "Sin cablear."


func _link_count_for(device_id: String) -> int:
	var count: int = 0
	for link: NetLink in model.links:
		if link.touches(device_id):
			count += 1
	return count


func _on_apply_pressed() -> void:
	if _open_device.is_empty():
		return
	model.set_config(_open_device, ip_field.text, mask_field.text, gateway_field.text)
	_refresh_device_window()


# --- Paquetes y pings ---------------------------------------------------------

## Manda el sobre por la ruta y avisa al terminar. En Tiempo real no anima.
func send_packet(path: PackedStringArray, on_arrived: Callable) -> void:
	_packet_callback = on_arrived
	canvas.play_packet(path)


func _on_packet_arrived() -> void:
	if _packet_callback.is_valid():
		var callback: Callable = _packet_callback
		_packet_callback = Callable()
		callback.call()


## Las consolas avisan aquí el resultado de cada ping.
func notify_ping(device_id: String, target_ip: String, ok: bool) -> void:
	ping_result.emit(device_id, target_ip, ok)


# --- Automatización del asistente --------------------------------------------

## Pasos que el asistente va haciendo a la vista: cables, campos y comandos.
func queue_actions(actions: Array[Dictionary]) -> void:
	cancel_actions()
	_actions = actions.duplicate()
	_action_total = _actions.size()
	_action_timer = 0.0


func cancel_actions() -> void:
	_actions.clear()
	_action_total = 0
	_action_timer = 0.0
	_waiting_console = null
	if cli_tab != null:
		cli_tab.cancel_typing()
	if console_tab != null:
		console_tab.cancel_typing()


func is_automating() -> bool:
	return not _actions.is_empty() or _waiting_console != null


func automation_progress() -> float:
	if _action_total <= 0:
		return 0.0
	return clampf(float(_action_total - _actions.size()) / float(_action_total), 0.0, 1.0)


func _process(delta: float) -> void:
	if _waiting_console != null:
		if _waiting_console.is_typing():
			return
		_waiting_console = null
	if _actions.is_empty():
		return
	_action_timer -= delta
	if _action_timer > 0.0:
		return
	var action: Dictionary = _actions[0]
	_actions.remove_at(0)
	_run_action(action)
	# Escribir un campo es más rápido que cablear o abrir una ventana.
	_action_timer = FIELD_DELAY if str(action.get("type", "")) == "field" else ACTION_DELAY
	if _actions.is_empty() and _waiting_console == null:
		actions_finished.emit()


func _run_action(action: Dictionary) -> void:
	match str(action.get("type", "")):
		"link":
			model.connect_ports(str(action["a"]), int(action["ap"]),
				str(action["b"]), int(action["bp"]), str(action["cable"]))
			status_label.text = "El asistente conecto %s con %s." % [action["a"], action["b"]]
		"open":
			open_device(str(action["id"]))
		"field":
			_fill_field(str(action["field"]), str(action["value"]))
		"apply":
			_on_apply_pressed()
		"cli":
			open_device(str(action["id"]))
			cli_tab.queue_commands(PackedStringArray(action["commands"]))
			_waiting_console = cli_tab
		"console":
			open_device(str(action["id"]))
			tabs.current_tab = 1
			console_tab.queue_commands(PackedStringArray(action["commands"]))
			_waiting_console = console_tab


## Escribe un campo de la configuración, como si lo teclearan.
func _fill_field(field: String, value: String) -> void:
	match field:
		"ip":
			ip_field.text = value
		"mask":
			mask_field.text = value
		"gateway":
			gateway_field.text = value

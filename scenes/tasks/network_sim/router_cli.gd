class_name RouterCli
extends ConsoleView

## CLI del router, con los niveles de siempre: usuario, privilegiado,
## configuración global y configuración de interfaz. El prompt cambia con el
## nivel y los comandos solo se aceptan donde corresponde.

enum Level { USER, PRIVILEGED, CONFIG, INTERFACE }

const INVALID: String = "% Invalid input detected at '^' marker."
const INTERFACE_NAME: String = "GigabitEthernet0/0"

var level: Level = Level.USER

var _sim: Node = null
var _device_id: String = ""
var _pending_ip: String = ""
var _pending_mask: String = ""


func bind(sim: Node, device_id: String) -> void:
	_sim = sim
	_device_id = device_id
	level = Level.USER
	_pending_ip = ""
	_pending_mask = ""
	cancel_typing()
	clear_screen()
	append_line("Conectado por consola a " + _hostname())
	append_line("")
	_refresh()


func prompt() -> String:
	match level:
		Level.PRIVILEGED:
			return _hostname() + "#"
		Level.CONFIG:
			return _hostname() + "(config)#"
		Level.INTERFACE:
			return _hostname() + "(config-if)#"
		_:
			return _hostname() + ">"


func _hostname() -> String:
	var device: NetDevice = _device()
	return "ROUTER" if device == null else device.label


func _device() -> NetDevice:
	if _sim == null:
		return null
	return _sim.model.device(_device_id)


func _run(raw: String) -> void:
	var command: String = raw.strip_edges().to_lower()
	if command.is_empty():
		return

	if command == "enable" or command == "en":
		_cmd_enable()
	elif command == "configure terminal" or command == "conf t":
		_cmd_configure()
	elif command.begins_with("interface "):
		_cmd_interface(command.substr("interface ".length()))
	elif command.begins_with("ip address "):
		_cmd_ip_address(command.substr("ip address ".length()))
	elif command == "no shutdown" or command == "no shut":
		_cmd_no_shutdown()
	elif command == "shutdown":
		_cmd_shutdown()
	elif command == "exit":
		_cmd_exit()
	elif command == "end":
		level = Level.PRIVILEGED if level != Level.USER else Level.USER
	elif command == "show ip interface brief":
		_cmd_show_brief()
	elif command == "cls":
		clear_screen()
	elif command == "?" or command == "help":
		_cmd_help()
	else:
		append_lines(PackedStringArray([INVALID, ""]))


func _cmd_enable() -> void:
	if level != Level.USER:
		append_lines(PackedStringArray([INVALID, ""]))
		return
	level = Level.PRIVILEGED


func _cmd_configure() -> void:
	if level != Level.PRIVILEGED:
		append_lines(PackedStringArray(["% Primero entra en modo privilegiado con enable.", ""]))
		return
	level = Level.CONFIG
	append_lines(PackedStringArray([
		"Enter configuration commands, one per line. End with CNTL/Z.", ""]))


func _cmd_interface(name: String) -> void:
	if level != Level.CONFIG and level != Level.INTERFACE:
		append_lines(PackedStringArray(["% Primero entra en configure terminal.", ""]))
		return
	var cleaned: String = name.strip_edges()
	if cleaned != "g0/0" and cleaned != "gi0/0" and cleaned != "gigabitethernet0/0":
		append_lines(PackedStringArray(["% Esa interfaz no existe en este router.", ""]))
		return
	level = Level.INTERFACE


func _cmd_ip_address(args: String) -> void:
	if level != Level.INTERFACE:
		append_lines(PackedStringArray(["% Este comando va dentro de interface g0/0.", ""]))
		return
	var parts: PackedStringArray = args.split(" ", false)
	if parts.size() < 2:
		append_lines(PackedStringArray(["% Incomplete command.", ""]))
		return
	if not CampusNetwork.looks_like_ip(parts[0]) or not CampusNetwork.looks_like_ip(parts[1]):
		append_lines(PackedStringArray([INVALID, ""]))
		return
	_pending_ip = parts[0]
	_pending_mask = parts[1]
	_apply_to_device()


func _cmd_no_shutdown() -> void:
	if level != Level.INTERFACE:
		append_lines(PackedStringArray(["% Este comando va dentro de interface g0/0.", ""]))
		return
	var device: NetDevice = _device()
	if device == null:
		return
	if device.ip.is_empty() and _pending_ip.is_empty():
		append_lines(PackedStringArray([
			"% La interfaz no tiene direccion IP todavia.", ""]))
		return
	_sim.model.set_interface_up(_device_id, true)
	append_lines(PackedStringArray([
		"%%LINK-5-CHANGED: Interface %s, changed state to up" % INTERFACE_NAME, ""]))


func _cmd_shutdown() -> void:
	if level != Level.INTERFACE:
		append_lines(PackedStringArray(["% Este comando va dentro de interface g0/0.", ""]))
		return
	_sim.model.set_interface_up(_device_id, false)
	append_lines(PackedStringArray([
		"%%LINK-5-CHANGED: Interface %s, changed state to down" % INTERFACE_NAME, ""]))


func _cmd_exit() -> void:
	match level:
		Level.INTERFACE:
			level = Level.CONFIG
		Level.CONFIG:
			level = Level.PRIVILEGED
		Level.PRIVILEGED:
			level = Level.USER
		_:
			pass


func _cmd_show_brief() -> void:
	if level == Level.USER:
		append_lines(PackedStringArray(["% Primero entra en modo privilegiado con enable.", ""]))
		return
	var device: NetDevice = _device()
	if device == null:
		return
	append_line("")
	append_line("Interface              IP-Address      Status")
	append_line("%-22s %-15s %s" % [INTERFACE_NAME,
		"unassigned" if device.ip.is_empty() else device.ip,
		"up" if device.interface_up else "administratively down"])
	append_line("")


func _cmd_help() -> void:
	append_line("Comandos: enable, configure terminal, interface g0/0,")
	append_line("ip address <ip> <mascara>, no shutdown, shutdown,")
	append_line("show ip interface brief, exit, end, cls")
	append_line("")


## La IP se guarda en el equipo en cuanto se escribe el comando.
func _apply_to_device() -> void:
	var device: NetDevice = _device()
	if device == null:
		return
	_sim.model.set_config(_device_id, _pending_ip, _pending_mask, "")

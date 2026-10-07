class_name RouterCli
extends ConsoleView

## CLI de los equipos de red, con los niveles de siempre: usuario,
## privilegiado, configuración global, configuración de interfaz y
## configuración de un pool de DHCP. El prompt cambia con el nivel y los
## comandos solo se aceptan donde corresponde.
##
## Sirve igual para el router y para el switch: según el equipo cambian las
## interfaces que acepta y los comandos que tienen sentido. En el switch van
## las VLAN de cada puerto; en el router, la dirección de g0/0 y las reservas
## de DHCP.

enum Level { USER, PRIVILEGED, CONFIG, INTERFACE, POOL }

const INVALID: String = "% Invalid input detected at '^' marker."
const INTERFACE_NAME: String = "GigabitEthernet0/0"

var level: Level = Level.USER

var _sim: Node = null
var _device_id: String = ""
var _pending_ip: String = ""
var _pending_mask: String = ""
## El puerto de switch que se está configurando, o -1 si ninguno.
var _port: int = -1
## El pool de DHCP que se está configurando, o cadena vacía.
var _pool: String = ""


func bind(sim: Node, device_id: String) -> void:
	_sim = sim
	_device_id = device_id
	level = Level.USER
	_pending_ip = ""
	_pending_mask = ""
	_port = -1
	_pool = ""
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
		Level.POOL:
			return _hostname() + "(config-dhcp)#"
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
	elif command.begins_with("switchport access vlan "):
		_cmd_access_vlan(command.substr("switchport access vlan ".length()))
	elif command.begins_with("ip dhcp pool "):
		_cmd_dhcp_pool(command.substr("ip dhcp pool ".length()))
	elif command.begins_with("host "):
		_cmd_host(command.substr("host ".length()))
	elif command == "show vlan brief":
		_cmd_show_vlan()
	elif command == "show ip dhcp binding":
		_cmd_show_bindings()
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
	var device: NetDevice = _device()
	if device != null and device.kind == NetDevice.Kind.SWITCH:
		var port: int = _port_from_name(cleaned)
		if port < 0 or port >= device.port_count:
			append_lines(PackedStringArray(["% Ese puerto no existe en este switch.", ""]))
			return
		_port = port
		level = Level.INTERFACE
		return
	if cleaned != "g0/0" and cleaned != "gi0/0" and cleaned != "gigabitethernet0/0":
		append_lines(PackedStringArray(["% Esa interfaz no existe en este router.", ""]))
		return
	_port = -1
	level = Level.INTERFACE


## "f0/3" o "fa0/3" -> el puerto 2, porque en pantalla se cuentan desde 1.
func _port_from_name(name: String) -> int:
	var cleaned: String = name.replace("fastethernet", "").replace("fa", "").replace("f", "")
	var parts: PackedStringArray = cleaned.split("/", false)
	if parts.is_empty():
		return -1
	var number: String = parts[parts.size() - 1].strip_edges()
	if not number.is_valid_int():
		return -1
	return int(number) - 1


## La VLAN de acceso del puerto que se está configurando, en el switch.
func _cmd_access_vlan(args: String) -> void:
	var device: NetDevice = _device()
	if device == null or device.kind != NetDevice.Kind.SWITCH:
		append_lines(PackedStringArray(["% Este comando es de un switch.", ""]))
		return
	if level != Level.INTERFACE or _port < 0:
		append_lines(PackedStringArray(["% Primero entra en interface f0/<puerto>.", ""]))
		return
	var number: String = args.strip_edges()
	if not number.is_valid_int() or int(number) < 1 or int(number) > 4094:
		append_lines(PackedStringArray(["% La VLAN va de 1 a 4094.", ""]))
		return
	device.port_vlans[_port] = int(number)
	_sim.model.validate()
	_sim.model_changed.emit()
	append_lines(PackedStringArray([
		"%% El puerto %d queda en la VLAN %s." % [_port + 1, number], ""]))
	_refresh()


## Abre (o crea) un pool de DHCP en el router, para reservar una dirección.
func _cmd_dhcp_pool(args: String) -> void:
	var device: NetDevice = _device()
	if device == null or device.kind != NetDevice.Kind.ROUTER:
		append_lines(PackedStringArray(["% Este comando es de un router.", ""]))
		return
	if level != Level.CONFIG and level != Level.POOL:
		append_lines(PackedStringArray(["% Primero entra en configure terminal.", ""]))
		return
	var name: String = args.strip_edges()
	if name.is_empty():
		append_lines(PackedStringArray(["% Falta el nombre del pool.", ""]))
		return
	_pool = name
	level = Level.POOL


## La dirección reservada dentro del pool abierto.
func _cmd_host(args: String) -> void:
	if level != Level.POOL or _pool.is_empty():
		append_lines(PackedStringArray(["% Este comando va dentro de ip dhcp pool.", ""]))
		return
	var parts: PackedStringArray = args.split(" ", false)
	if parts.size() < 2:
		append_lines(PackedStringArray(["% Uso: host <ip> <mascara>", ""]))
		return
	var device: NetDevice = _device()
	if device == null:
		return
	device.reservations[_pool] = {"ip": parts[0].strip_edges(), "mask": parts[1].strip_edges()}
	_sim.apply_reservations()
	append_lines(PackedStringArray([
		"%% Reservada %s para el pool %s." % [parts[0], _pool], ""]))
	_refresh()


func _cmd_show_vlan() -> void:
	var device: NetDevice = _device()
	if device == null or device.kind != NetDevice.Kind.SWITCH:
		append_lines(PackedStringArray(["% Este comando es de un switch.", ""]))
		return
	append_lines(PackedStringArray(["VLAN Puerto    Estado", "---- --------- ------"]))
	for port: int in device.port_count:
		append_line("%-4d f0/%-6d activo" % [device.vlan_of_port(port), port + 1])
	append_line("")


func _cmd_show_bindings() -> void:
	var device: NetDevice = _device()
	if device == null or device.kind != NetDevice.Kind.ROUTER:
		append_lines(PackedStringArray(["% Este comando es de un router.", ""]))
		return
	if device.reservations.is_empty():
		append_lines(PackedStringArray(["No hay reservas.", ""]))
		return
	append_lines(PackedStringArray(["Pool           Direccion        Mascara", "-------------- ---------------- ---------------"]))
	for pool: String in device.reservations:
		var entry: Dictionary = device.reservations[pool]
		append_line("%-14s %-16s %s" % [pool, entry.get("ip", ""), entry.get("mask", "")])
	append_line("")


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
		Level.POOL:
			_pool = ""
			level = Level.CONFIG
		Level.INTERFACE:
			_port = -1
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

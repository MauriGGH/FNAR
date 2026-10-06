class_name DeviceConsole
extends ConsoleView

## Mini consola de una PC o un servidor del simulador: solo ipconfig y ping.
## En modo Simulación el ping no contesta al momento: manda el sobre por los
## cables y las respuestas salen cuando llega.

const PING_COUNT: int = 4

var _sim: Node = null
var _device_id: String = ""
var _pending_ping: String = ""


func bind(sim: Node, device_id: String) -> void:
	_sim = sim
	_device_id = device_id
	_pending_ping = ""
	cancel_typing()
	clear_screen()
	append_line("Consola de " + _label())
	append_line("Comandos: ipconfig, ping <ip>, cls, help")
	append_line("")
	_refresh()


func prompt() -> String:
	return "C:\\>"


func _label() -> String:
	var device: NetDevice = _device()
	return "equipo" if device == null else device.label


func _device() -> NetDevice:
	if _sim == null:
		return null
	return _sim.model.device(_device_id)


func _run(raw: String) -> void:
	var command: String = raw.strip_edges()
	if command.is_empty():
		return
	var parts: PackedStringArray = command.split(" ", false)
	match parts[0].to_lower():
		"help":
			append_lines(PackedStringArray(["Comandos: ipconfig, ping <ip>, cls, help", ""]))
		"cls":
			clear_screen()
		"ipconfig":
			_cmd_ipconfig()
		"ping":
			_cmd_ping(parts.slice(1))
		_:
			append_lines(PackedStringArray([
				"'%s' no se reconoce como un comando." % parts[0], ""]))


func _cmd_ipconfig() -> void:
	var device: NetDevice = _device()
	if device == null:
		return
	append_line("")
	append_line("Adaptador de Ethernet:")
	append_line("   Direccion IPv4  . . . . : " + _or_none(device.ip))
	append_line("   Mascara de subred . . . : " + _or_none(device.mask))
	append_line("   Puerta de enlace  . . . : " + _or_none(device.gateway))
	append_line("")


func _or_none(value: String) -> String:
	return "(sin configurar)" if value.is_empty() else value


func _cmd_ping(args: PackedStringArray) -> void:
	if args.is_empty():
		append_lines(PackedStringArray(["Uso: ping <ip>", ""]))
		return
	var target_ip: String = args[0]
	if not CampusNetwork.looks_like_ip(target_ip):
		append_lines(PackedStringArray(["Host de destino no valido: " + target_ip, ""]))
		return

	var target: NetDevice = _sim.model.device_by_ip(target_ip)
	if target == null:
		append_lines(PackedStringArray([
			"", "Haciendo ping a %s con 32 bytes de datos:" % target_ip,
			"Host de destino inaccesible.", ""]))
		_sim.notify_ping(_device_id, target_ip, false)
		return

	var result: Dictionary = _sim.model.reach(_device_id, target.id)
	append_line("")
	append_line("Haciendo ping a %s con 32 bytes de datos:" % target_ip)
	if not result["ok"]:
		for i: int in PING_COUNT:
			append_line("Tiempo de espera agotado para esta solicitud.")
		append_line(str(result["reason"]))
		append_line("")
		_sim.notify_ping(_device_id, target_ip, false)
		return

	# En Simulación se ve el sobre viajando y la respuesta llega después.
	if _sim.is_simulation:
		append_line("Enviando paquete por la red...")
		append_line("")
		_pending_ping = target_ip
		_sim.send_packet(result["path"], _on_packet_arrived)
		return
	_print_replies(target_ip)


func _on_packet_arrived() -> void:
	if _pending_ping.is_empty():
		return
	var target_ip: String = _pending_ping
	_pending_ping = ""
	_print_replies(target_ip)
	_refresh()


func _print_replies(target_ip: String) -> void:
	for i: int in PING_COUNT:
		append_line("Respuesta desde %s: bytes=32 tiempo=%dms TTL=128" % [target_ip, randi_range(1, 6)])
	append_line("")
	append_line("Estadisticas de ping para %s:" % target_ip)
	append_line("    Paquetes: enviados = 4, recibidos = 4, perdidos = 0")
	append_line("")
	_sim.notify_ping(_device_id, target_ip, true)

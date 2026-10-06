class_name PcTerminal
extends ConsoleView

## Consola de la PC, estilo símbolo del sistema. Lleva su propia copia simulada
## de la red del campus: el estado de los servicios y qué equipo del
## laboratorio no responde esta noche. Los paneles de las tareas se enganchan
## a sus señales para saber lo que hizo el jugador.
## Lo genérico de una consola (cursor, historial, escritura del asistente) está
## en ConsoleView.

signal service_queried(service: String, state: String)
signal service_state_changed(service: String, state: String)
signal host_pinged(ip: String, responded: bool)
signal host_reported(ip: String)

const PROMPT: String = "C:\\COORDINACION>"
const PING_COUNT: int = 4

var services: Dictionary = {}       # nombre -> estado
var service_errors: Dictionary = {} # nombre -> código de error
var dead_lab_ip: String = ""


func _ready() -> void:
	super()
	reset_for_night()


func prompt() -> String:
	return PROMPT


# --- Estado simulado de la noche ---------------------------------------------

## Deja la consola y la red como al principio de una noche.
func reset_for_night() -> void:
	services.clear()
	service_errors.clear()
	for service: String in CampusNetwork.RUNNING_SERVICES:
		services[service] = CampusNetwork.STATE_RUNNING
		service_errors[service] = 0
	for service: String in CampusNetwork.BROKEN_SERVICES:
		services[service] = CampusNetwork.STATE_STOPPED
		service_errors[service] = CampusNetwork.BROKEN_SERVICES[service]

	# Un equipo del laboratorio distinto cada noche.
	dead_lab_ip = CampusNetwork.LAB_HOSTS[randi() % CampusNetwork.LAB_HOSTS.size()]

	cancel_typing()
	_history.clear()
	_history_index = -1
	_input = ""
	_lines.clear()
	append_line("Consola de la Coordinacion de Sistemas [version 3.1]")
	append_line("Escribe help para ver los comandos.")
	append_line("")
	_refresh()


func service_state(service: String) -> String:
	return services.get(service, "")


## true si el equipo contesta un ping.
func is_host_up(ip: String) -> bool:
	if not CampusNetwork.is_known_host(ip):
		return false
	return ip != dead_lab_ip


# --- Comandos -----------------------------------------------------------------

func _run(raw: String) -> void:
	var command: String = raw.strip_edges()
	if command.is_empty():
		return
	var parts: PackedStringArray = command.split(" ", false)
	var verb: String = parts[0].to_lower()
	var args: PackedStringArray = parts.slice(1)

	match verb:
		"help":
			_cmd_help()
		"cls":
			clear_screen()
		"ipconfig":
			_cmd_ipconfig()
		"ping":
			_cmd_ping(args)
		"tracert":
			_cmd_tracert(args)
		"netstat":
			_cmd_netstat()
		"sc":
			_cmd_sc(args)
		"net":
			_cmd_net(args)
		"reportar":
			_cmd_reportar(args)
		_:
			append_line("'%s' no se reconoce como un comando interno o externo," % parts[0])
			append_line("programa o archivo por lotes ejecutable.")
			append_line("")


func _cmd_help() -> void:
	append_line("Comandos disponibles:")
	append_line("  help                  muestra esta lista")
	append_line("  cls                   limpia la pantalla")
	append_line("  ipconfig              configuracion de red del equipo")
	append_line("  ping <ip>             prueba si un equipo responde")
	append_line("  tracert <ip>          ruta hasta un equipo")
	append_line("  netstat               conexiones activas")
	append_line("  sc query <servicio>   estado de un servicio")
	append_line("  net stop <servicio>   detiene un servicio")
	append_line("  net start <servicio>  inicia un servicio")
	append_line("  reportar <ip>         reporta un equipo a la mesa de ayuda")
	append_line("")


func _cmd_ipconfig() -> void:
	append_line("Configuracion IP de Windows")
	append_line("")
	append_line("Adaptador de Ethernet Red del campus:")
	append_line("   Nombre del equipo . . . : " + CampusNetwork.HOSTNAME)
	append_line("   Direccion fisica  . . . : " + CampusNetwork.MAC)
	append_line("   Direccion IPv4  . . . . : " + CampusNetwork.LOCAL_IP)
	append_line("   Mascara de subred . . . : " + CampusNetwork.SUBNET_MASK)
	append_line("   Puerta de enlace  . . . : " + CampusNetwork.GATEWAY)
	append_line("   Servidores DNS  . . . . : " + CampusNetwork.DNS_PRIMARY)
	append_line("                             " + CampusNetwork.DNS_SECONDARY)
	append_line("")


func _cmd_ping(args: PackedStringArray) -> void:
	if args.is_empty():
		append_line("Uso: ping <ip>")
		append_line("")
		return
	var ip: String = args[0]
	if not CampusNetwork.looks_like_ip(ip):
		append_line("La solicitud de ping no pudo encontrar al host " + ip + ".")
		append_line("Compruebe el nombre y vuelva a intentarlo.")
		append_line("")
		return

	var up: bool = is_host_up(ip)
	append_line("")
	append_line("Haciendo ping a %s con 32 bytes de datos:" % ip)
	for i: int in PING_COUNT:
		if up:
			append_line("Respuesta desde %s: bytes=32 tiempo=%dms TTL=128" % [ip, randi_range(1, 9)])
		else:
			append_line("Tiempo de espera agotado para esta solicitud.")
	append_line("")
	append_line("Estadisticas de ping para %s:" % ip)
	if up:
		append_line("    Paquetes: enviados = 4, recibidos = 4, perdidos = 0")
	else:
		append_line("    Paquetes: enviados = 4, recibidos = 0, perdidos = 4")
	append_line("")
	host_pinged.emit(ip, up)


func _cmd_tracert(args: PackedStringArray) -> void:
	if args.is_empty():
		append_line("Uso: tracert <ip>")
		append_line("")
		return
	var ip: String = args[0]
	if not CampusNetwork.looks_like_ip(ip):
		append_line("No se puede resolver el nombre de destino " + ip + ".")
		append_line("")
		return

	var hops: PackedStringArray = CampusNetwork.route_to(ip)
	var up: bool = is_host_up(ip)
	append_line("")
	append_line("Traza a %s sobre un maximo de 30 saltos:" % ip)
	for i: int in hops.size():
		var is_last: bool = i == hops.size() - 1
		if is_last and not up:
			append_line("  %d     *      *     Tiempo de espera agotado." % (i + 1))
		else:
			append_line("  %d    %2d ms  %s" % [i + 1, randi_range(1, 12), hops[i]])
	append_line("Traza completa." if up else "No se pudo completar la traza.")
	append_line("")


func _cmd_netstat() -> void:
	append_line("")
	append_line("Conexiones activas")
	append_line("")
	append_line(_netstat_row("Proto", "Local", "Remoto", "Estado"))
	append_line(_netstat_row("TCP", CampusNetwork.LOCAL_IP + ":50312", "192.168.1.10:25", _mail_connection_state()))
	append_line(_netstat_row("TCP", CampusNetwork.LOCAL_IP + ":50318", CampusNetwork.DNS_PRIMARY + ":53", "ESTABLISHED"))
	append_line(_netstat_row("TCP", CampusNetwork.LOCAL_IP + ":50401", "192.168.1.20:445", "ESTABLISHED"))
	append_line(_netstat_row("TCP", CampusNetwork.LOCAL_IP + ":139", "0.0.0.0:0", "LISTENING"))
	append_line("")


## Columnas de ancho fijo, para que queden alineadas como en una consola.
func _netstat_row(proto: String, local: String, remote: String, state: String) -> String:
	return "  %-5s %-20s %-17s %s" % [proto, local, remote, state]


## La conexión al correo se ve caída mientras el servicio esté detenido.
func _mail_connection_state() -> String:
	return "ESTABLISHED" if service_state("correo") == CampusNetwork.STATE_RUNNING else "SYN_SENT"


func _cmd_sc(args: PackedStringArray) -> void:
	if args.size() < 2 or args[0].to_lower() != "query":
		append_line("Uso: sc query <servicio>")
		append_line("")
		return
	var service: String = args[1].to_lower()
	if not services.has(service):
		append_line("[SC] OpenService ERROR 1060:")
		append_line("El servicio especificado no existe.")
		append_line("")
		return

	var state: String = services[service]
	append_line("")
	append_line("NOMBRE_SERVICIO: " + service)
	append_line("        TIPO            : 10  WIN32_OWN_PROCESS")
	append_line("        ESTADO          : %d  %s" % [CampusNetwork.STATE_CODES.get(state, 1), state])
	append_line("        CODIGO_SALIDA   : %d" % int(service_errors.get(service, 0)))
	append_line("")
	service_queried.emit(service, state)


func _cmd_net(args: PackedStringArray) -> void:
	if args.size() < 2:
		append_line("Uso: net stop <servicio> | net start <servicio>")
		append_line("")
		return
	var action: String = args[0].to_lower()
	var service: String = args[1].to_lower()
	if not services.has(service):
		append_line("No se encontro el nombre de servicio.")
		append_line("Escriba NET HELPMSG 2185 para obtener mas ayuda.")
		append_line("")
		return

	var display: String = CampusNetwork.SERVICES.get(service, service)
	match action:
		"stop":
			_net_stop(service, display)
		"start":
			_net_start(service, display)
		_:
			append_line("Uso: net stop <servicio> | net start <servicio>")
			append_line("")


func _net_stop(service: String, display: String) -> void:
	var state: String = services[service]
	var error_code: int = int(service_errors.get(service, 0))
	if state == CampusNetwork.STATE_STOPPED and error_code == 0:
		append_line("El %s no se ha iniciado." % display)
		append_line("")
		return

	# Si quedó detenido con error, el proceso sigue trabado: pararlo lo libera.
	if state == CampusNetwork.STATE_STOPPED:
		append_line("El %s tiene una instancia bloqueada." % display)
	else:
		append_line("El %s se esta deteniendo." % display)
	service_errors[service] = 0
	_set_service_state(service, CampusNetwork.STATE_STOPPED)
	append_line("El %s se detuvo satisfactoriamente." % display)
	append_line("")


func _net_start(service: String, display: String) -> void:
	var state: String = services[service]
	if state == CampusNetwork.STATE_RUNNING:
		append_line("El %s ya se ha iniciado." % display)
		append_line("")
		return

	var error_code: int = int(service_errors.get(service, 0))
	if error_code != 0:
		# Hay que liberar la instancia trabada antes de poder arrancarlo.
		append_line("El %s no se pudo iniciar." % display)
		append_line("Error %d: el proceso termino inesperadamente." % error_code)
		append_line("Detenga el servicio y vuelva a intentarlo.")
		append_line("")
		return

	append_line("El %s se esta iniciando." % display)
	_set_service_state(service, CampusNetwork.STATE_RUNNING)
	append_line("El %s se inicio correctamente." % display)
	append_line("")


func _set_service_state(service: String, state: String) -> void:
	services[service] = state
	service_state_changed.emit(service, state)


func _cmd_reportar(args: PackedStringArray) -> void:
	if args.is_empty():
		append_line("Uso: reportar <ip>")
		append_line("")
		return
	var ip: String = args[0]
	if not CampusNetwork.looks_like_ip(ip):
		append_line("Direccion no valida: " + ip)
		append_line("")
		return
	append_line("Reporte enviado a la mesa de ayuda: " + ip)
	append_line("Folio: CS-%d" % randi_range(1000, 9999))
	append_line("")
	host_reported.emit(ip)

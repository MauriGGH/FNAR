class_name NetModel
extends RefCounted

## El modelo del simulador de red: los equipos, los cables y las reglas.
## Cada vez que algo cambia revisa todos los enlaces y les pone por qué
## fallan, que es lo que el lienzo pinta en rojo.

signal changed()
signal config_changed(device_id: String)

const CABLE_STRAIGHT: String = "recto"
const CABLE_CROSSOVER: String = "cruzado"
const CABLE_FIBER: String = "fibra"
const CABLES: Array[String] = [CABLE_STRAIGHT, CABLE_CROSSOVER, CABLE_FIBER]

var device_order: PackedStringArray = PackedStringArray()
var devices: Dictionary = {}  # id -> NetDevice
var links: Array[NetLink] = []


func clear() -> void:
	device_order.clear()
	devices.clear()
	links.clear()
	changed.emit()


func add_device(device: NetDevice) -> void:
	devices[device.id] = device
	device_order.append(device.id)


func device(id: String) -> NetDevice:
	return devices.get(id, null)


func device_list() -> Array[NetDevice]:
	var out: Array[NetDevice] = []
	for id: String in device_order:
		out.append(devices[id])
	return out


## Equipo que tiene esa IP, o null. Lo usa el ping de las consolas.
func device_by_ip(ip: String) -> NetDevice:
	for device: NetDevice in device_list():
		if device.ip == ip:
			return device
	return null


func router() -> NetDevice:
	for device: NetDevice in device_list():
		if device.kind == NetDevice.Kind.ROUTER:
			return device
	return null


# --- Cables -------------------------------------------------------------------

## Intenta conectar dos puertos. Devuelve "" si se pudo, o el motivo del rechazo.
func connect_ports(a_id: String, a_port: int, b_id: String, b_port: int, cable: String) -> String:
	if a_id == b_id:
		return "No puedes conectar un equipo consigo mismo."
	if not devices.has(a_id) or not devices.has(b_id):
		return "Equipo desconocido."
	if port_in_use(a_id, a_port) or port_in_use(b_id, b_port):
		return "Ese puerto ya esta ocupado."

	var link: NetLink = NetLink.new()
	link.a_id = a_id
	link.a_port = a_port
	link.b_id = b_id
	link.b_port = b_port
	link.cable = cable
	links.append(link)
	validate()
	changed.emit()
	return ""


func port_in_use(device_id: String, port: int) -> bool:
	for link: NetLink in links:
		if link.uses(device_id, port):
			return true
	return false


func remove_link(link: NetLink) -> void:
	links.erase(link)
	validate()
	changed.emit()


func link_between(a_id: String, b_id: String) -> NetLink:
	for link: NetLink in links:
		if (link.a_id == a_id and link.b_id == b_id) or (link.a_id == b_id and link.b_id == a_id):
			return link
	return null


# --- Configuración ------------------------------------------------------------

func set_config(device_id: String, ip: String, mask: String, gateway: String) -> void:
	var device: NetDevice = self.device(device_id)
	if device == null:
		return
	device.ip = ip.strip_edges()
	device.mask = mask.strip_edges()
	device.gateway = gateway.strip_edges()
	validate()
	config_changed.emit(device_id)
	changed.emit()


func set_interface_up(device_id: String, up: bool) -> void:
	var device: NetDevice = self.device(device_id)
	if device == null:
		return
	device.interface_up = up
	validate()
	changed.emit()


# --- Reglas -------------------------------------------------------------------

## Revisa todos los enlaces: primero el cable, luego la configuración IP.
func validate() -> void:
	var duplicated: Dictionary = _duplicated_ips()
	for link: NetLink in links:
		var a: NetDevice = device(link.a_id)
		var b: NetDevice = device(link.b_id)
		link.ok = true
		link.reason = ""
		if a == null or b == null:
			link.ok = false
			link.reason = "Equipo desconocido."
			continue

		var cable_problem: String = _cable_problem(a, b, link.cable)
		if not cable_problem.is_empty():
			link.ok = false
			link.reason = cable_problem
			continue

		var config_problem: String = _config_problem(a, b, duplicated)
		if not config_problem.is_empty():
			link.ok = false
			link.reason = config_problem
			continue

		var vlan_problem: String = _vlan_problem(link, a, b)
		if not vlan_problem.is_empty():
			link.ok = false
			link.reason = vlan_problem


## El cable recto va entre equipos distintos; el cruzado entre iguales (y de
## PC a router); la fibra es para el enlace entre router y switch.
func _cable_problem(a: NetDevice, b: NetDevice, cable: String) -> String:
	var a_switch: bool = a.kind == NetDevice.Kind.SWITCH
	var b_switch: bool = b.kind == NetDevice.Kind.SWITCH
	var one_switch: bool = a_switch != b_switch
	var has_router: bool = a.kind == NetDevice.Kind.ROUTER or b.kind == NetDevice.Kind.ROUTER

	match cable:
		CABLE_STRAIGHT:
			if one_switch:
				return ""
			return "Cable equivocado: entre estos dos va cruzado."
		CABLE_CROSSOVER:
			if not one_switch:
				return ""
			return "Cable equivocado: a un switch va cable recto."
		CABLE_FIBER:
			if (a_switch and b_switch) or (one_switch and has_router):
				return ""
			return "La fibra es solo para el enlace de switch a router."
	return "Cable desconocido."


## Un equipo enchufado a un puerto de switch que está en otra VLAN queda
## aislado, aunque el cable y las IPs estén bien.
func _vlan_problem(link: NetLink, a: NetDevice, b: NetDevice) -> String:
	for pair: Array in [[a, b, link.a_port, link.b_port], [b, a, link.b_port, link.a_port]]:
		var switch: NetDevice = pair[0]
		var other: NetDevice = pair[1]
		if switch.kind != NetDevice.Kind.SWITCH or other.kind == NetDevice.Kind.SWITCH:
			continue
		var port_vlan: int = switch.vlan_of_port(int(pair[2]))
		if port_vlan != other.vlan:
			return "El puerto %d del switch esta en la VLAN %d y %s en la %d" % [
				int(pair[2]) + 1, port_vlan, other.label, other.vlan]
	return ""


## Problemas de IP que hacen que el enlace no sirva, con el motivo a la vista.
func _config_problem(a: NetDevice, b: NetDevice, duplicated: Dictionary) -> String:
	var gateway_device: NetDevice = router()
	for device: NetDevice in [a, b]:
		if device.kind == NetDevice.Kind.ROUTER and not device.interface_up:
			return "La interfaz g0/0 del router esta apagada."
		if device.ip.is_empty():
			continue
		if duplicated.has(device.ip):
			return "IP repetida en la red: %s" % device.ip
		if not device.mask.is_empty() and not _is_valid_mask(device.mask):
			return "Mascara invalida en %s: %s" % [device.label, device.mask]
		if not device.is_configurable() or gateway_device == null or gateway_device.ip.is_empty():
			continue
		if not device.gateway.is_empty() and device.gateway != gateway_device.ip:
			return "La puerta de %s no es la del router (%s)" % [device.label, gateway_device.ip]
		if not device.mask.is_empty() and not _same_subnet(device.ip, gateway_device.ip, device.mask):
			return "%s esta fuera de la subred del router" % device.label
	return ""


## IPs que aparecen en más de un equipo.
func _duplicated_ips() -> Dictionary:
	var seen: Dictionary = {}
	var repeated: Dictionary = {}
	for device: NetDevice in device_list():
		if device.ip.is_empty():
			continue
		if seen.has(device.ip):
			repeated[device.ip] = true
		seen[device.ip] = true
	return repeated


static func _is_valid_mask(mask: String) -> bool:
	if not CampusNetwork.looks_like_ip(mask):
		return false
	# Una máscara válida es unos seguidos de ceros: 11111111111111110000...
	var bits: int = 0
	for part: String in mask.split("."):
		bits = (bits << 8) | part.to_int()
	if bits == 0:
		return false
	var inverted: int = (~bits) & 0xFFFFFFFF
	return (inverted & (inverted + 1)) == 0


static func _same_subnet(ip_a: String, ip_b: String, mask: String) -> bool:
	if not CampusNetwork.looks_like_ip(ip_a) or not CampusNetwork.looks_like_ip(ip_b):
		return false
	if not _is_valid_mask(mask):
		return false
	return _to_int(ip_a) & _to_int(mask) == _to_int(ip_b) & _to_int(mask)


static func _to_int(ip: String) -> int:
	var value: int = 0
	for part: String in ip.split("."):
		value = (value << 8) | part.to_int()
	return value


# --- Alcance ------------------------------------------------------------------

## Busca camino por cables que funcionen. Devuelve ok, el motivo si falla y
## la ruta de equipos, que es la que recorre el sobre en modo Simulación.
func reach(from_id: String, to_id: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": "", "path": PackedStringArray()}
	var from_device: NetDevice = device(from_id)
	var to_device: NetDevice = device(to_id)
	if from_device == null or to_device == null:
		result["reason"] = "Equipo desconocido."
		return result
	if from_device.ip.is_empty():
		result["reason"] = "Este equipo no tiene IP configurada."
		return result
	if to_device.ip.is_empty():
		result["reason"] = "El destino no tiene IP configurada."
		return result

	var path: PackedStringArray = _shortest_path(from_id, to_id)
	if path.is_empty():
		result["reason"] = "No hay camino: revisa los cables."
		return result

	if not from_device.mask.is_empty() and not _same_subnet(from_device.ip, to_device.ip, from_device.mask):
		var gateway_device: NetDevice = router()
		if gateway_device == null or from_device.gateway != gateway_device.ip:
			result["reason"] = "Hace falta una puerta de enlace valida."
			return result

	result["ok"] = true
	result["path"] = path
	return result


## Camino más corto entre dos equipos, pasando solo por enlaces sanos.
func _shortest_path(from_id: String, to_id: String) -> PackedStringArray:
	var previous: Dictionary = {from_id: ""}
	var queue: PackedStringArray = PackedStringArray([from_id])
	while not queue.is_empty():
		var current: String = queue[0]
		queue.remove_at(0)
		if current == to_id:
			return _rebuild_path(previous, to_id)
		for link: NetLink in links:
			if not link.ok or not link.touches(current):
				continue
			var next_id: String = link.other_end(current)
			if previous.has(next_id):
				continue
			previous[next_id] = current
			queue.append(next_id)
	return PackedStringArray()


func _rebuild_path(previous: Dictionary, to_id: String) -> PackedStringArray:
	var reversed_path: PackedStringArray = PackedStringArray()
	var step: String = to_id
	while not step.is_empty():
		reversed_path.append(step)
		step = previous[step]
	var path: PackedStringArray = PackedStringArray()
	for i: int in range(reversed_path.size() - 1, -1, -1):
		path.append(reversed_path[i])
	return path

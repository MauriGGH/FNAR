class_name CampusNetwork
extends RefCounted

## Datos de la red del campus que usa la consola de la PC. Son inventados pero
## consistentes: la coordinación está en el segmento 10, los servidores en el 1
## y el laboratorio en el 30.

const HOSTNAME: String = "COORD-GUARDIA"
const LOCAL_IP: String = "192.168.10.10"
const SUBNET_MASK: String = "255.255.255.0"
const GATEWAY: String = "192.168.10.1"
const DNS_PRIMARY: String = "192.168.1.5"
const DNS_SECONDARY: String = "8.8.8.8"
const MAC: String = "A4-5E-60-C1-07-2B"
const CORE_ROUTER: String = "10.0.0.1"

## Equipos que la consola conoce por nombre: ip -> nombre.
const HOSTS: Dictionary = {
	"192.168.10.1": "GW-COORDINACION",
	"192.168.10.10": "COORD-GUARDIA",
	"192.168.10.11": "RECEPCION-01",
	"192.168.10.12": "CUBICULO-02",
	"192.168.1.5": "SRV-DNS",
	"192.168.1.10": "SRV-CORREO",
	"192.168.1.20": "SRV-RESPALDOS",
	"192.168.20.21": "CAFETERIA-01",
	"192.168.30.11": "LAB-A-01",
	"192.168.30.12": "LAB-A-02",
	"192.168.30.13": "LAB-A-03",
	"192.168.30.14": "LAB-B-01",
	"192.168.30.15": "LAB-B-02",
	"192.168.30.16": "LAB-B-03",
}

## Equipos del laboratorio, de donde sale el que no responde cada noche.
const LAB_HOSTS: Array[String] = [
	"192.168.30.11", "192.168.30.12", "192.168.30.13",
	"192.168.30.14", "192.168.30.15", "192.168.30.16",
]

## Servicios del campus: nombre -> cómo se llama en el reporte.
## Nombre corto con el que los responde la consola. Cortos a propósito: las
## líneas de la consola no hacen salto y se cortarían pasando los 61 caracteres.
const SERVICES: Dictionary = {
	"correo": "servicio de correo",
	"dhcp": "servicio DHCP",
	"impresion": "cola de impresion",
	"respaldos": "servicio de respaldos",
}

## Servicios que arrancan la noche caídos, con su código de error.
const BROKEN_SERVICES: Dictionary = {
	"correo": 1067,
}

## Servicios que arrancan la noche andando.
const RUNNING_SERVICES: Array[String] = ["dhcp", "impresion", "respaldos"]

# Estados de servicio, con el número que enseña sc query.
const STATE_STOPPED: String = "STOPPED"
const STATE_RUNNING: String = "RUNNING"
const STATE_CODES: Dictionary = {
	STATE_STOPPED: 1,
	STATE_RUNNING: 4,
}


static func host_name(ip: String) -> String:
	return HOSTS.get(ip, "")


static func is_known_host(ip: String) -> bool:
	return HOSTS.has(ip)


## Saltos de tracert hasta una ip: dentro del segmento de la oficina es
## directo; a cualquier otro lado pasa por la puerta de enlace y el núcleo.
static func route_to(ip: String) -> PackedStringArray:
	if ip.begins_with("192.168.10."):
		return PackedStringArray([ip])
	return PackedStringArray([GATEWAY, CORE_ROUTER, ip])


## Revisa que el texto tenga forma de IPv4, para contestar como una consola.
static func looks_like_ip(text: String) -> bool:
	var parts: PackedStringArray = text.split(".")
	if parts.size() != 4:
		return false
	for part: String in parts:
		if part.is_empty() or not part.is_valid_int():
			return false
		var value: int = part.to_int()
		if value < 0 or value > 255:
			return false
	return true

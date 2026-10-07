class_name NetDevice
extends RefCounted

## Un equipo del simulador de topologías.

enum Kind { ROUTER, SWITCH, PC, SERVER }

var id: String = ""
var kind: Kind = Kind.PC
var label: String = ""
## Posición en el lienzo, normalizada de 0 a 1, para que se adapte al tamaño.
var position: Vector2 = Vector2(0.5, 0.5)
var port_count: int = 1
## Cuántos de sus puertos se dibujan en el borde de arriba; el resto va abajo.
## El switch lleva 1 arriba (el enlace al router) y los demás abajo (las PCs),
## así ningún cable cruza por encima de un equipo.
var top_ports: int = 1

# Configuración de red. En el router es la de su interfaz g0/0.
var ip: String = ""
var mask: String = ""
var gateway: String = ""
## En el router, si la interfaz está levantada. Los demás siempre andan.
var interface_up: bool = true

## La VLAN a la que pertenece este equipo. 1 es la de siempre.
var vlan: int = 1
## En un switch, la VLAN de cada puerto: número de puerto -> VLAN. Los puertos
## que no estén aquí se quedan en la VLAN 1.
var port_vlans: Dictionary = {}
## En un router, las reservas de DHCP: nombre del pool -> {"ip", "mask"}.
var reservations: Dictionary = {}


## La VLAN de un puerto de switch.
func vlan_of_port(port: int) -> int:
	return int(port_vlans.get(port, 1))


func is_configurable() -> bool:
	return kind == Kind.PC or kind == Kind.SERVER


func kind_name() -> String:
	match kind:
		Kind.ROUTER:
			return "router"
		Kind.SWITCH:
			return "switch"
		Kind.SERVER:
			return "servidor"
		_:
			return "PC"

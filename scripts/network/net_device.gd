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

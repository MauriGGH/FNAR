class_name Tasks
extends RefCounted

## Banco de tareas del juego y lo que pagan. Cada noche se sacan unas cuantas
## al azar de aquí; cuántas, lo dice TASKS_PER_NIGHT.

const TYPE_MAIL_SERVICE: String = "mail_service"
const TYPE_LAB_DIAGNOSTIC: String = "lab_diagnostic"
const TYPE_CONNECT_LAB: String = "connect_lab"
const TYPE_NET_IP_CONFIG: String = "net_ip_config"
const TYPE_CONNECTIVITY: String = "connectivity"
const TYPE_ROUTER_INTERFACE: String = "router_interface"

# En qué app del escritorio se hace cada tarea.
const APP_TERMINAL: String = "Terminal"
const APP_NETWORK: String = "Simulador de red"
const APP_SERVER_ROOM: String = "Sala de servidores"

## Lo que le pagan al guardia por cada tarea terminada.
const PAYMENT_PER_TASK: int = 75

## Cuántas tareas pide cada noche, según la tabla del documento de diseño.
const TASKS_PER_NIGHT: Dictionary = {
	1: 2, 2: 3, 3: 3, 4: 4, 5: 4, 6: 5,
}

## Panel de cada tipo de tarea.
const SCENES: Dictionary = {
	TYPE_MAIL_SERVICE: "res://scenes/tasks/mail_service_task.tscn",
	TYPE_LAB_DIAGNOSTIC: "res://scenes/tasks/lab_diagnostic_task.tscn",
	TYPE_CONNECT_LAB: "res://scenes/tasks/connect_lab_task.tscn",
	TYPE_NET_IP_CONFIG: "res://scenes/tasks/net_ip_config_task.tscn",
	TYPE_CONNECTIVITY: "res://scenes/tasks/connectivity_task.tscn",
	TYPE_ROUTER_INTERFACE: "res://scenes/tasks/router_interface_task.tscn",
}

## El banco. Todas las tareas de aquí se pueden terminar; las del patch panel
## de la sala de servidores entran cuando exista esa vista.
const BANK: Array[Dictionary] = [
	{
		"id": "servicio_correo",
		"title": "Reiniciar el servicio de correo",
		"description": "El correo del campus se cayo con error. Levantalo de nuevo.",
		"app": APP_TERMINAL,
		"type": TYPE_MAIL_SERVICE,
		"service": "correo",
	},
	{
		"id": "diagnostico_laboratorio",
		"title": "Diagnosticar el laboratorio",
		"description": "Un equipo del laboratorio no responde. Encuentralo y reportalo.",
		"app": APP_TERMINAL,
		"type": TYPE_LAB_DIAGNOSTIC,
	},
	{
		"id": "conectar_laboratorio",
		"title": "Conectar el laboratorio",
		"description": "Llegaron los equipos nuevos sin cablear. Armalos como el diagrama.",
		"app": APP_NETWORK,
		"type": TYPE_CONNECT_LAB,
	},
	{
		"id": "configurar_ips_lab",
		"title": "Configurar IPs del laboratorio",
		"description": "Las cuatro PCs del laboratorio quedaron sin direccion fija.",
		"app": APP_NETWORK,
		"type": TYPE_NET_IP_CONFIG,
	},
	{
		"id": "prueba_conectividad",
		"title": "Prueba de conectividad",
		"description": "Comprueba desde una PC que el servidor del laboratorio responde.",
		"app": APP_NETWORK,
		"type": TYPE_CONNECTIVITY,
	},
	{
		"id": "interfaz_router",
		"title": "Activar la interfaz del router",
		"description": "La g0/0 del router quedo apagada. Configurala por la CLI.",
		"app": APP_NETWORK,
		"type": TYPE_ROUTER_INTERFACE,
		"min_night": 4,
	},
]


## Saca al azar las tareas de una noche. Se llama una sola vez por noche,
## desde GameManager, para que la lista no cambie a media partida.
static func pick_for_night(night: int) -> Array:
	var count: int = TASKS_PER_NIGHT.get(night, 2)
	var pool: Array = []
	for task: Dictionary in BANK:
		# Las que piden noche minima no salen antes de tiempo.
		if night >= int(task.get("min_night", 1)):
			pool.append(task)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


static func scene_for_type(type: String) -> String:
	return SCENES.get(type, "")

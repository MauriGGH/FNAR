class_name Tasks
extends RefCounted

## Tareas que pide cada noche y lo que pagan. Por ahora el único minijuego que
## existe es el de las IPs; los demás llegan en el hito 7.

const TYPE_IP_CONFIG: String = "ip_config"

## Lo que le pagan al guardia por cada tarea terminada.
const PAYMENT_PER_TASK: int = 75

## Escena de cada tipo de tarea.
const SCENES: Dictionary = {
	TYPE_IP_CONFIG: "res://scenes/tasks/ip_config_task.tscn",
}

const NIGHT_1: Array[Dictionary] = [
	{
		"id": "ips_planta_alta",
		"title": "Configurar IPs (planta alta)",
		"type": TYPE_IP_CONFIG,
		"computers": ["RECEPCION-01", "CUBICULO-02", "CUBICULO-03", "SALON-B-01"],
		"ips": ["192.168.10.11", "192.168.10.12", "192.168.10.13", "192.168.10.14"],
	},
	{
		"id": "ips_planta_baja",
		"title": "Configurar IPs (planta baja)",
		"type": TYPE_IP_CONFIG,
		"computers": ["CAFETERIA-01", "CAFETERIA-02", "CASETA-01", "SERVIDORES-01"],
		"ips": ["192.168.20.21", "192.168.20.22", "192.168.20.23", "192.168.20.24"],
	},
]

const BY_NIGHT: Dictionary = {
	1: NIGHT_1,
}


## Tareas de una noche. Las noches que todavía no están definidas usan las de la 1.
static func tasks_for_night(night: int) -> Array:
	return BY_NIGHT.get(night, NIGHT_1)


static func scene_for_type(type: String) -> String:
	return SCENES.get(type, "")

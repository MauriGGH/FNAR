class_name Rooms
extends RefCounted

## Grafo de habitaciones del edificio. Cada id guarda su nombre para mostrar,
## el número de cámara que lo vigila (0 = sin cámara) y sus conexiones.
## Las conexiones son de ida y vuelta: si A lista a B, B tiene que listar a A.
## No es autoload: se usa como Rooms.display_name("oficina") gracias al class_name.

const NO_CAMERA: int = 0
## Cuántas cámaras hay en total, de la 1 a la 13.
const CAMERA_COUNT: int = 13

const ROOMS: Dictionary = {
	# --- Oficina y recepción ------------------------------------------------
	"oficina": {
		"display_name": "Oficina",
		"camera": NO_CAMERA,
		# Al frente, el cristal y la puerta de entrada: las dos dan al pasillo sur.
		"links": ["recepcion", "pasillo_sur"],
	},
	"recepcion": {
		"display_name": "Recepción",
		"camera": NO_CAMERA,
		"links": ["pasillo_sur", "oficina", "sala_servidores", "cubiculo_2", "cubiculo_3", "escalera_techo"],
	},

	# --- Sala de servidores y cubículos ------------------------------------
	"sala_servidores": {
		"display_name": "Sala de servidores",
		"camera": NO_CAMERA,
		"links": ["recepcion"],
	},
	"cubiculo_2": {
		"display_name": "Cubículo 2",
		"camera": 3,
		"links": ["recepcion"],
	},
	"cubiculo_3": {
		"display_name": "Cubículo 3",
		"camera": 4,
		"links": ["recepcion"],
	},

	# --- Pasillo ------------------------------------------------------------
	"pasillo_norte": {
		"display_name": "Pasillo norte",
		"camera": 1,
		"links": ["pasillo_sur", "salon_1", "salon_2", "salon_b", "salon_d", "sala_juntas"],
	},
	"sala_juntas": {
		"display_name": "Sala de juntas",
		"camera": 13,
		"links": ["pasillo_norte"],
	},
	"pasillo_sur": {
		"display_name": "Pasillo sur",
		"camera": 2,
		"links": [
			"pasillo_norte", "oficina", "recepcion", "salon_2", "salon_3",
			"salon_d", "salon_e", "banos", "escalera_pb",
		],
	},

	# --- Salones del lado izquierdo ----------------------------------------
	"salon_1": {
		"display_name": "Salón 1",
		"camera": NO_CAMERA,
		"links": ["pasillo_norte"],
	},
	"salon_2": {
		"display_name": "Salón 2",
		"camera": NO_CAMERA,
		# Está a la mitad del pasillo, así que toca las dos mitades.
		"links": ["pasillo_norte", "pasillo_sur"],
	},
	"salon_3": {
		"display_name": "Salón 3",
		"camera": NO_CAMERA,
		"links": ["pasillo_sur"],
	},

	# --- Salones del lado derecho ------------------------------------------
	"salon_b": {
		"display_name": "Salón B (sala de servicio)",
		"camera": 10,
		"links": ["pasillo_norte"],
	},
	"salon_d": {
		"display_name": "Salón D",
		"camera": NO_CAMERA,
		"links": ["pasillo_norte", "pasillo_sur"],
	},
	"salon_e": {
		"display_name": "Salón E",
		"camera": 11,
		"links": ["pasillo_sur"],
	},

	# --- Baños --------------------------------------------------------------
	"banos": {
		"display_name": "Baños",
		"camera": 12,
		"links": ["pasillo_sur"],
	},

	# --- Techo --------------------------------------------------------------
	"escalera_techo": {
		"display_name": "Escalera al techo",
		"camera": 5,
		"links": ["recepcion", "techo"],
	},
	"techo": {
		"display_name": "Techo (pararrayos)",
		"camera": 6,
		"links": ["escalera_techo"],
	},

	# --- Planta baja --------------------------------------------------------
	"escalera_pb": {
		"display_name": "Escalera a planta baja",
		"camera": 7,
		"links": ["pasillo_sur", "cafeteria", "estacionamiento"],
	},
	"cafeteria": {
		"display_name": "Cafetería sur",
		"camera": 9,
		"links": ["escalera_pb", "estacionamiento"],
	},
	"estacionamiento": {
		"display_name": "Estacionamiento",
		"camera": 8,
		"links": ["cafeteria", "escalera_pb"],
	},
}


static func has_room(id: String) -> bool:
	return ROOMS.has(id)


static func display_name(id: String) -> String:
	return ROOMS[id]["display_name"] if has_room(id) else "???"


## Número de cámara que vigila la habitación, o NO_CAMERA si es punto ciego.
static func camera_of(id: String) -> int:
	return ROOMS[id]["camera"] if has_room(id) else NO_CAMERA


static func has_camera(id: String) -> bool:
	return camera_of(id) != NO_CAMERA


## Habitación que vigila una cámara, o cadena vacía si ese número no existe.
static func room_of_camera(camera: int) -> String:
	for id: String in ROOMS:
		if ROOMS[id]["camera"] == camera:
			return id
	return ""


static func links_of(id: String) -> PackedStringArray:
	return PackedStringArray(ROOMS[id]["links"]) if has_room(id) else PackedStringArray()


static func are_linked(from_room: String, to_room: String) -> bool:
	return to_room in links_of(from_room)


## Números de cámara ordenados, del 1 al 12.
static func camera_numbers() -> PackedInt32Array:
	var numbers: PackedInt32Array = PackedInt32Array()
	for id: String in ROOMS:
		var camera: int = ROOMS[id]["camera"]
		if camera != NO_CAMERA:
			numbers.append(camera)
	numbers.sort()
	return numbers

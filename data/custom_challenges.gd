class_name CustomChallenges
extends RefCounted

## Los retos de la Custom Night: combinaciones ya puestas, cada una con su
## gracia. Un botón deja los niveles como pide el reto y, si se gana, queda
## marcado con una palomita en la pantalla de Custom Night.
##
## Los niveles que no aparecen en "levels" van a 0.

## La marca de los que ya se ganaron.
const DONE_MARK: String = "✓"

const ACADEMY: String = "junta_academia"
const NEWCOMERS: String = "puros_nuevos"
const AFTER_HOURS: String = "fuera_de_horario"
const BLACKOUT: String = "apagon"
const ALL_MAX: String = "todos_en_20"

## Cada reto: su nombre en pantalla, una línea de qué va, los niveles que pone y
## con cuánta energía empieza la noche (si no dice nada, con el 100 %).
const LIST: Array[Dictionary] = [
	{
		"id": "junta_academia",
		"name": "Junta de academia",
		"line": "Los tres de la sala de juntas, a la vez.",
		"levels": {"mamador": 20, "juan_exe": 20, "armando": 20},
	},
	{
		"id": "puros_nuevos",
		"name": "Puros nuevos",
		"line": "Juan.exe y Armando, sin nadie que te distraiga.",
		"levels": {"juan_exe": 20, "armando": 20},
	},
	{
		"id": "fuera_de_horario",
		"name": "Fuera de horario",
		"line": "Barcosa corriendo y Rochis levantándose.",
		"levels": {"barcosa": 20, "rochis": 20},
	},
	{
		"id": "apagon",
		"name": "Apagón",
		"line": "El Mago en 20 y media batería para toda la noche.",
		"levels": {"audel": 20},
		"start_power": 50.0,
	},
	{
		"id": "todos_en_20",
		"name": "Todos en 20",
		"line": "Los ocho al máximo. Suerte.",
		"levels": {
			"barcosa": 20, "mamador": 20, "urena": 20, "rochis": 20,
			"audel": 20, "juan_exe": 20, "armando": 20, "come_trabas": 20,
		},
	},
]


static func count() -> int:
	return LIST.size()


static func challenge(challenge_id: String) -> Dictionary:
	for entry: Dictionary in LIST:
		if str(entry["id"]) == challenge_id:
			return entry
	return {}


static func display_name(challenge_id: String) -> String:
	return str(challenge(challenge_id).get("name", challenge_id))


static func line(challenge_id: String) -> String:
	return str(challenge(challenge_id).get("line", ""))


## Los ocho niveles del reto, con 0 en los que no menciona.
static func levels_of(challenge_id: String) -> Dictionary:
	var wanted: Dictionary = challenge(challenge_id).get("levels", {}) as Dictionary
	var levels: Dictionary = {}
	for key: String in Nights.ALL_KEYS:
		levels[key] = int(wanted.get(key, 0))
	return levels


## Con cuánta energía arranca la noche de ese reto.
static func start_power(challenge_id: String) -> float:
	return float(challenge(challenge_id).get("start_power", NightConfig.MAX_POWER))

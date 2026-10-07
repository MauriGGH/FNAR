class_name Sounds
extends RefCounted

## El catálogo de sonidos: un id por sonido, el archivo que espera en
## assets/audio/, el bus por el que sale y su volumen. Todo el juego pide sus
## sonidos por id a través del AudioManager; nadie carga un archivo a mano.
##
## Mientras el archivo de verdad no exista, el AudioManager usa el provisional
## de ToneBuilder y lo avisa una sola vez en consola. Para meter un sonido real
## basta con dejar el archivo con ese nombre en assets/audio/: no hay que tocar
## código.

const PATH: String = "res://assets/audio/%s"

# Los buses. Tienen que llamarse igual que en assets/audio/buses.tres.
const BUS_MASTER: String = "Master"
const BUS_AMBIENCE: String = "Ambiente"
const BUS_EFFECTS: String = "Efectos"
const BUS_VOICES: String = "Voces"
const BUS_MUSIC: String = "Música"

## Los buses que el jugador puede subir y bajar, en el orden del menú.
const MIXER_BUSES: Array[String] = ["Master", "Música", "Efectos", "Ambiente", "Voces"]

# --- Ids ---------------------------------------------------------------------
const MUSIC_BOX: String = "cajita_musical"
## La misma melodía, pero para el apagón: suena una sola vez y más fuerte, porque
## en la oscuridad es lo único que hay. Usa el mismo archivo que la de la botarga.
const MUSIC_BOX_BLACKOUT: String = "cajita_musical_apagon"
const TICKET: String = "ticket_nuevo"
const SCREAM: String = "grito"
const BUSY_TONE: String = "tono_ocupado"
const ALARM: String = "despertador"
const SCHOOL_BELL: String = "campana_escuela"
const FOOTSTEPS: String = "pasos_acercandose"
const LOW_HIT: String = "golpe_grave"
## Cuando uno de los del cristal se va con el cuarto destello.
const GLASS_REPEL: String = "se_aleja"

## El catálogo. Por sonido: "file" (nombre dentro de assets/audio/, sin ruta),
## "bus", "volume_db" y "generator" (el nombre de la función de ToneBuilder que
## lo arma si el archivo falta; vacío si no hay provisional).
const CATALOG: Dictionary = {
	"cajita_musical": {
		"file": "cajita_musical.ogg", "bus": "Música",
		"volume_db": -16.0, "generator": "music_box",
	},
	"cajita_musical_apagon": {
		"file": "cajita_musical.ogg", "bus": "Música",
		"volume_db": -4.0, "generator": "music_box",
	},
	"ticket_nuevo": {
		"file": "ticket_nuevo.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "ticket_chime",
	},
	"grito": {
		"file": "grito.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "scream",
	},
	"tono_ocupado": {
		"file": "tono_ocupado.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "busy_tone",
	},
	"despertador": {
		"file": "despertador.ogg", "bus": "Efectos",
		"volume_db": -8.0, "generator": "alarm",
	},
	"campana_escuela": {
		"file": "campana_escuela.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "school_bell",
	},
	"pasos_acercandose": {
		"file": "pasos_acercandose.ogg", "bus": "Efectos",
		"volume_db": -2.0, "generator": "footsteps",
	},
	"se_aleja": {
		"file": "se_aleja.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "glass_repel",
	},
	"golpe_grave": {
		"file": "golpe_grave.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "low_hit",
	},
}

## Los que suenan en bucle: el AudioManager les marca el bucle al cargarlos.
const LOOPING: Array[String] = ["cajita_musical", "despertador"]


static func ids() -> Array:
	return CATALOG.keys()


static func entry(id: String) -> Dictionary:
	return CATALOG.get(id, {}) as Dictionary


static func file_name(id: String) -> String:
	return str(entry(id).get("file", ""))


## La ruta donde se espera el archivo de verdad.
static func file_path(id: String) -> String:
	var name: String = file_name(id)
	return "" if name.is_empty() else PATH % name


static func bus_of(id: String) -> String:
	return str(entry(id).get("bus", BUS_EFFECTS))


static func volume_db(id: String) -> float:
	return float(entry(id).get("volume_db", 0.0))


static func generator_of(id: String) -> String:
	return str(entry(id).get("generator", ""))


static func is_looping(id: String) -> bool:
	return id in LOOPING

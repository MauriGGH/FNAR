class_name Extras
extends RefCounted

## El cargador de los expedientes de Extras. Por ahora solo encuentra la hoja
## de referencia de cada personaje; la ficha (nombre, rol, descripción) y el
## menú llegan con el hito 7.
##
## Los ids son los mismos que usa el código para las imágenes de cámara
## (image_slug()), así que un profe puede pedir su propio expediente sin que
## nadie tenga que mantener dos listas.

const DOSSIER_PATH: String = "res://assets/art/extras/expediente_%s"
## Las imágenes de jumpscare, que la galería de Extras también usa.
const JUMPSCARE_PATH: String = "res://assets/art/jumpscares/jumpscare_%s"

## El id del jumpscare de cada personaje. Casi siempre es el mismo que el del
## expediente; la botarga es la excepción, su imagen va sin guion bajo.
const JUMPSCARE_IDS: Dictionary = {
	"come_trabas": "cometrabas",
}

## Todos los ids con expediente, en el orden en que irán en el menú.
const DOSSIER_IDS: Array[String] = [
	"barcosa", "mamador", "urena", "rochis", "audel", "juan", "armando", "come_trabas",
]


## La hoja de referencia de un personaje, o null si no está. Acepta png, jpg
## y jpeg, como todas las imágenes del juego.
static func dossier_texture(character_id: String) -> Texture2D:
	return GameAssets.load_texture(DOSSIER_PATH % character_id)


static func has_dossier(character_id: String) -> bool:
	return GameAssets.has_texture(DOSSIER_PATH % character_id)


## La ruta real del expediente, con su extensión, o cadena vacía.
static func dossier_path(character_id: String) -> String:
	return GameAssets.find_texture_path(DOSSIER_PATH % character_id)


## La imagen de jumpscare de un personaje, o null si no la tiene. Mamador no
## salta: la suya es la de los militares.
static func jumpscare_texture(character_id: String) -> Texture2D:
	return GameAssets.load_texture(JUMPSCARE_PATH % jumpscare_id(character_id))


static func jumpscare_id(character_id: String) -> String:
	if character_id == "mamador":
		return "mamador_militares"
	return str(JUMPSCARE_IDS.get(character_id, character_id))

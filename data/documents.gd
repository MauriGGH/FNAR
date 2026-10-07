class_name Documents
extends RefCounted

## Los documentos que se le entregan al guardia: los recibos de pago de las
## últimas dos noches y la carta de despido del final. Son imágenes completas;
## lo único que pone el código encima es el nombre del jugador, escrito a
## máquina sobre la línea que trae cada hoja.

const PATH: String = "res://assets/art/extras/documentos/%s"

const RECEIPT_NIGHT_5: String = "recibo_noche5"
const RECEIPT_NIGHT_6: String = "recibo_noche6"
const DISMISSAL: String = "carta_despido"

## Todos, en el orden en que los ve el jugador.
const IDS: Array[String] = ["recibo_noche5", "recibo_noche6", "carta_despido"]

## La tinta de la máquina de escribir y el tamaño del nombre medido a 1080p: en
## pantallas de otro alto se escala solo.
const INK: Color = Color(0.137, 0.118, 0.118)
const NAME_SIZE_AT_1080: float = 26.0
const REFERENCE_HEIGHT: float = 1080.0

## Dónde va el nombre en cada hoja: posición normalizada de la esquina superior
## izquierda del texto, y lo chueco que quedó al escribirlo, en grados. Son
## medidas tomadas sobre las imágenes, no se adivinan.
const NAME_SPOTS: Dictionary = {
	"recibo_noche5": {"at": Vector2(0.387, 0.230), "tilt": 2.0},
	"recibo_noche6": {"at": Vector2(0.387, 0.230), "tilt": 2.0},
	"carta_despido": {"at": Vector2(0.298, 0.270), "tilt": -1.5},
}

## Qué documento toca al pasar una noche. Solo las dos últimas dan recibo; la
## carta de despido no sale de aquí, se gana pasando una Custom Night.
const RECEIPTS_BY_NIGHT: Dictionary = {
	5: "recibo_noche5",
	6: "recibo_noche6",
}


static func texture(document_id: String) -> Texture2D:
	return GameAssets.load_texture(PATH % document_id)


static func has_document(document_id: String) -> bool:
	return GameAssets.has_texture(PATH % document_id)


## El recibo de esa noche, o cadena vacía si esa noche no lleva documento.
static func for_cleared_night(night: int) -> String:
	return str(RECEIPTS_BY_NIGHT.get(night, ""))


## El nombre que se enseña de cada hoja en la pestaña de Extras.
const TITLES: Dictionary = {
	"recibo_noche5": "Recibo de pago · noche 5",
	"recibo_noche6": "Recibo de pago · noche 6",
	"carta_despido": "Carta de despido",
}

## Cómo se consigue cada hoja, para la ficha de Extras.
const SOURCES: Dictionary = {
	"recibo_noche5": "Al pasar la noche 5",
	"recibo_noche6": "Al pasar la noche 6",
	"carta_despido": "Al ganar una Custom Night",
}


static func title(document_id: String) -> String:
	return str(TITLES.get(document_id, document_id))


static func source(document_id: String) -> String:
	return str(SOURCES.get(document_id, ""))


static func name_position(document_id: String) -> Vector2:
	var spot: Dictionary = NAME_SPOTS.get(document_id, {}) as Dictionary
	return spot.get("at", Vector2(0.3, 0.25)) as Vector2


## La inclinación en radianes, que es lo que pide draw_set_transform.
static func name_tilt(document_id: String) -> float:
	var spot: Dictionary = NAME_SPOTS.get(document_id, {}) as Dictionary
	return deg_to_rad(float(spot.get("tilt", 0.0)))


## El tamaño del nombre para una pantalla de este alto.
static func name_font_size(view_height: float) -> int:
	return maxi(8, roundi(NAME_SIZE_AT_1080 * view_height / REFERENCE_HEIGHT))

class_name Hallucinations
extends RefCounted

## Las alucinaciones: un solo cuadro que aparece y se va, con un golpe grave.
## No hacen nada, no matan y no se pueden contestar; solo están para que el
## jugador dude de lo que vio.
##
## Empiezan en la noche 2, son raras, se hacen más seguidas en las noches altas
## y nunca sale una antes de 90 s desde la anterior.

## Desde qué noche pueden salir.
const FIRST_NIGHT: int = 2
## Cada cuánto se tira el dado, y la probabilidad de cada tirada por noche.
const ROLL_INTERVAL: float = 10.0
const CHANCE_BY_NIGHT: Dictionary = {
	2: 0.04,
	3: 0.07,
	4: 0.11,
	5: 0.16,
	6: 0.22,
}
## Lo mínimo que pasa entre dos alucinaciones, pase lo que pase.
const MIN_GAP: float = 90.0
## Lo que se queda el cuadro en pantalla.
const MIN_TIME: float = 0.1
const MAX_TIME: float = 0.2

# --- Los cuatro cuadros ------------------------------------------------------
const PHOTO: String = "foto_esposa"
const IMPRESSIVE: String = "es_impresionante"
const COSTUME: String = "botarga"
const DOSSIER: String = "expediente"

const ALL: Array[String] = ["foto_esposa", "es_impresionante", "botarga", "expediente"]

## La foto de la esposa de Rochis, recortada de la capa de la CAM 3 y puesta a
## pantalla completa. El rectángulo está medido sobre `cam03_foto`, donde la
## foto cuelga entre x 0.523 y 0.595 y entre y 0.038 y 0.236.
const PHOTO_IMAGE: String = "res://assets/art/cameras/cam03_foto"
const PHOTO_REGION: Rect2 = Rect2(0.523, 0.038, 0.074, 0.198)

## El texto rojo sobre el monitor. Solo sale con la PC abierta, que es cuando se
## ve la pantalla; si está bajada, se elige otro cuadro.
const IMPRESSIVE_TEXT: String = "ES IMPRESIONANTE"
const IMPRESSIVE_COLOR: Color = Color(0.85, 0.08, 0.08)
const IMPRESSIVE_SIZE: int = 96

## La botarga sentada en la silla de la oficina: se reusa su jumpscare, muy
## oscurecido, para que se adivine la silueta en la penumbra.
const COSTUME_IMAGE: String = "res://assets/art/jumpscares/jumpscare_cometrabas"
const COSTUME_DARKEN: float = 0.62

## Un expediente cualquiera con el nombre del jugador donde va el del profe.
## El valor del campo NOMBRE empieza en x 0.072, y 0.253 y llega hasta x 0.296,
## con un alto de 0.033; son medidas sobre la hoja, que en la imagen está
## girada −2.5°. El parche tapa el nombre impreso y encima se escribe el nuevo,
## los dos girados ese mismo ángulo sobre esa esquina, para que caigan en el
## renglón y no de través.
const DOSSIER_NAME_PATCH: Rect2 = Rect2(0.072, 0.253, 0.224, 0.033)
const DOSSIER_TILT_DEGREES: float = -2.5
## El tono del papel (#d6c49e), para que el parche no se note en un vistazo de
## una décima de segundo.
const DOSSIER_PAPER: Color = Color(0.8392, 0.7686, 0.6196)
const DOSSIER_NAME_SIZE_AT_1080: float = 30.0
## La tinta de la máquina de escribir (#282019).
const DOSSIER_INK: Color = Color(0.1569, 0.1255, 0.0980)
const REFERENCE_HEIGHT: float = 1080.0


## La probabilidad de cada tirada en esa noche. 0 si todavía no hay.
static func chance_for_night(night: int) -> float:
	if night < FIRST_NIGHT:
		return 0.0
	return float(CHANCE_BY_NIGHT.get(night, CHANCE_BY_NIGHT.get(CHANCE_BY_NIGHT.keys().back(), 0.0)))


## Los cuadros que se pueden enseñar ahora mismo. El del monitor necesita la PC
## abierta, así que no siempre está.
static func available(is_pc_open: bool) -> Array[String]:
	var out: Array[String] = []
	for kind: String in ALL:
		if kind == IMPRESSIVE and not is_pc_open:
			continue
		out.append(kind)
	return out


static func pick(is_pc_open: bool) -> String:
	var options: Array[String] = available(is_pc_open)
	return "" if options.is_empty() else options[randi() % options.size()]


## El tamaño del nombre del expediente para una pantalla de este alto.
static func dossier_name_size(view_height: float) -> int:
	return maxi(10, roundi(DOSSIER_NAME_SIZE_AT_1080 * view_height / REFERENCE_HEIGHT))


## Lo girada que está la hoja, en radianes, que es lo que pide draw_set_transform.
static func dossier_tilt() -> float:
	return deg_to_rad(DOSSIER_TILT_DEGREES)

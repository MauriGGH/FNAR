class_name Urena
extends GlassStalker

## Ureña (rol Chica). Lento: sube por los baños y el salón E (o el salón sin
## cámara de al lado) hasta el cristal de la oficina. En el cristal funciona
## como todos los de GlassStalker; lo único propio es su ruta, que cambia de
## salón cada noche, y lo lento que avanza.

const STEP_BANOS: int = 0
const STEP_MIDDLE: int = 1
const STEP_PASILLO_SUR: int = 2
## El segundo paso se sortea: el salón E tiene cámara, el 3 es punto ciego.
const MIDDLE_ROOMS: Array[String] = ["salon_e", "salon_3"]

## Cada cuánto tira el dado. Es el más lento de todos.
const MOVE_INTERVAL: float = 8.0

const GAME_OVER_CAUSE: String = "Ureña"


func ai_key() -> String:
	return Nights.URENA


## El salón del medio cambia cada noche.
func build_route() -> PackedStringArray:
	return PackedStringArray(["banos", MIDDLE_ROOMS[randi() % MIDDLE_ROOMS.size()], "pasillo_sur"])


func step_interval() -> float:
	return MOVE_INTERVAL


func game_over_cause() -> String:
	return GAME_OVER_CAUSE


## Tecla 1: lo manda directo al cristal, para no esperar al dado.
func debug_key() -> Key:
	return KEY_1

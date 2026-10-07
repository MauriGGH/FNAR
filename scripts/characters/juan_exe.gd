class_name JuanExe
extends GlassStalker

## Juan.exe (rol Bonnie clásico). Profe sencillo, sin mecánica propia: sale de
## la sala de juntas, baja por el pasillo y se pega al cristal. Ahí funciona
## igual que Ureña, con los destellos de linterna. No usa la reserva del
## pasillo, así que puede coincidir con Barcosa, con Mamador y con Armando.

const ROUTE: Array[String] = ["sala_juntas", "pasillo_norte", "pasillo_sur"]
const MOVE_INTERVAL: float = 7.0
const GAME_OVER_CAUSE: String = "Juan.exe"


func ai_key() -> String:
	return Nights.JUAN_EXE


func build_route() -> PackedStringArray:
	return PackedStringArray(ROUTE)


func step_interval() -> float:
	return MOVE_INTERVAL


func game_over_cause() -> String:
	return GAME_OVER_CAUSE


## Tecla 5: lo manda directo al cristal.
func debug_key() -> Key:
	return KEY_5

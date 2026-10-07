class_name JuanExe
extends GlassStalker

## Juan.exe (rol Bonnie clásico). Profe sencillo, sin mecánica propia: sale de
## la sala de juntas, baja por el pasillo y se pega al cristal. Ahí funciona
## igual que Ureña, con los destellos de linterna. No usa la reserva del
## pasillo, así que puede coincidir con Barcosa, con Mamador y con Armando.

const ROUTE: Array[String] = ["sala_juntas", "pasillo_norte", "pasillo_sur"]
const MOVE_INTERVAL: float = 7.0
const GAME_OVER_CAUSE: String = "Juan.exe"


## Nombre corto para los archivos de imagen: cam07_juan.png y demás.
func image_slug() -> String:
	return "juan"


## Antes de salir de su lugar inicial se queda mirando fijo a la cámara.
func stalks_before_leaving() -> bool:
	return true


func ai_key() -> String:
	return Nights.JUAN_EXE


func build_route() -> PackedStringArray:
	return PackedStringArray(ROUTE)


func step_interval() -> float:
	return MOVE_INTERVAL


func game_over_cause() -> String:
	return GAME_OVER_CAUSE


## Tecla 5: lo manda directo al cristal.
func debug_action() -> String:
	return DebugKeys.JUAN_GLASS

class_name LoadingLines
extends RefCounted

## Las frases de las pantallas de carga. Son del lore y van en serio: nada de
## bromas, y nada que revele lo que se guarda para la segunda entrega.

const LINES: Array[String] = [
	"La botarga no se mueve sola. Eso dicen.",
	"El turno de noche no aparece en el organigrama.",
	"La chapa de la puerta está en el no-break. Por algo será.",
	"En la bitácora falta la hoja de esa noche.",
	"Nadie ha vuelto a pedir las llaves del cubículo 3.",
	"El pararrayos se instaló después del incidente.",
	"Las cámaras graban. Nadie revisa las grabaciones.",
	"La coordinación cierra a las nueve. El edificio no.",
	"Servicio social: cuatrocientas ochenta horas.",
	"Si oyes pasos en el pasillo, cierra la puerta.",
]


static func random_line() -> String:
	return LINES[randi() % LINES.size()]


static func count() -> int:
	return LINES.size()


static func line(index: int) -> String:
	return LINES[clampi(index, 0, LINES.size() - 1)]

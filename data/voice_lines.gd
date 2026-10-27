class_name VoiceLines
extends RefCounted

## Las líneas sueltas que dicen los profes en la oficina: Barcosa aporreando la
## puerta, Mamador cuando no encuentra nada. No son llamadas ni conversaciones,
## solo una frase y a otra cosa.
##
## Cada una tiene su id, su texto y su archivo en `assets/audio/voces/<id>.ogg`.
## **Si no hay grabación, solo sale el subtítulo**: en este juego no se usa la
## síntesis de voz en ningún sitio.
##
## **Barcosa no habla.** Sus cuatro líneas se quedan aquí porque se siguen
## leyendo cuando aporrea la cortina, pero no tienen id en `data/sounds.gd` ni
## archivo: son subtítulo y nada más. Las de Mamador sí están grabadas.

## Dónde van los archivos, dentro de assets/audio/.
const FILE_FORMAT: String = "voces/%s.ogg"

# --- Barcosa en la puerta ----------------------------------------------------
const BARCOSA_DOOR_1: String = "barcosa_puerta_1"
const BARCOSA_DOOR_2: String = "barcosa_puerta_2"
const BARCOSA_DOOR_3: String = "barcosa_puerta_3"
const BARCOSA_LEAVES: String = "barcosa_se_va"
## Las tres de cuando empieza a golpear; se elige una al azar.
const BARCOSA_DOOR: Array[String] = [
	"barcosa_puerta_1", "barcosa_puerta_2", "barcosa_puerta_3",
]

# --- Mamador cuando no encuentra nada ----------------------------------------
const MAMADOR_OK_1: String = "mamador_ok_1"
const MAMADOR_OK_2: String = "mamador_ok_2"
const MAMADOR_OK_3: String = "mamador_ok_3"
const MAMADOR_OK: Array[String] = ["mamador_ok_1", "mamador_ok_2", "mamador_ok_3"]

## El texto de cada línea, palabra por palabra.
const LINES: Dictionary = {
	"barcosa_puerta_1": "¿Quién cerró? Tengo clase en este salón.",
	"barcosa_puerta_2": "Abra, joven. Nada más paso lista y me voy.",
	"barcosa_puerta_3": "Diez minutos. Le estoy pidiendo diez minutos.",
	"barcosa_se_va": "Bueno, ya. Quedan todos con falta.",
	"mamador_ok_1": "Sin novedad. Me retiro.",
	"mamador_ok_2": "Nada de inteligencia artificial. Así me gusta.",
	"mamador_ok_3": "Todo en orden. Sigan así.",
}

## Todos los ids, para el catálogo de sonidos y el panel de pruebas.
const IDS: Array[String] = [
	"barcosa_puerta_1", "barcosa_puerta_2", "barcosa_puerta_3", "barcosa_se_va",
	"mamador_ok_1", "mamador_ok_2", "mamador_ok_3",
]


static func text_of(line_id: String) -> String:
	return str(LINES.get(line_id, ""))


static func has_line(line_id: String) -> bool:
	return LINES.has(line_id)


## El nombre del archivo que espera, dentro de assets/audio/.
static func file_name(line_id: String) -> String:
	return FILE_FORMAT % line_id


## Una al azar de un grupo.
static func pick(group: Array[String]) -> String:
	return "" if group.is_empty() else group[randi() % group.size()]

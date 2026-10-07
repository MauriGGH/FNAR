class_name ArmandoPrompts
extends GlassStalker

## Armando Prompts (rol Chica clásico + Lolbit). Se cree genio, presume títulos
## inventados y todo lo automatiza con IA. Misma ruta y misma mecánica de
## linterna que Juan.exe.
##
## Lo suyo aparte pasa en la PC: desde la noche 4, cada vez que el jugador
## pulsa "Resolver tarea" en Claudio hay probabilidad de que su cara tome toda
## la pantalla. Eso lo maneja la pantalla de la PC; aquí solo vive la
## probabilidad, las frases y la tecla de depuración.

## Su recorrido completo. Al ahuyentarlo con la linterna no vuelve de un salto
## a la sala de juntas: sigue bajando, sale del edificio, cruza el
## estacionamiento hasta la cafetería y de ahí da la vuelta.
const ROUTE: Array[String] = ["sala_juntas", "pasillo_norte", "pasillo_sur",
	"escalera_pb", "estacionamiento", "cafeteria"]
## El cristal queda a media ruta, no al final.
const GLASS_STEP: int = 2
const STEP_ESCALERA_PB: int = 3
const MOVE_INTERVAL: float = 7.0
const GAME_OVER_CAUSE: String = "Armando Prompts"

## Lo que tarda en irse si el jugador no escribe la frase.
const TAKEOVER_TIME: float = 6.0
## Lo que hay que escribir para quitárselo de encima. Se acepta sin acento y
## en minúsculas: la pantalla compara en mayúsculas y sin tildes.
const TAKEOVER_ANSWER: String = "APÁGATE"
## Lo que cuesta no lograrlo.
const TAKEOVER_POWER_COST: float = 5.0
## Probabilidad de aparecer, en fracción por punto de nivel de IA: con nivel 6
## sale 6 de cada 20 veces que se pulsa "Resolver tarea".
const TAKEOVER_CHANCE_PER_LEVEL: float = 1.0 / 20.0

const PHRASES: Array[String] = [
	"HOLA, SOY ARMANDO PROMPTS, INGENIERO EN PROMPTS CERTIFICADO POR MÍ MISMO.",
	"LE PEDÍ A CLAUDIO QUE HICIERA TU TAREA. TAMBIÉN LE PEDÍ QUE TE CORRIERA.",
	"ESTE MENSAJE FUE GENERADO CON IA. YO NI LO LEÍ.",
	"MI TESIS LA HIZO CLAUDIO. MI BODA TAMBIÉN.",
	"AUTOMATICÉ MIS SENTIMIENTOS. AHORA SUFRO 40% MÁS RÁPIDO.",
	"¿PENSAR? NAH, ESO ES DE BOOMERS.",
]

## La PC escucha esto para taparse con su cara.
signal takeover_requested(phrase: String)


## Nombre corto para los archivos de imagen: cam07_armando.png y demás.
func image_slug() -> String:
	return "armando"


## Antes de salir de su lugar inicial se queda mirando fijo a la cámara.
func stalks_before_leaving() -> bool:
	return true


func ai_key() -> String:
	return Nights.ARMANDO


func build_route() -> PackedStringArray:
	return PackedStringArray(ROUTE)


func step_interval() -> float:
	return MOVE_INTERVAL


func game_over_cause() -> String:
	return GAME_OVER_CAUSE


func glass_step() -> int:
	return GLASS_STEP


## Parado en la escalera lleva su sufijo: cam07_armando-escalera.
func _slug_token() -> String:
	if current_room == ROUTE[STEP_ESCALERA_PB]:
		return "%s-escalera" % image_slug()
	return super()


func retreats_walking() -> bool:
	return true


# --- Lo de la PC --------------------------------------------------------------

## true si esta noche ya puede aparecerse en la pantalla de Claudio.
func can_take_over_pc() -> bool:
	return Nights.armando_pc_enabled(GameManager.current_night, ai_level)


## Tira el dado de aparecer. Lo llama la PC al pulsar "Resolver tarea".
func roll_takeover() -> bool:
	if not can_take_over_pc():
		return false
	if randf() >= float(ai_level) * TAKEOVER_CHANCE_PER_LEVEL:
		return false
	force_takeover()
	return true


## Tecla 7: lo aparece en la pantalla sin tirar el dado.
func force_takeover() -> void:
	takeover_requested.emit(PHRASES[randi() % PHRASES.size()])



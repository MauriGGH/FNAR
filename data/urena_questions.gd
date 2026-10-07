class_name UrenaQuestions
extends RefCounted

## La llamada de Ureña. No es un examen: llama meloso, felicita al guardia por
## su trabajo de la noche y le ofrece "trabajitos extra" con doble sentido.
## El jugador tiene que zafarse con educación y rápido.
##
## Cada insinuación trae tres respuestas: esquivar con educación (la buena),
## seguirle el juego y contestar grosero. Las dos malas cuestan energía; solo
## seguirle el juego deja una foto suya en el escritorio.

## Qué clase de respuesta eligió el jugador.
enum Answer { DODGE, PLAYS_ALONG, RUDE }

## Cuántas insinuaciones por llamada (se sortea entre estas dos) y cuánto da
## para contestar cada una.
const MIN_LINES_PER_CALL: int = 1
const MAX_LINES_PER_CALL: int = 2
const SECONDS_PER_LINE: float = 6.0
## Lo que cuesta seguirle el juego o contestarle grosero.
const WRONG_ANSWER_POWER_COST: float = 5.0

## Lo que se quedan en pantalla el saludo, cada reacción y la despedida
## después de terminar de escribirse.
const GREETING_HOLD: float = 1.6
const REACTION_HOLD: float = 1.4
const FAREWELL_HOLD: float = 1.8


const BANK: Array[Dictionary] = [
	{
		"text": "Me dijeron que hiciste muy buen trabajo hoy… ¿no te gustaría hacerme unos trabajitos extra?",
		"dodge": "Gracias, profe, pero ya tengo muchas tareas esta noche.",
		"plays_along": "¿Qué tan extra, profe?",
		"rude": "Ni loco.",
	},
	{
		"text": "Siempre me han gustado los muchachos con iniciativa… ¿tú tienes iniciativa?",
		"dodge": "Sí, profe, ahorita mismo estoy revisando las cámaras.",
		"plays_along": "Pruébeme.",
		"rude": "Cuelgue, por favor.",
	},
	{
		"text": "Esta noche hace mucho frío en el edificio, ¿no? Yo sé cómo calentarnos…",
		"dodge": "Ya prendí el no-break, profe, todo en orden.",
		"plays_along": "Cuénteme más.",
		"rude": "¡Qué asco!",
	},
	{
		"text": "Tengo un proyecto muy grande que necesita a alguien como tú…",
		"dodge": "Mándelo por correo y lo reviso en la mañana.",
		"plays_along": "¿Qué tan grande?",
		"rude": "No me interesa.",
	},
	{
		"text": "¿Sabes cuál es mi materia favorita?",
		"dodge": "La que usted imparte, profe.",
		"plays_along": "Anatomía.",
		"rude": "No me importa.",
	},
	{
		"text": "Ven a mi salón cuando termines tu turno, te voy a dar unos créditos extra…",
		"dodge": "Mi turno termina a las 6, profe, y me voy derechito a mi casa.",
		"plays_along": "Ahí le caigo.",
		"rude": "Lo voy a reportar.",
	},
	{
		"text": "A ver, muchacho, explícame qué es el polimorfismo… pero despacito, como a mí me gusta.",
		"dodge": "Es cuando un mismo método se comporta distinto según el objeto, profe.",
		"plays_along": "Es cuando uno se adapta a lo que le pidan…",
		"rude": "Búsquelo en Google.",
	},
	{
		"text": "Oye, ¿no te gustaría heredar todos mis atributos esta noche?",
		"dodge": "Prefiero la composición, profe.",
		"plays_along": "Hágame su clase hija.",
		"rude": "Qué asco.",
	},
	{
		"text": "¿Y tú me dejarías sobrecargar tus métodos?",
		"dodge": "Solo con la firma correcta, profe.",
		"plays_along": "Los que usted quiera.",
		"rude": "Voy a colgar.",
	},
	{
		"text": "Se me ocurre una cosa… ¿qué tal si esta noche te convierto en mujer?",
		"dodge": "No, gracias, profe, así estoy bien.",
		"plays_along": "Sorpréndame.",
		"rude": "¡Cállese!",
	},
]


## El saludo: nombre del guardia y cuántas tareas lleva. %s es el nombre y %d
## las tareas; la de cero no lleva número.
const GREETING_NONE: String = "Hola, %s… aunque no has hecho nada, igual me caes bien"
const GREETING_ONE: String = "Hola, %s… ya vi que llevas 1 tarea terminada, qué aplicadito"
const GREETING_MANY: String = "Hola, %s… ya vi que llevas %d tareas terminadas, qué aplicadito"

## Varias variantes de cada reacción, para que no se repita en una llamada.
const REACTIONS_DODGE: Array[String] = [
	"Ay, qué serio… bueno, otro día.",
	"Uy, qué formal me saliste. Ni modo.",
	"Está bien, está bien… no te enojes.",
]
const REACTIONS_PLAYS_ALONG: Array[String] = [
	"¡Así me gusta!",
	"¡Ese es mi muchacho!",
	"Mmm… me encanta cómo piensas.",
]
const REACTIONS_RUDE: Array[String] = [
	"Qué grosero eres…",
	"Ay, qué carácter. Ni que te hubiera hecho algo.",
	"No tenías por qué contestarme así.",
]

## Se despide distinto si le siguió el juego alguna vez.
const FAREWELL_CLEAN: String = "Bueno, ahí te encargo… sigo esperando mis trabajitos."
const FAREWELL_DIRTY: String = "Te dejo mi foto para que te acuerdes de mí."


## Las insinuaciones de una llamada, sin repetir, con sus tres respuestas ya
## barajadas. Cada una queda como {"text": String, "answers": Array}.
static func pick() -> Array[Dictionary]:
	var pool: Array = BANK.duplicate()
	pool.shuffle()
	var picked: Array[Dictionary] = []
	var count: int = randi_range(MIN_LINES_PER_CALL, MAX_LINES_PER_CALL)
	for i: int in mini(count, pool.size()):
		picked.append(_shuffled_answers(pool[i]))
	return picked


static func _shuffled_answers(entry: Dictionary) -> Dictionary:
	var answers: Array[Dictionary] = [
		{"text": str(entry["dodge"]), "kind": Answer.DODGE},
		{"text": str(entry["plays_along"]), "kind": Answer.PLAYS_ALONG},
		{"text": str(entry["rude"]), "kind": Answer.RUDE},
	]
	answers.shuffle()
	return {"text": str(entry["text"]), "answers": answers}


static func greeting(player_name: String, tasks_done: int) -> String:
	if tasks_done <= 0:
		return GREETING_NONE % player_name
	if tasks_done == 1:
		return GREETING_ONE % player_name
	return GREETING_MANY % [player_name, tasks_done]


static func reaction(kind: Answer) -> String:
	var variants: Array[String] = REACTIONS_DODGE
	match kind:
		Answer.PLAYS_ALONG:
			variants = REACTIONS_PLAYS_ALONG
		Answer.RUDE:
			variants = REACTIONS_RUDE
	return variants[randi() % variants.size()]


## Si le siguió el juego alguna vez se despide dejando su foto; si solo
## esquivó (o se puso grosero sin seguirle el juego), se queda esperando.
static func farewell(played_along: bool) -> String:
	return FAREWELL_DIRTY if played_along else FAREWELL_CLEAN


## Las dos respuestas malas cuestan energía; la foto solo si le siguió el juego.
static func costs_power(kind: Answer) -> bool:
	return kind != Answer.DODGE


static func leaves_photo(kind: Answer) -> bool:
	return kind == Answer.PLAYS_ALONG

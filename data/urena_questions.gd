class_name UrenaQuestions
extends RefCounted

## La llamada de Ureña. No es un examen: llama meloso, felicita al guardia por
## sus tareas y le ofrece "trabajitos extra" con doble sentido. El jugador
## tiene que zafarse con educación y rápido.
##
## Cada insinuación trae tres respuestas: esquivar con educación (la buena),
## seguirle el juego y contestar grosero. Las dos malas cuestan energía; solo
## seguirle el juego deja su foto en el escritorio.
##
## Los textos son los del equipo, palabra por palabra. [NOMBRE] es el nombre
## del jugador y [N] las tareas que lleva terminadas esa noche.

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

## Las marcas que se cambian por el nombre del jugador y sus tareas.
const NAME_TAG: String = "[NOMBRE]"
const TASKS_TAG: String = "[N]"

const GREETING: String = "¡Quihubo, [NOMBRE]! Ya llevas [N] tareas... qué aplicadito."


const BANK: Array[Dictionary] = [
	{
		"text": "Ando buscando a alguien para unos trabajitos extra... en mi cubículo.",
		"dodge": "Ando de guardia, profe.",
		"plays_along": "Uff, ¿cuánto paga?",
		"rude": "Qué asco, profe.",
	},
	{
		"text": "Te quiero convertir en mujer por una noche.",
		"dodge": "Así estoy bien, gracias, profe.",
		"plays_along": "Uff, esas con Nutella.",
		"rude": "Está bien enfermo.",
	},
	{
		"text": "Te subo la calificación... ven a mi oficina a las 3 AM.",
		"dodge": "Mejor el examen, profe.",
		"plays_along": "¿Llevo algo, profe?",
		"rude": "Lo voy a acusar.",
	},
	{
		"text": "¿Me mandas una foto de cuerpo completo? Para el archivo.",
		"dodge": "Ya tiene la oficial.",
		"plays_along": "Ay, profe, qué rico.",
		"rude": "No me stalkee, viejo.",
	},
	{
		"text": "Se me puso bien duro... el disco. ¿Me lo formateas?",
		"dodge": "Tráigalo al laboratorio.",
		"plays_along": "Con todo y particiones.",
		"rude": "Búsquese un técnico.",
	},
	{
		"text": "¿Me haces una conexión punto a punto? Sin switch.",
		"dodge": "Solo con ticket, profe.",
		"plays_along": "¿Me pasa su IP?",
		"rude": "Me da asco, profe.",
	},
	{
		"text": "Tengo el cable bien largo... ¿me ayudas a ponchar el conector?",
		"dodge": "Mañana en el laboratorio.",
		"plays_along": "Uy, ¿categoría 6?",
		"rude": "Guárdese su cable.",
	},
]


## Las cuatro despedidas, según cómo le fue en la llamada.
const FAREWELL_ALL_DODGED: String = "Ay, qué serio... la oferta sigue en pie."
const FAREWELL_PLAYED_ALONG: String = "Te dejé un regalito en tu escritorio."
const FAREWELL_RUDE: String = "Me rompiste el corazón... y eso se paga."
## Esta sale por el altavoz después del tono de ocupado, al colgarle.
const FAREWELL_SNUBBED: String = "¿Me colgaste? ...Ahorita voy para allá."


## Cuántas insinuaciones hay en el banco.
static func count() -> int:
	return BANK.size()


## El texto de una insinuación, para la lista del panel de pruebas.
static func line_text(index: int) -> String:
	return str(BANK[index]["text"]) if index >= 0 and index < BANK.size() else ""


## Las insinuaciones de una llamada, con sus tres respuestas ya barajadas.
## used son los índices que ya salieron esta noche: no se repiten.
static func pick(used: Array[int] = []) -> Array[Dictionary]:
	var pool: Array[int] = []
	for i: int in BANK.size():
		if not i in used:
			pool.append(i)
	# Si ya se usaron todas en la noche, se vuelve a empezar con el banco.
	if pool.is_empty():
		for i: int in BANK.size():
			pool.append(i)
	pool.shuffle()
	var count_wanted: int = randi_range(MIN_LINES_PER_CALL, MAX_LINES_PER_CALL)
	var picked: Array[Dictionary] = []
	for i: int in mini(count_wanted, pool.size()):
		picked.append(line(pool[i]))
	return picked


## Una insinuación concreta, por índice. La usa el panel de pruebas.
static func line(index: int) -> Dictionary:
	if index < 0 or index >= BANK.size():
		return {}
	var entry: Dictionary = BANK[index]
	var answers: Array[Dictionary] = [
		{"text": str(entry["dodge"]), "kind": Answer.DODGE},
		{"text": str(entry["plays_along"]), "kind": Answer.PLAYS_ALONG},
		{"text": str(entry["rude"]), "kind": Answer.RUDE},
	]
	answers.shuffle()
	return {"index": index, "text": str(entry["text"]), "answers": answers}


## El saludo, con el nombre del guardia y sus tareas puestos.
static func greeting(player_name: String, tasks_done: int) -> String:
	return GREETING.replace(NAME_TAG, player_name).replace(TASKS_TAG, str(tasks_done))


## Lo que contesta a cada clase de respuesta. Son frases cortas de relleno
## entre insinuaciones; las que cuentan son las despedidas.
static func reaction(kind: Answer) -> String:
	match kind:
		Answer.PLAYS_ALONG:
			return "¡Así me gusta!"
		Answer.RUDE:
			return "Qué grosero eres..."
	return "Ay, qué serio..."


## La despedida que toca: la foto manda sobre lo grosero, y lo grosero sobre
## haber esquivado todo.
static func farewell(played_along: bool, was_rude: bool) -> String:
	if played_along:
		return FAREWELL_PLAYED_ALONG
	if was_rude:
		return FAREWELL_RUDE
	return FAREWELL_ALL_DODGED


## Las dos respuestas malas cuestan energía; la foto solo si le siguió el juego.
static func costs_power(kind: Answer) -> bool:
	return kind != Answer.DODGE


static func leaves_photo(kind: Answer) -> bool:
	return kind == Answer.PLAYS_ALONG

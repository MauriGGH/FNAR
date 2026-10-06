class_name UrenaQuestions
extends RefCounted

## Banco de preguntas de la llamada de Ureña. Son de ejemplo: el equipo
## escribirá las reales. Cada una trae tres opciones y el índice de la buena.

## Cuántas pregunta por llamada y cuánto da para contestar cada una.
const QUESTIONS_PER_CALL: int = 3
const SECONDS_PER_QUESTION: float = 6.0
## Lo que cuesta cada respuesta mala o sin contestar.
const WRONG_ANSWER_POWER_COST: float = 5.0

const BANK: Array[Dictionary] = [
	{
		"text": "¿Que comando muestra la configuracion de red del equipo?",
		"options": ["ipconfig", "netstat", "tracert"],
		"correct": 0,
	},
	{
		"text": "¿Cuantos puertos tiene el patch panel de la sala?",
		"options": ["8", "12", "24"],
		"correct": 1,
	},
	{
		"text": "¿Que cable va de una PC a un switch?",
		"options": ["Cruzado", "Recto", "Fibra"],
		"correct": 1,
	},
	{
		"text": "¿En que cubiculo esta el cuarto de redes?",
		"options": ["La sala de servidores", "El cubiculo 2", "El cubiculo 3"],
		"correct": 0,
	},
	{
		"text": "¿A que hora termina el turno del guardia?",
		"options": ["5 AM", "6 AM", "7 AM"],
		"correct": 1,
	},
	{
		"text": "¿Que se usa para darle cuerda a la botarga?",
		"options": ["El breaker", "La linterna", "El boton de la CAM 4"],
		"correct": 2,
	},
]


## Saca al azar las preguntas de una llamada, sin repetir.
static func pick() -> Array[Dictionary]:
	var pool: Array = BANK.duplicate()
	pool.shuffle()
	var picked: Array[Dictionary] = []
	for i: int in mini(QUESTIONS_PER_CALL, pool.size()):
		picked.append(pool[i])
	return picked

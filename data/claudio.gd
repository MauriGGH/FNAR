class_name Claudio
extends RefCounted

## Las frases de Claudio, el asistente de IA de la PC. Es una parodia de
## asistente: empieza todo con "¡Excelente pregunta!" y se disculpa por todo,
## incluso cuando no hizo nada mal.

const OPENER: String = "¡Excelente pregunta!"

## Disculpas al azar, para que no diga siempre la misma.
const APOLOGIES: Array[String] = [
	"Perdón por la demora,",
	"Mil disculpas,",
	"Perdón por el inconveniente,",
	"Disculpa la molestia,",
]

## Con qué cierra cuando termina algo.
const CLOSERS: Array[String] = [
	"Perdón si tardé.",
	"Disculpa cualquier error.",
	"Perdón por no hacerlo antes.",
]


## Una respuesta normal: abre con su frase y sigue con lo que haya que decir.
static func say(text: String) -> String:
	return "%s %s" % [OPENER, text]


## Una respuesta donde además se disculpa antes de decir lo suyo.
static func sorry(text: String) -> String:
	var apology: String = APOLOGIES[randi() % APOLOGIES.size()]
	return "%s %s %s" % [OPENER, apology, _lower_first(text)]


## Lo que dice al terminar: siempre se disculpa de pasada.
static func done(text: String) -> String:
	return "%s %s %s" % [OPENER, text, CLOSERS[randi() % CLOSERS.size()]]


## Tras una disculpa la frase sigue en minúscula, como una oración partida.
static func _lower_first(text: String) -> String:
	if text.is_empty():
		return text
	return text.substr(0, 1).to_lower() + text.substr(1)

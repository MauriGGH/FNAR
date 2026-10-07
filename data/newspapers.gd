class_name Newspapers
extends RefCounted

## Los recortes de periódico que cuentan la historia de fondo. El jugador no
## recibe ninguna explicación en el juego: la va armando con estos siete
## recortes, uno antes de la noche 1 y los demás al pasar cada noche.
##
## Si existe assets/art/extras/periodico_N (png, jpg o jpeg) se usa esa
## imagen; si no, el recorte se dibuja con una plantilla de periódico y el
## texto de aquí.

const IMAGE_PATH: String = "res://assets/art/extras/periodico_%d"

## La cabecera del periódico inventado, la misma en todos los recortes.
const MASTHEAD: String = "EL HERALDO UNIVERSITARIO"

## El recorte que sale antes de empezar la noche 1.
const FIRST_INDEX: int = 0

const CLIPPINGS: Array[Dictionary] = [
	{
		"title": "SE BUSCA GUARDIA NOCTURNO",
		"date": "12 de agosto",
		"body": [
			"La Coordinación de Sistemas convoca a un alumno para cubrir",
			"la vigilancia nocturna del edificio, de 12 a 6 de la mañana.",
			"No se requiere experiencia. Pago por noche y constancia.",
			"\"Excelente oportunidad de servicio social\", informa la jefatura.",
		],
	},
	{
		"title": "DESAPARECE UN ALUMNO DURANTE LA BIENVENIDA",
		"date": "3 de septiembre",
		"body": [
			"Santi, alumno de Sistemas, no volvió a casa tras el evento de",
			"bienvenida. Compañeros declaran que la última vez que lo vieron",
			"traía puesta la botarga de la mascota de la universidad. La",
			"botarga apareció al día siguiente, doblada en su silla.",
		],
	},
	{
		"title": "\"LA BOTARGA TOCA SOLA POR LAS NOCHES\"",
		"date": "19 de septiembre",
		"body": [
			"Alumnos de la coordinación reportan que la botarga guardada en el",
			"cubículo 3 toca de madrugada una cancioncita de cajita musical,",
			"sin que nadie le dé cuerda. La jefatura lo atribuye a \"un juguete",
			"viejo\" y pide no difundir rumores entre los de primer semestre.",
		],
	},
	{
		"title": "HALLAN VELAS Y SAL EN LA SALA DE JUNTAS",
		"date": "2 de octubre",
		"body": [
			"Personal de intendencia encontró velas consumidas, sal en el piso",
			"y un símbolo trazado sobre la mesa ovalada. La universidad niega",
			"que se haya celebrado cualquier clase de ritual en sus salones.",
			"En la bitácora no aparece quién convocó esa junta.",
		],
	},
	{
		"title": "RENUNCIA EL PERSONAL DE LIMPIEZA NOCTURNO",
		"date": "21 de octubre",
		"body": [
			"Los tres trabajadores del turno de noche presentaron su renuncia",
			"el mismo día y se negaron a volver al edificio. Uno de ellos",
			"declaró a este diario: \"dentro de la botarga se oyen voces,",
			"muchas voces\". La coordinación no quiso hacer comentarios.",
		],
	},
	{
		"title": "SE FILTRA LA LISTA DE ASISTENTES A LA JUNTA",
		"date": "8 de noviembre",
		"body": [
			"Circula entre los alumnos una copia del registro de aquella noche.",
			"La hoja lleva fecha, hora de entrada y ocho firmas, pero todos",
			"los nombres aparecen tachados con tinta, uno por uno.",
			"El original ya no está en el archivo de la coordinación.",
		],
	},
	{
		"title": "CLAUSURAN LA COORDINACIÓN DE SISTEMAS",
		"date": "30 de noviembre",
		"body": [
			"La universidad cerró el edificio por tiempo indefinido y retiró",
			"el equipo de los cubículos. No se informó el destino de la botarga.",
			"El expediente se entregó a las autoridades con una sola línea:",
			"\"El responsable sigue sin ser identificado\".",
		],
	},
]


static func count() -> int:
	return CLIPPINGS.size()


static func has(index: int) -> bool:
	return index >= 0 and index < CLIPPINGS.size()


static func clipping(index: int) -> Dictionary:
	return CLIPPINGS[index] if has(index) else {}


## Qué recorte toca al pasar una noche. La noche 1 da el 1, y así.
static func index_for_cleared_night(night: int) -> int:
	return night


## La imagen del recorte, o null si todavía no existe y hay que dibujarlo.
static func image(index: int) -> Texture2D:
	return GameAssets.load_texture(IMAGE_PATH % index)

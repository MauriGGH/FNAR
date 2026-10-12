class_name Newspapers
extends RefCounted

## Los recortes de periódico que cuentan la historia de fondo. El jugador no
## recibe ninguna explicación en el juego: la va armando con estos siete
## recortes, uno antes de la noche 1 y los demás al pasar cada noche.
##
## **Se desbloquean por número de noche, no por contenido**
## (`index_for_cleared_night`), así que reordenar o reescribir los recortes no
## rompe una partida guardada: el que tenía desbloqueado el 3 sigue teniendo
## desbloqueado el 3, con el contenido que lleve ahora.
##
## El orden no es el cronológico: el recorte 1 es de la posada de diciembre, de
## un semestre antes que todo lo demás, porque es el primer hilo del que se
## tira. Las fechas y los titulares son los que traen pintadas las imágenes.
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
		"date": "Lunes 12 de agosto",
		"body": [
			"La Coordinación de Sistemas convoca a un alumno para cubrir",
			"la vigilancia nocturna del edificio, de 12 a 6 de la mañana.",
			"No se requiere experiencia. Pago por noche y constancia.",
			"\"Excelente oportunidad de servicio social\", informa la jefatura.",
		],
	},
	{
		"title": "ENCUENTRAN TERMO CON RESTOS DE TEQUILA TRAS LA POSADA DE LA COORDINACIÓN",
		"date": "Lunes 16 de diciembre",
		"body": [
			"A la mañana siguiente de la posada de la Coordinación de Sistemas,",
			"intendencia encontró entre la basura del salón un termo color",
			"verde-limón con restos de tequila. La dirección había prohibido el",
			"alcohol en el evento. El termo se entregó a vigilancia como",
			"evidencia y nadie se ha presentado a reclamarlo. Varios alumnos",
			"aseguran que pasó de mano en mano toda la noche y que el último en",
			"tenerlo fue Santiago, alumno de Sistemas. Él lo niega: \"mi termo",
			"era verde-naranja, ese termo no es mío\", aunque en un principio",
			"él mismo había ido a buscarlo.",
		],
	},
	{
		"title": "DESAPARECE ALUMNO DURANTE EL EVENTO DE BIENVENIDA",
		"date": "Lunes 19 de agosto",
		"body": [
			"Santi, alumno de Sistemas, no volvió a casa tras el evento de",
			"bienvenida. Lo vieron por última vez quitándose la botarga de la",
			"mascota detrás del edificio. La botarga apareció al día siguiente,",
			"doblada en su silla del cubículo 3.",
		],
	},
	{
		"title": "ESCUCHAN MÚSICA EN LA COORDINACIÓN VACÍA",
		"date": "Lunes 26 de agosto",
		"body": [
			"Alumnos aseguran que una cajita musical suena sola pasada la",
			"medianoche. Un grupo que se quedó a terminar una práctica dice",
			"haberla oído del lado de los cubículos, con el edificio cerrado.",
			"La jefatura lo atribuye a \"un juguete viejo\" y pide no difundir",
			"rumores entre los de primer semestre.",
		],
	},
	{
		"title": "HALLAN RESTOS DE UN RITUAL EN LA SALA DE JUNTAS",
		"date": "Lunes 2 de septiembre",
		"body": [
			"Velas consumidas, sal en el piso y un símbolo dibujado sobre la",
			"mesa ovalada. La universidad habla de una broma y niega que se",
			"haya celebrado cualquier clase de ritual en sus salones.",
			"En la bitácora no aparece quién convocó esa junta.",
		],
	},
	{
		"title": "SE FILTRA LA LISTA DE LA JUNTA EXTRAORDINARIA",
		"date": "Lunes 9 de septiembre",
		"body": [
			"Circula entre los alumnos una copia del registro de aquella noche.",
			"La hoja lleva fecha, hora de entrada y ocho firmas, pero todos los",
			"nombres aparecen tachados con tinta roja, uno por uno.",
			"El original ya no está en el archivo de la coordinación.",
		],
	},
	{
		"title": "CLAUSURAN LA COORDINACIÓN DE SISTEMAS",
		"date": "Lunes 16 de septiembre",
		"body": [
			"Tras semanas de incidentes, la rectoría ordenó cerrar el edificio",
			"de forma indefinida y retiró el equipo de los cubículos. No se",
			"informó el destino de la botarga. El expediente se entregó a las",
			"autoridades con una sola línea: \"el responsable sigue sin",
			"aparecer\".",
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

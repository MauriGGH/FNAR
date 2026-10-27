class_name UnoDeck
extends RefCounted

## La baraja de la tarea "Inventariar material decomisado". Son cartas al
## estilo de las de UNO —óvalo blanco inclinado, número grande al centro y dos
## chiquitos en las esquinas— pero **sin el logo ni la palabra**: solo la forma
## que todo el mundo reconoce.
##
## Aquí vive todo lo que es diseño (colores, cuántas cartas, dónde cae cada
## cosa en la pantalla acercada); el estado de la partida lo lleva
## `UnoDeckModel` y el dibujo, `scenes/office/uno_desk.gd`.

## Los cuatro colores, en el orden en que se enseñan los montones.
const RED: int = 0
const YELLOW: int = 1
const GREEN: int = 2
const BLUE: int = 3
const COLORS: Array[int] = [RED, YELLOW, GREEN, BLUE]

## Del 0 al 5, que son seis cartas por color: 24 en total.
const LOWEST: int = 0
const HIGHEST: int = 5
const PER_COLOR: int = HIGHEST - LOWEST + 1
const TOTAL: int = PER_COLOR * 4

## El color de cada palo. Son parecidos a los de verdad sin ser los mismos:
## bajados de saturación para que peguen con la oficina.
const INK: Dictionary = {
	RED: Color(0.84, 0.19, 0.16),
	YELLOW: Color(0.95, 0.74, 0.13),
	GREEN: Color(0.20, 0.62, 0.29),
	BLUE: Color(0.13, 0.41, 0.74),
}
const NAMES: Dictionary = {
	RED: "ROJO", YELLOW: "AMARILLO", GREEN: "VERDE", BLUE: "AZUL",
}

# --- Cómo es una carta --------------------------------------------------------

## El tamaño de una carta en la pantalla acercada, y lo redondeada que va.
const CARD_SIZE: Vector2 = Vector2(66.0, 98.0)
const CARD_RADIUS: float = 9.0
## El marco blanco de fuera, y lo inclinado que va el óvalo de en medio.
const CARD_BORDER: float = 6.0
const OVAL_TILT: float = -0.44
## Ancho y alto del óvalo en fracción de la carta. Tiene que ser **bastante
## más ancho que alto**: con 0.80 x 0.52 salía un círculo y la inclinación no
## se notaba.
const OVAL_SIZE: Vector2 = Vector2(0.86, 0.40)
## Los números: el grande del centro y los dos de las esquinas, en fracción
## del alto de la carta.
const BIG_NUMBER: float = 0.52
const SMALL_NUMBER: float = 0.19
const CORNER_INSET: Vector2 = Vector2(0.16, 0.12)

const WHITE: Color = Color(0.96, 0.95, 0.92)
const CARD_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.35)
## El dorso, para la baraja guardada que se ve sobre el escritorio.
const BACK: Color = Color(0.11, 0.1, 0.11)

# --- La pantalla acercada -----------------------------------------------------

## Todo está medido sobre el lienzo de 1152x648 de la noche.
const CANVAS: Vector2 = Vector2(1152.0, 648.0)
## Los cuatro montones, arriba: dónde empieza el primero y cuánto se separan.
const PILE_FIRST: Vector2 = Vector2(300.0, 52.0)
const PILE_STEP: float = 184.0
## Lo que se encima una carta sobre la anterior dentro de un montón: lo justo
## para contarlas de un vistazo sin perder el número de la de arriba.
const PILE_OVERLAP: float = 13.0

## El revoltijo de abajo: la rejilla sobre la que se reparten las 24 cartas.
## Acaba en x 856 a propósito: lo que queda a la derecha es el hueco del botón
## de "Guardar baraja", y así ninguna carta se esconde debajo.
const SPREAD: Rect2 = Rect2(96.0, 300.0, 760.0, 300.0)
const SPREAD_COLUMNS: int = 8
## Lo chueca que queda cada carta del revoltijo. Es poco a propósito: el clic
## se prueba contra el rectángulo sin girar, así que una carta muy torcida se
## agarraría mal.
const SPREAD_TILT: float = 0.09
## Y lo que se corre de su casilla, para que no parezca una cuadrícula.
const SPREAD_JITTER: Vector2 = Vector2(10.0, 8.0)

## Lo que tarda una carta en regresarse sola cuando la sueltas donde no va.
const RETURN_TIME: float = 0.22

## La mesa de la pantalla acercada.
const DESK_TOP: Color = Color(0.17, 0.14, 0.12)
const DESK_BOTTOM: Color = Color(0.09, 0.07, 0.06)
const SLOT_EMPTY: Color = Color(1.0, 1.0, 1.0, 0.1)

# --- La baraja sobre el escritorio --------------------------------------------

## Dónde se ve la baraja guardada en la vista central, **medido sobre
## `oficina_centro.jpeg`**: el hueco de mesa que queda a la derecha del
## teclado, antes de la tabla de las hojas. Es el mismo rectángulo que la zona
## de clic `uno_deck` de `data/oficina_zonas.json`.
const DESK_SPOT: Rect2 = Rect2(0.335, 0.800, 0.055, 0.072)
## Cuántas cartas se dibujan de canto en el montoncito del escritorio.
const DESK_STACK: int = 5
## Lo que se le baja el brillo a la baraja para que pegue con la mesa. Está
## **medido** sobre `oficina_centro_oscura.jpeg`: en ese pedazo de escritorio
## lo más claro que hay son las tazas, con 136 de 255, así que el blanco de la
## carta (245) tiene que caer por ahí. El tinte es frío, como la luz que les
## llega del monitor.
const DESK_LIGHT: Color = Color(0.46, 0.52, 0.60)


## Las 24 cartas revueltas. Cada una es {"color", "number"}.
static func shuffled() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for color: int in COLORS:
		for number: int in range(LOWEST, HIGHEST + 1):
			cards.append({"color": color, "number": number})
	cards.shuffle()
	return cards


## El color de un montón por su posición, de izquierda a derecha.
static func color_at(slot: int) -> int:
	return COLORS[clampi(slot, 0, COLORS.size() - 1)]


static func ink(color: int) -> Color:
	return INK.get(color, WHITE) as Color

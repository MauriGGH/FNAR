class_name UnoDeckModel
extends RefCounted

## El estado de la baraja decomisada. Vive en el GameManager, no en la
## pantalla, por dos razones:
##
## - **La tarjeta de la PC y la mesa acercada miran lo mismo.** Una enseña
##   cuántas van y la otra deja moverlas.
## - **Mamador pregunta por ella desde el cristal.** Lo que le importa no es
##   que la pantalla esté abierta, sino que la baraja esté *afuera*: si la
##   dejaste a medio acomodar y te fuiste a las cámaras, sigue estando afuera.
##
## Cerrar la pantalla con Esc **no la guarda**: eso lo hace el botón "Guardar
## baraja", que recoge las cartas sueltas sin perder lo ya acomodado. Ese es el
## precio de la tarea: para dejarla a salvo hay que parar de jugar.

## Cambió algo que se ve (una carta movida, la baraja guardada).
signal changed()
## Los cuatro montones quedaron completos.
signal solved()

## Las 24 cartas, en el orden en que se repartieron sobre la mesa. Cada una es
## {"color", "number"} y su sitio en el revoltijo es su índice.
var cards: Array[Dictionary] = []
## Lo que lleva cada montón: color -> cuántas van puestas (el siguiente número
## que acepta es justo ese).
var piles: Dictionary = {}
## true mientras el ticket esté vivo: la baraja se ve sobre el escritorio.
var is_available: bool = false
## true mientras las cartas estén afuera. Es lo que ve Mamador.
var is_out: bool = false
var is_solved: bool = false


func reset() -> void:
	cards = UnoDeck.shuffled()
	piles.clear()
	for color: int in UnoDeck.COLORS:
		piles[color] = 0
	is_available = false
	is_out = false
	is_solved = false


## Llegó el ticket: la baraja aparece junto al teclado, todavía guardada.
func make_available() -> void:
	if is_available or is_solved:
		return
	if cards.is_empty():
		reset()
	is_available = true
	changed.emit()


## La sacas de su caja. De aquí en adelante Mamador la puede ver.
func take_out() -> void:
	if not is_available or is_out or is_solved:
		return
	is_out = true
	changed.emit()


## "Guardar baraja": las sueltas vuelven a la caja y lo acomodado se queda.
func put_away() -> void:
	if not is_out:
		return
	is_out = false
	changed.emit()


## Cuántas cartas siguen sueltas, o sea las que no están en ningún montón.
func loose_count() -> int:
	return UnoDeck.TOTAL - placed_count()


func placed_count() -> int:
	var total: int = 0
	for color: int in UnoDeck.COLORS:
		total += int(piles.get(color, 0))
	return total


## ¿Está puesta ya esa carta? Lo está si su número es menor que lo que lleva
## su montón, porque los montones se llenan del 0 para arriba.
func is_placed(card: Dictionary) -> bool:
	return int(card.get("number", 0)) < int(piles.get(int(card.get("color", 0)), 0))


## Intenta poner una carta en el montón de un color. Solo entra la que sigue:
## el montón del rojo con tres cartas únicamente acepta el rojo 3.
func try_place(card: Dictionary, pile_color: int) -> bool:
	if is_solved or int(card.get("color", -1)) != pile_color:
		return false
	if int(card.get("number", -1)) != int(piles.get(pile_color, 0)):
		return false
	piles[pile_color] = int(piles[pile_color]) + 1
	changed.emit()
	if placed_count() >= UnoDeck.TOTAL:
		_finish()
	return true


## Se acabó: la baraja se guarda sola y deja de ser un problema.
func _finish() -> void:
	is_solved = true
	is_out = false
	is_available = false
	changed.emit()
	solved.emit()


## El panel de pruebas y las capturas: deja `placed` cartas ya acomodadas,
## repartidas entre los cuatro montones, para no tener que arrastrar 24.
func debug_place(placed: int) -> void:
	for color: int in UnoDeck.COLORS:
		piles[color] = 0
	var left: int = clampi(placed, 0, UnoDeck.TOTAL - 1)
	var slot: int = 0
	while left > 0:
		var color: int = UnoDeck.color_at(slot % UnoDeck.COLORS.size())
		if int(piles[color]) < UnoDeck.PER_COLOR:
			piles[color] = int(piles[color]) + 1
			left -= 1
		slot += 1
	changed.emit()

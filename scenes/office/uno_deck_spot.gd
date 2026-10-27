class_name UnoDeckSpot
extends Control

## La baraja decomisada, vista desde la oficina: un montoncito de cartas boca
## abajo sobre la mesa, a la derecha del teclado. Es lo que se pica para
## abrir la mesa de cerca.
##
## Cuelga del Content de la vista central, como el tótem, así que se mueve con
## el mismo parallax, se desenfoca con el giro y se apaga con el apagón sin
## tratarlo aparte. Se dibuja por código: no hay arte de baraja.
##
## Lo que **no** le llega es el desenfoque del giro: `office_view.gdshader`
## difumina muestreando la textura, y aquí no hay textura que muestrear, son
## rectángulos. Es lo mismo que le pasa al sobrecito del ticket.
##
## **Afuera se nota.** Guardada se ve el montoncito de canto; desparramada,
## las cartas sueltas encima. Esa diferencia es la única pista de que Mamador
## la puede ver.

## Lo que se encima una carta sobre la de abajo en el montoncito, en fracción
## del alto del hueco.
const STACK_STEP: float = 0.085
## Las cartas sueltas que se dibujan cuando la baraja está afuera.
const LOOSE: int = 3

var _model: UnoDeckModel = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Las cartas vienen a pleno color y la oficina está a oscuras: sin esto
	# la baraja parece pegada encima de la foto.
	modulate = UnoDeck.DESK_LIGHT
	visible = false


func bind(model: UnoDeckModel) -> void:
	_model = model
	if not _model.changed.is_connected(_refresh):
		_model.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	visible = _model != null and _model.is_available
	queue_redraw()


func _draw() -> void:
	if _model == null or not _model.is_available:
		return
	# Una carta ocupa casi todo el hueco; las demás van detrás, escalonadas.
	var card: Vector2 = Vector2(size.x * 0.62, size.y * 0.86)
	var base: Vector2 = Vector2(size.x * 0.5 - card.x * 0.5, size.y - card.y)
	for i: int in UnoDeck.DESK_STACK:
		var lift: float = float(UnoDeck.DESK_STACK - 1 - i) * size.y * STACK_STEP
		UnoCard.draw_back(self, Rect2(base - Vector2(0.0, lift), card))
	if not _model.is_out:
		return
	# Afuera: unas cuantas boca arriba, desparramadas sobre el montón.
	for i: int in LOOSE:
		var at: Vector2 = base + Vector2(
			(float(i) - 1.0) * card.x * 0.42, -size.y * STACK_STEP * float(i + 3))
		UnoCard.draw_card(self, Rect2(at, card),
			{"color": UnoDeck.color_at(i), "number": i + 1},
			(float(i) - 1.0) * 0.3, false)

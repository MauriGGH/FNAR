class_name UnoDesk
extends Control

## El escritorio de cerca, con la baraja decomisada desparramada. Es la única
## tarea que no se hace en la PC ni en el rack: se hace aquí, en la mesa.
##
## Las cartas se arrastran a los cuatro montones de arriba, uno por color y en
## orden del 0 al 5. Soltar una donde no va la regresa sola a su sitio: no hay
## castigo, lo que cuesta es el tiempo.
##
## Se sale como de las otras pantallas acercadas: clic fuera, Esc o clic
## derecho. **Salir así no guarda la baraja**, y esa es la gracia: mientras
## siga afuera, Mamador la puede ver desde el cristal. Para dejarla a salvo
## está el botón "Guardar baraja", que recoge lo suelto sin perder lo hecho.

signal closed()
## El jugador recogió la baraja: la noche lo usa para cerrar también la vista.
signal put_away()

const ACTIVE_MARGIN: float = 26.0
const TITLE: String = "MATERIAL DECOMISADO"
const SAVE_TEXT: String = "Guardar baraja"
## Dónde va el botón. El ancho lo pone él solo con su texto, así que aquí solo
## va la esquina de arriba a la izquierda.
const SAVE_AT: Vector2 = Vector2(880.0, 544.0)
## Más chico que el de los menús: aquí es un botón de trabajo, no una opción.
const SAVE_SIZE: Vector2 = Vector2(256.0, 48.0)

var is_open: bool = false

var _model: UnoDeckModel = null
## La carta que se trae en la mano, o -1. Es su índice en `cards`.
var _dragging: int = -1
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_at: Vector2 = Vector2.ZERO
## La que se está regresando sola, con lo que le queda de viaje.
var _returning: int = -1
var _return_left: float = 0.0
var _return_from: Vector2 = Vector2.ZERO
var _hover_pile: int = -1

var _exit_hint: ExitHint = null
var _save_button: Button = null


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_exit_hint = ExitHint.build(self)
	_build_save_button()


## Lo que cuenta como "la mesa": los montones y el revoltijo juntos. Un clic
## fuera de ahí es un clic para salir.
func active_rect() -> Rect2:
	var piles: Rect2 = Rect2(UnoDeck.PILE_FIRST, Vector2(
		UnoDeck.PILE_STEP * 3.0 + UnoDeck.CARD_SIZE.x, UnoDeck.CARD_SIZE.y))
	return piles.merge(UnoDeck.SPREAD).grow(ACTIVE_MARGIN)


func bind(model: UnoDeckModel) -> void:
	_model = model
	if not _model.changed.is_connected(queue_redraw):
		_model.changed.connect(queue_redraw)


func open() -> void:
	if is_open or _model == null:
		return
	is_open = true
	visible = true
	_dragging = -1
	_returning = -1
	_model.take_out()
	if _exit_hint != null:
		_exit_hint.show_once("baraja")
	queue_redraw()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	_dragging = -1
	closed.emit()


# --- Entrada ------------------------------------------------------------------

## Igual que el breaker: Esc, clic derecho o clic fuera de la mesa. Va en
## _input porque este Control está en STOP y si no se quedaría los clics.
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if click.button_index == MOUSE_BUTTON_RIGHT:
		close()
		get_viewport().set_input_as_handled()
		return
	if click.button_index == MOUSE_BUTTON_LEFT \
			and not active_rect().has_point(click.position) \
			and not _save_button.get_rect().has_point(click.position):
		close()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		if _dragging >= 0:
			_drag_at = motion.position - _drag_offset
			_hover_pile = _pile_under(_drag_at + UnoDeck.CARD_SIZE * 0.5)
			queue_redraw()
		return

	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if click.pressed:
		_grab(click.position)
	else:
		_drop()
	accept_event()


## Agarra la carta de más arriba bajo el cursor. Se recorren al revés porque
## las últimas son las que se dibujan encima.
func _grab(at: Vector2) -> void:
	if _model == null or _model.is_solved:
		return
	for i: int in range(_model.cards.size() - 1, -1, -1):
		if _model.is_placed(_model.cards[i]):
			continue
		var rect: Rect2 = Rect2(_spread_at(i), UnoDeck.CARD_SIZE)
		if not rect.has_point(at):
			continue
		_dragging = i
		_drag_offset = at - rect.position
		_drag_at = rect.position
		_returning = -1
		AudioManager.play(Sounds.CARD_PICK)
		queue_redraw()
		return


## La suelta. Si cae en su montón, entra; si no, se regresa sola.
func _drop() -> void:
	if _dragging < 0:
		return
	var index: int = _dragging
	var pile: int = _pile_under(_drag_at + UnoDeck.CARD_SIZE * 0.5)
	_dragging = -1
	_hover_pile = -1
	if pile >= 0 and _model.try_place(_model.cards[index], UnoDeck.color_at(pile)):
		AudioManager.play(Sounds.CARD_DROP)
		queue_redraw()
		return
	# Donde no va: vuelve a su sitio, sin castigo.
	_returning = index
	_return_left = UnoDeck.RETURN_TIME
	_return_from = _drag_at
	AudioManager.play(Sounds.CARD_PICK)
	queue_redraw()


## Sobre qué montón está el punto, o -1.
func _pile_under(at: Vector2) -> int:
	for slot: int in UnoDeck.COLORS.size():
		if _pile_rect(slot).grow(14.0).has_point(at):
			return slot
	return -1


func _process(delta: float) -> void:
	if _returning < 0:
		return
	_return_left -= delta
	if _return_left <= 0.0:
		_returning = -1
	queue_redraw()


func _on_save_pressed() -> void:
	if _model != null:
		_model.put_away()
	put_away.emit()
	close()


# --- Sitios -------------------------------------------------------------------

## Dónde descansa una carta del revoltijo: su casilla de la rejilla, corrida
## un poco con un vaivén fijo por índice (siempre el mismo, no al azar en cada
## cuadro).
func _spread_at(index: int) -> Vector2:
	var columns: int = UnoDeck.SPREAD_COLUMNS
	var rows: int = ceili(float(UnoDeck.TOTAL) / float(columns))
	var column: int = index % columns
	var row: int = index / columns
	var step: Vector2 = Vector2(
		(UnoDeck.SPREAD.size.x - UnoDeck.CARD_SIZE.x) / float(columns - 1),
		(UnoDeck.SPREAD.size.y - UnoDeck.CARD_SIZE.y) / float(maxi(rows - 1, 1)))
	var at: Vector2 = UnoDeck.SPREAD.position + Vector2(column * step.x, row * step.y)
	return at + Vector2(sin(float(index) * 12.9898), sin(float(index) * 4.233 + 1.7)) \
		* UnoDeck.SPREAD_JITTER


func _spread_tilt(index: int) -> float:
	return sin(float(index) * 7.77 + 0.4) * UnoDeck.SPREAD_TILT


func _pile_rect(slot: int) -> Rect2:
	return Rect2(UnoDeck.PILE_FIRST + Vector2(UnoDeck.PILE_STEP * float(slot), 0.0),
		UnoDeck.CARD_SIZE)


# --- Dibujo -------------------------------------------------------------------

func _draw() -> void:
	DrawKit.gradient_rect(self, Rect2(Vector2.ZERO, size),
		UnoDeck.DESK_TOP, UnoDeck.DESK_BOTTOM)
	_draw_title()
	_draw_piles()
	_draw_spread()
	if _dragging >= 0:
		UnoCard.draw_card(self, Rect2(_drag_at, UnoDeck.CARD_SIZE),
			_model.cards[_dragging], 0.0, true)


func _draw_title() -> void:
	var font: Font = Fonts.terminal()
	draw_string(font, Vector2(UnoDeck.SPREAD.position.x, 40.0), TITLE,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, Color(0.78, 0.76, 0.7))
	var count: String = "%d de %d acomodadas" % [_model.placed_count(), UnoDeck.TOTAL]
	draw_string(font, Vector2(UnoDeck.SPREAD.position.x, 68.0), count,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(0.62, 0.6, 0.55))


## Los cuatro montones. El hueco vacío es un marco punteado del color que le
## toca, para que se vea de lejos dónde va cada palo.
func _draw_piles() -> void:
	for slot: int in UnoDeck.COLORS.size():
		var color: int = UnoDeck.color_at(slot)
		var rect: Rect2 = _pile_rect(slot)
		var count: int = int(_model.piles.get(color, 0))
		var tint: Color = UnoDeck.ink(color)
		if slot == _hover_pile:
			DrawKit.glow(self, rect.get_center(), UnoDeck.CARD_SIZE.x, tint, 0.5)
		draw_rect(rect, UnoDeck.SLOT_EMPTY, false, 2.0)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), tint)
		for number: int in count:
			var at: Rect2 = Rect2(rect.position + Vector2(0.0,
				float(number) * UnoDeck.PILE_OVERLAP), UnoDeck.CARD_SIZE)
			UnoCard.draw_card(self, at, {"color": color, "number": number}, 0.0, false)
		var label: String = "%s %d/%d" % [UnoDeck.NAMES[color], count, UnoDeck.PER_COLOR]
		var bottom: float = rect.end.y + float(maxi(count - 1, 0)) * UnoDeck.PILE_OVERLAP
		draw_string(Fonts.terminal(), Vector2(rect.position.x, bottom + 26.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, tint)


## El revoltijo: las que todavía no están puestas, cada una en su casilla y
## un poco chueca. La que se trae en la mano no se dibuja aquí.
func _draw_spread() -> void:
	for i: int in _model.cards.size():
		if i == _dragging or _model.is_placed(_model.cards[i]):
			continue
		var at: Vector2 = _spread_at(i)
		if i == _returning:
			# La que se regresa sola: va interpolando de donde la soltaste.
			var t: float = 1.0 - _return_left / UnoDeck.RETURN_TIME
			at = _return_from.lerp(at, clampf(t, 0.0, 1.0))
		UnoCard.draw_card(self, Rect2(at, UnoDeck.CARD_SIZE), _model.cards[i],
			_spread_tilt(i), false)


func _build_save_button() -> void:
	_save_button = UiButton.make(SAVE_TEXT)
	# Arriba de la barra de cámaras, que ocupa el bajo centro de la pantalla:
	# puesto en la esquina de abajo el botón le quedaba debajo.
	_save_button.custom_minimum_size = SAVE_SIZE
	_save_button.add_theme_font_size_override("font_size", 22)
	_save_button.position = SAVE_AT
	_save_button.size = SAVE_SIZE
	_save_button.pressed.connect(_on_save_pressed)
	add_child(_save_button)

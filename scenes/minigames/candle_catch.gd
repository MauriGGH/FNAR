class_name CandleCatch
extends Control

## El minijuego de la maquinita: atrapar velitas con una canasta, esquivando
## calaveras. Treinta segundos para juntar diez. Si se gana, el tótem.
##
## Todo está dibujado por código con cuadros grandes y filtro nearest, para que
## se vea pixel art: no hay arte que cargar. Los números de diseño (el tiempo,
## cuántas velitas) están en `data/sergio.gd`.
##
## Una calavera no mata: **resta una velita** de las que llevas. Así esquivar
## importa, pero un roce no te manda al principio.

## Se acabó. `won` dice si juntó las diez.
signal finished(won: bool)

## El lienzo del juego, en píxeles de diseño. Se escala al hueco que le toque.
const BOARD: Vector2 = Vector2(320.0, 180.0)
const PIXEL: float = 4.0

## La canasta: lo que mide y lo rápido que sigue al mouse.
const BASKET: Vector2 = Vector2(44.0, 14.0)
const BASKET_Y: float = 158.0
const BASKET_SPEED: float = 9.0

## Lo que cae: cada cuánto, a qué velocidad y de qué tamaño.
const DROP_GAP_MIN: float = 0.45
const DROP_GAP_MAX: float = 0.9
const DROP_SPEED_MIN: float = 52.0
const DROP_SPEED_MAX: float = 86.0
const CANDLE: Vector2 = Vector2(10.0, 18.0)
const SKULL: Vector2 = Vector2(16.0, 14.0)
## Una de cada tantas cosas que caen es calavera.
const SKULL_ONE_IN: int = 3

const BACK: Color = Color(0.06, 0.05, 0.09)
const FRAME: Color = Color(0.35, 0.3, 0.45)
const BASKET_COLOR: Color = Color(0.62, 0.42, 0.2)
const BASKET_EDGE: Color = Color(0.82, 0.6, 0.32)
const WAX: Color = Color(0.95, 0.93, 0.82)
const FLAME: Color = Color(1.0, 0.76, 0.25)
const BONE: Color = Color(0.88, 0.88, 0.84)
const HUD_TEXT: Color = Color(0.9, 0.92, 0.95)
const WIN_TEXT: Color = Color(0.55, 0.95, 0.5)
const LOSE_TEXT: Color = Color(0.95, 0.5, 0.45)
const FONT_SIZE: int = 14
## Lo que se queda el cartel del final antes de cerrarse.
const END_HOLD: float = 1.6

var is_playing: bool = false

var _left: float = Sergio.GAME_TIME
var _caught: int = 0
var _basket_x: float = BOARD.x * 0.5
var _next_drop: float = 0.0
var _drops: Array[Dictionary] = []
var _end_left: float = 0.0
var _won: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false
	set_process(false)


func play() -> void:
	if is_playing:
		return
	is_playing = true
	visible = true
	_left = Sergio.GAME_TIME
	_caught = 0
	_basket_x = BOARD.x * 0.5
	_next_drop = 0.3
	_end_left = 0.0
	_won = false
	_drops.clear()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	# El cartel del final: ya no se juega, solo se espera.
	if _end_left > 0.0:
		_end_left -= delta
		if _end_left <= 0.0:
			_close()
		queue_redraw()
		return
	_left -= delta
	_move_basket(delta)
	_spawn(delta)
	_fall(delta)
	if _caught >= Sergio.GAME_TARGET:
		_end(true)
	elif _left <= 0.0:
		_end(false)
	queue_redraw()


## La canasta sigue al mouse, con un poco de retraso para que se sienta.
func _move_basket(delta: float) -> void:
	var board: Rect2 = _board_rect()
	if board.size.x <= 0.0:
		return
	var local: float = (get_local_mouse_position().x - board.position.x) \
		/ board.size.x * BOARD.x
	var wanted: float = clampf(local, BASKET.x * 0.5, BOARD.x - BASKET.x * 0.5)
	_basket_x = lerpf(_basket_x, wanted, clampf(delta * BASKET_SPEED, 0.0, 1.0))


func _spawn(delta: float) -> void:
	_next_drop -= delta
	if _next_drop > 0.0:
		return
	_next_drop = randf_range(DROP_GAP_MIN, DROP_GAP_MAX)
	var skull: bool = randi() % SKULL_ONE_IN == 0
	var box: Vector2 = SKULL if skull else CANDLE
	_drops.append({
		"skull": skull,
		"at": Vector2(randf_range(box.x, BOARD.x - box.x), -box.y),
		"speed": randf_range(DROP_SPEED_MIN, DROP_SPEED_MAX),
	})


## Las cosas caen y se miran contra la canasta. Lo que la pasa se tira.
func _fall(delta: float) -> void:
	var basket: Rect2 = Rect2(Vector2(_basket_x - BASKET.x * 0.5, BASKET_Y), BASKET)
	var alive: Array[Dictionary] = []
	for drop: Dictionary in _drops:
		var at: Vector2 = drop["at"]
		at.y += float(drop["speed"]) * delta
		drop["at"] = at
		var box: Vector2 = SKULL if bool(drop["skull"]) else CANDLE
		var rect: Rect2 = Rect2(at - Vector2(box.x * 0.5, 0.0), box)
		if rect.intersects(basket):
			if bool(drop["skull"]):
				# Una calavera cuesta una velita, nunca baja de cero.
				_caught = maxi(_caught - 1, 0)
			else:
				_caught += 1
			continue
		if at.y <= BOARD.y:
			alive.append(drop)
	_drops = alive


func _end(won: bool) -> void:
	_won = won
	_end_left = END_HOLD
	_drops.clear()
	if won:
		GameManager.give_totem()
		AudioManager.play(Sounds.AURA)


func _close() -> void:
	is_playing = false
	visible = false
	set_process(false)
	finished.emit(_won)


## Se puede salir antes con Escape: cuenta como perdida.
func _input(event: InputEvent) -> void:
	if not is_playing:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		_won = false
		_close()
		get_viewport().set_input_as_handled()


# --- Dibujo -------------------------------------------------------------------

## El lienzo, centrado y lo más grande que quepa en pasos enteros, que es lo
## que mantiene los pixeles cuadrados.
func _board_rect() -> Rect2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Rect2()
	var scale: float = floorf(minf(size.x / BOARD.x, size.y / BOARD.y))
	scale = maxf(scale, 1.0)
	var drawn: Vector2 = BOARD * scale
	return Rect2((size - drawn) * 0.5, drawn)


func _to_screen(board: Rect2, at: Vector2) -> Vector2:
	return board.position + at / BOARD * board.size


func _box(board: Rect2, at: Vector2, box: Vector2, color: Color) -> void:
	var scale: Vector2 = board.size / BOARD
	draw_rect(Rect2(_to_screen(board, at), box * scale), color)


func _draw() -> void:
	var board: Rect2 = _board_rect()
	if board.size.x <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.88))
	draw_rect(board, BACK)
	draw_rect(board, FRAME, false, maxf(2.0, board.size.y / BOARD.y))

	# La canasta.
	var basket_at: Vector2 = Vector2(_basket_x - BASKET.x * 0.5, BASKET_Y)
	_box(board, basket_at, BASKET, BASKET_COLOR)
	_box(board, basket_at, Vector2(BASKET.x, 3.0), BASKET_EDGE)

	for drop: Dictionary in _drops:
		var at: Vector2 = drop["at"]
		if bool(drop["skull"]):
			_draw_skull(board, at)
		else:
			_draw_candle(board, at)

	_draw_hud(board)


## Una velita: cera y llama, en cuadros grandes.
func _draw_candle(board: Rect2, at: Vector2) -> void:
	var corner: Vector2 = at - Vector2(CANDLE.x * 0.5, 0.0)
	_box(board, corner + Vector2(0.0, 5.0), Vector2(CANDLE.x, CANDLE.y - 5.0), WAX)
	_box(board, corner + Vector2(3.0, 0.0), Vector2(4.0, 5.0), FLAME)


## Una calavera: el cráneo y dos huecos de ojos.
func _draw_skull(board: Rect2, at: Vector2) -> void:
	var corner: Vector2 = at - Vector2(SKULL.x * 0.5, 0.0)
	_box(board, corner, SKULL, BONE)
	_box(board, corner + Vector2(3.0, 4.0), Vector2(4.0, 4.0), BACK)
	_box(board, corner + Vector2(SKULL.x - 7.0, 4.0), Vector2(4.0, 4.0), BACK)
	_box(board, corner + Vector2(5.0, SKULL.y - 3.0), Vector2(6.0, 3.0), BACK)


## Lo que lleva y lo que le queda, arriba del lienzo, y el cartel del final.
func _draw_hud(board: Rect2) -> void:
	var font: Font = Fonts.terminal()
	if font == null:
		return
	var scale: float = board.size.y / BOARD.y
	var size_px: int = maxi(10, roundi(FONT_SIZE * scale))
	draw_string(font, board.position + Vector2(8.0 * scale, -6.0 * scale),
		"VELITAS %d/%d" % [_caught, Sergio.GAME_TARGET],
		HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, HUD_TEXT)
	draw_string(font, board.position + Vector2(board.size.x - 90.0 * scale, -6.0 * scale),
		"%02d s" % ceili(maxf(_left, 0.0)),
		HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, HUD_TEXT)
	if _end_left <= 0.0:
		return
	var text: String = "¡TÓTEM!" if _won else "SE ACABÓ"
	draw_string(font, board.get_center() - Vector2(60.0 * scale, 0.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size_px * 2, WIN_TEXT if _won else LOSE_TEXT)

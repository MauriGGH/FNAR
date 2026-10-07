extends Control

## El contador de destellos: cuando el cono de la linterna le está dando a uno
## de los del cristal, aparecen cuatro rayitas debajo del haz y se van llenando
## con cada destello que cuenta. Discreto a propósito: es una ayuda para
## entender la mecánica, no un HUD.

const TICK_SIZE: Vector2 = Vector2(16.0, 5.0)
const TICK_GAP: float = 6.0
## Lo que baja el contador respecto del centro del haz.
const DROP: float = 0.09
const NAME_SIZE: int = 15
const DONE_COLOR: Color = Color(0.98, 0.85, 0.45)
const EMPTY_COLOR: Color = Color(0.85, 0.87, 0.9, 0.3)
const NAME_COLOR: Color = Color(0.9, 0.9, 0.86, 0.75)
## Lo que tarda en aparecer y en irse.
const FADE_SPEED: float = 10.0

var _label: String = ""
var _flashes: int = 0
var _total: int = 4
var _at: Vector2 = Vector2(0.5, 0.5)
var _amount: float = 0.0
var _target: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Lo que hay que enseñar: a quién se está alumbrando, cuántos destellos lleva
## y dónde está el haz. Con el nombre vacío se esconde.
func show_progress(label: String, flashes: int, total: int, at: Vector2) -> void:
	_label = label
	_flashes = flashes
	_total = maxi(total, 1)
	_at = at
	_target = 0.0 if label.is_empty() else 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if is_equal_approx(_amount, _target):
		return
	_amount = lerpf(_amount, _target, 1.0 - exp(-delta * FADE_SPEED))
	if absf(_amount - _target) < 0.004:
		_amount = _target
	queue_redraw()


func _draw() -> void:
	if _amount <= 0.01:
		return
	var width: float = float(_total) * TICK_SIZE.x + float(_total - 1) * TICK_GAP
	var center: Vector2 = Vector2(_at.x * size.x, (_at.y + DROP) * size.y)
	var left: float = center.x - width * 0.5
	for i: int in _total:
		var tick: Rect2 = Rect2(
			Vector2(left + float(i) * (TICK_SIZE.x + TICK_GAP), center.y), TICK_SIZE)
		var color: Color = DONE_COLOR if i < _flashes else EMPTY_COLOR
		draw_rect(tick, Color(color.r, color.g, color.b, color.a * _amount))

	if _label.is_empty():
		return
	var font: Font = Fonts.terminal()
	if font == null:
		return
	var text: String = "%s  %d/%d" % [_label, _flashes, _total]
	var text_width: float = font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
	var at: Vector2 = Vector2(center.x - text_width * 0.5, center.y - 8.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_SIZE,
		4, Color(0.0, 0.0, 0.0, 0.8 * _amount))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_SIZE,
		Color(NAME_COLOR.r, NAME_COLOR.g, NAME_COLOR.b, NAME_COLOR.a * _amount))

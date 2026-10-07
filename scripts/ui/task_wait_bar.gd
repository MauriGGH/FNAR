class_name TaskWaitBar
extends Control

## El paso que tarda de una tarea, con su barra. La barra SOLO avanza
## mientras la PC está arriba: al bajarla se pausa y se queda esperando.
## Ese es el dilema del juego, quedarse en la PC o vigilar la oficina.
##
## La usan las diez tareas: cuando su parte "de hacer" ya está lista,
## arrancan la espera y solo al acabarse se dan por terminadas.

signal finished()

const HEIGHT: float = 44.0
const BAR_HEIGHT: float = 14.0
const LABEL_SIZE: int = 15
const BACK: Color = Color(0.08, 0.1, 0.12, 0.85)
const FILL: Color = Color(0.4, 0.78, 0.86)
const FILL_PAUSED: Color = Color(0.55, 0.5, 0.3)
const BORDER: Color = Color(0.6, 0.66, 0.7, 0.7)
const TEXT: Color = Color(0.85, 0.9, 0.92)
const PAUSED_TEXT: Color = Color(0.95, 0.83, 0.4)
const PAUSED_SUFFIX: String = "  (en pausa: la PC esta abajo)"

var is_running: bool = false
var is_done: bool = false

var _total: float = 0.0
var _left: float = 0.0
var _text: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, HEIGHT)
	visible = false


## Arranca la espera. Los segundos salen de Nights.wait_seconds(noche), así
## que se alargan solos en las noches altas.
func start(text: String, seconds: float = -1.0) -> void:
	if is_done or is_running:
		return
	_text = text
	_total = seconds if seconds > 0.0 else Nights.wait_seconds(GameManager.current_night)
	_left = _total
	is_running = true
	visible = true
	queue_redraw()


## De 0 a 1, lo que lleva hecho.
func progress() -> float:
	if _total <= 0.0:
		return 0.0
	return clampf(1.0 - _left / _total, 0.0, 1.0)


func _process(delta: float) -> void:
	if not is_running:
		return
	# Con la PC abajo el proceso se queda esperando.
	if not PowerManager.is_pc_open:
		queue_redraw()
		return
	_left -= delta
	queue_redraw()
	if _left > 0.0:
		return
	is_running = false
	is_done = true
	finished.emit()


func _draw() -> void:
	var paused: bool = is_running and not PowerManager.is_pc_open
	var font: Font = get_theme_default_font()
	var label: String = _text
	if is_done:
		label = "%s  listo" % _text
	elif paused:
		label += PAUSED_SUFFIX
	else:
		label += "  %d %%" % roundi(progress() * 100.0)
	draw_string(font, Vector2(0.0, LABEL_SIZE + 2.0), label, HORIZONTAL_ALIGNMENT_LEFT,
		size.x, LABEL_SIZE, PAUSED_TEXT if paused else TEXT)

	var bar: Rect2 = Rect2(Vector2(0.0, HEIGHT - BAR_HEIGHT), Vector2(size.x, BAR_HEIGHT))
	draw_rect(bar, BACK)
	var fill: Rect2 = Rect2(bar.position, Vector2(bar.size.x * progress(), bar.size.y))
	draw_rect(fill, FILL_PAUSED if paused else FILL)
	DrawKit.soft_outline(self, bar, BORDER)

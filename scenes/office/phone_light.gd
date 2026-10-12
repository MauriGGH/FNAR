extends Control

## Lo que hace el teléfono de la oficina cuando suena: enciende el LED y la
## pantallita que ya trae la foto, y los sacude un poco con cada timbrazo.
##
## **Solo suma luz, nunca pinta encima.** Antes también repintaba un pedazo de
## la foto corrido, para que el teléfono entero temblara; pero esa foto es la
## del pasillo **a oscuras**, así que con la linterna encendida dejaba un
## cuadrado negro alrededor del teléfono, tapando la foto iluminada. Lo que
## tiembla ahora es la luz, que es lo único que se nota.
##
## El nodo cubre todo el contenido de la vista central, así que las posiciones
## son las mismas normalizadas de las zonas y escalan junto con la vista.

## El foquito, a la derecha del teclado.
const LED_POINT: Vector2 = Vector2(0.6197, 0.75)
## La pantallita LCD.
const LCD_RECT: Rect2 = Rect2(0.572, 0.716, 0.053, 0.0234)

## Los radios están pensados a esta anchura de contenido; con otra resolución
## se escalan solos para que el foquito se vea igual de grande.
const REFERENCE_WIDTH: float = 1360.0
const LED_RADIUS_MIN: float = 6.0
const LED_RADIUS_MAX: float = 10.0

const LED_COLOR: Color = Color(1.0, 0.26, 0.14)      # rojo ámbar
const LCD_COLOR: Color = Color(0.56, 0.85, 0.42)     # verde ámbar

## Brillo de la pantallita: de fondo mientras suena, en el pico del timbrazo,
## y fijo durante la llamada.
const LCD_IDLE: float = 0.22
const LCD_RING: float = 0.85
const LCD_IN_CALL: float = 0.3

## Cada timbrazo son dos golpes cortos, como un teléfono de oficina.
const PULSE_TIME: float = 0.6
const PULSE_SECOND: float = 0.32
const PULSE_WIDTH: float = 0.24

## El temblor del teléfono: muy ligero y rápido.
const SHAKE_PIXELS: float = 2.0
const SHAKE_SPEED_X: float = 74.0
const SHAKE_SPEED_Y: float = 53.0
var is_ringing: bool = false
var is_in_call: bool = false

var _pulse_elapsed: float = PULSE_TIME
var _glow: Control = null


func _ready() -> void:
	# El resplandor va en un hijo con mezcla aditiva: así solo suma luz sobre
	# la foto, sin tapar nada ni dejar borde.
	var material: CanvasItemMaterial = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow = Control.new()
	_glow.name = "Glow"
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.material = material
	add_child(_glow)
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.draw.connect(_draw_glow)
	resized.connect(_refresh)


func set_ringing(ringing: bool) -> void:
	if is_ringing == ringing:
		return
	is_ringing = ringing
	if ringing:
		_pulse_elapsed = 0.0
	_refresh()


func set_in_call(in_call: bool) -> void:
	if is_in_call == in_call:
		return
	is_in_call = in_call
	_refresh()


## Un timbrazo: reinicia el parpadeo y el temblor.
func pulse() -> void:
	_pulse_elapsed = 0.0


func _process(delta: float) -> void:
	if not is_ringing:
		return
	_pulse_elapsed += delta
	queue_redraw()
	if _glow != null:
		_glow.queue_redraw()


func _refresh() -> void:
	visible = is_ringing or is_in_call
	if _glow != null:
		_glow.queue_redraw()
	queue_redraw()


# --- Dibujo -------------------------------------------------------------------

## Capa aditiva: el foquito y la pantallita encendidos.
func _draw_glow() -> void:
	var offset: Vector2 = _shake_offset()
	var scale: float = size.x / REFERENCE_WIDTH
	var pulse: float = _pulse() if is_ringing else 0.0

	if is_ringing:
		var radius: float = lerpf(LED_RADIUS_MIN, LED_RADIUS_MAX, pulse) * scale
		DrawKit.glow(_glow, LED_POINT * size + offset, radius, LED_COLOR, 0.12 + pulse * 0.88)

	var lcd: Rect2 = Rect2(LCD_RECT.position * size, LCD_RECT.size * size)
	lcd.position += offset
	var brightness: float = LCD_IN_CALL
	if is_ringing:
		brightness = lerpf(LCD_IDLE, LCD_RING, pulse)
	DrawKit.glow_rect(_glow, lcd, LCD_COLOR, brightness)


## Envolvente del timbrazo: dos golpes suaves y después nada hasta el siguiente.
func _pulse() -> float:
	var first: float = _bump(_pulse_elapsed / PULSE_WIDTH)
	var second: float = _bump((_pulse_elapsed - PULSE_SECOND) / PULSE_WIDTH)
	return clampf(maxf(first, second), 0.0, 1.0)


func _bump(t: float) -> float:
	if t <= 0.0 or t >= 1.0:
		return 0.0
	return sin(t * PI)


func _shake_offset() -> Vector2:
	if not is_ringing:
		return Vector2.ZERO
	var amount: float = _pulse() * SHAKE_PIXELS * (size.x / REFERENCE_WIDTH)
	if amount < 0.05:
		return Vector2.ZERO
	return Vector2(sin(_pulse_elapsed * SHAKE_SPEED_X), sin(_pulse_elapsed * SHAKE_SPEED_Y) * 0.6) * amount

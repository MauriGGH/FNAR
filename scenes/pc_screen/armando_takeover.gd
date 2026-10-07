extends Control

## Armando Prompts tomando la pantalla de la PC. Pone de fondo la carta de
## ajuste de assets/art/pc/armando_standby, le escribe una de sus frases
## dentro del círculo central y abajo, sobre las franjas oscuras, pide
## escribir "YA BÁJALE" contra reloj.
##
## Si el jugador lo escribe a tiempo, se va; si no, avisa que falló y la PC se
## encarga del castigo. Sin la imagen de fondo se dibuja un recuadro con su
## nombre, para que siga funcionando.

## Se logró escribir la frase a tiempo.
signal survived()
## Se acabó el tiempo: hay que borrar el progreso de la tarea y quitar energía.
signal failed()

const BACKGROUND_PATH: String = "res://assets/art/pc/armando_standby"

## El círculo central de la carta de ajuste, medido sobre la imagen: el centro
## en fracción del ancho y del alto, el radio en fracción del alto.
const CIRCLE_CENTER: Vector2 = Vector2(0.5, 0.469)
const CIRCLE_RADIUS: float = 0.306
## Lo que se aprovecha del círculo para la frase, para que no toque el borde.
const CIRCLE_TEXT_FILL: float = 0.84

## De aquí hacia abajo están las franjas oscuras de la carta: ahí va lo que se
## escribe y la cuenta regresiva. Solo se usa para comprobar que todo cae
## dentro de la franja; el acomodo real va desde el borde de abajo.
const INPUT_TOP: float = 0.775

# Medidas del bloque de abajo, contadas desde el borde inferior.
const BAR_BOTTOM: float = 22.0
const BAR_THICK: float = 8.0
const TIMER_GAP: float = 12.0
const FIELD_HEIGHT: float = 52.0
const ORDER_GAP: float = 14.0

## Velocidad con la que se escribe su frase, en letras por segundo.
const TYPE_SPEED: float = 34.0

# Tamaños de letra de la frase: se prueba de mayor a menor hasta que quepa.
const PHRASE_SIZE_MAX: int = 34
const PHRASE_SIZE_MIN: int = 14
const PHRASE_OUTLINE: int = 10
const ORDER_SIZE: int = 30
const TYPED_SIZE: int = 38
const TIMER_SIZE: int = 24
const NAME_SIZE: int = 44

const PHRASE_COLOR: Color = Color(1.0, 1.0, 1.0)
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.95)
const ORDER_COLOR: Color = Color(1.0, 0.76, 0.3)
const TYPED_OK: Color = Color(0.6, 1.0, 0.65)
const TYPED_BAD: Color = Color(1.0, 0.45, 0.4)
const BAR_BACK: Color = Color(0.0, 0.0, 0.0, 0.55)
const CARET_COLOR: Color = Color(1.0, 1.0, 1.0, 0.8)
const BACKDROP: Color = Color(0.06, 0.03, 0.02, 0.96)
const PLACEHOLDER_TOP: Color = Color(0.4, 0.17, 0.12)
const PLACEHOLDER_BOTTOM: Color = Color(0.18, 0.07, 0.05)

## El temblor de tele mal sintonizada: siempre un poquito.
const SHAKE_PIXELS: float = 2.2
const SHAKE_SPEED_X: float = 23.0
const SHAKE_SPEED_Y: float = 17.0

# Parpadeos de estática: cada tanto, unas bandas claras muy cortas.
const STATIC_MIN_WAIT: float = 0.6
const STATIC_MAX_WAIT: float = 2.2
const STATIC_TIME: float = 0.14
const STATIC_BANDS: int = 14
const STATIC_COLOR: Color = Color(1.0, 1.0, 1.0, 0.16)
## Lo que se corre la imagen a los lados durante el parpadeo.
const STATIC_SLIP: float = 9.0

var is_active: bool = false

var _phrase: String = ""
var _typed_chars: float = 0.0
var _time_left: float = 0.0
var _answer: String = ""
var _texture: Texture2D = null
var _target: String = ""
var _elapsed: float = 0.0
var _static_left: float = 0.0
var _static_wait: float = 0.0
var _slip: float = 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # No deja clicar el escritorio.
	_texture = GameAssets.load_texture(BACKGROUND_PATH)
	_target = _normalize(ArmandoPrompts.TAKEOVER_ANSWER)


## Lo llama la PC cuando Armando gana el dado. phrase es la frase al azar.
func play(phrase: String) -> void:
	_phrase = phrase.to_upper()
	_typed_chars = 0.0
	_time_left = ArmandoPrompts.TAKEOVER_TIME
	_answer = ""
	_elapsed = 0.0
	_static_left = 0.0
	_static_wait = randf_range(STATIC_MIN_WAIT, STATIC_MAX_WAIT)
	_slip = 0.0
	is_active = true
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if not is_active:
		return
	_elapsed += delta
	_typed_chars = minf(_typed_chars + TYPE_SPEED * delta, float(_phrase.length()))
	_time_left -= delta
	_process_static(delta)
	queue_redraw()
	if _time_left <= 0.0:
		_finish(false)


## Los parpadeos no son constantes: se esperan unos segundos y pegan corto.
func _process_static(delta: float) -> void:
	if _static_left > 0.0:
		_static_left -= delta
		return
	_static_wait -= delta
	if _static_wait > 0.0:
		return
	_static_left = STATIC_TIME
	_static_wait = randf_range(STATIC_MIN_WAIT, STATIC_MAX_WAIT)
	_slip = randf_range(-STATIC_SLIP, STATIC_SLIP)


## Se escribe con el teclado, sin importar mayúsculas ni acentos.
func _input(event: InputEvent) -> void:
	if not is_active:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	get_viewport().set_input_as_handled()
	if key.keycode == KEY_BACKSPACE:
		_answer = _answer.substr(0, maxi(_answer.length() - 1, 0))
		return
	var letter: String = char(key.unicode)
	if letter.is_empty() or key.unicode < 32:
		return
	_answer += letter
	if _normalize(_answer) == _target:
		_finish(true)


func _finish(ok: bool) -> void:
	is_active = false
	visible = false
	if ok:
		survived.emit()
	else:
		failed.emit()


## Para comparar: sin mayúsculas, sin acentos y sin espacios de sobra.
func _normalize(text: String) -> String:
	var plain: String = text.to_upper().strip_edges()
	for pair: Array in [["Á", "A"], ["É", "E"], ["Í", "I"], ["Ó", "O"], ["Ú", "U"], ["Ü", "U"], ["Ñ", "N"]]:
		plain = plain.replace(str(pair[0]), str(pair[1]))
	# Un espacio donde haya varios, para que "YA  BAJALE" también valga.
	while plain.contains("  "):
		plain = plain.replace("  ", " ")
	return plain


# --- Dibujo -------------------------------------------------------------------

func _draw() -> void:
	# Todo se dibuja corrido: el temblor de tele mal sintonizada.
	draw_set_transform(_shake_offset(), 0.0, Vector2.ONE)
	_draw_background()
	_draw_phrase()
	_draw_input()
	_draw_static()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _shake_offset() -> Vector2:
	var jitter: Vector2 = Vector2(
		sin(_elapsed * SHAKE_SPEED_X), sin(_elapsed * SHAKE_SPEED_Y) * 0.7) * SHAKE_PIXELS
	# Durante el parpadeo, además se va de lado.
	if _static_left > 0.0:
		jitter.x += _slip
	return jitter


func _draw_background() -> void:
	# Un poco más grande que la pantalla: con el temblor no se ven los bordes.
	var rect: Rect2 = Rect2(Vector2.ZERO, size).grow(SHAKE_PIXELS + STATIC_SLIP + 2.0)
	if _texture != null:
		draw_texture_rect(_texture, rect, false)
		return
	draw_rect(rect, BACKDROP)
	var box: Rect2 = Rect2(size * 0.5 - Vector2(size.y * 0.22, size.y * 0.22),
		Vector2(size.y * 0.44, size.y * 0.44))
	DrawKit.gradient_rect(self, box, PLACEHOLDER_TOP, PLACEHOLDER_BOTTOM)
	DrawKit.soft_outline(self, box, ORDER_COLOR)
	_draw_centered_lines(box.get_center(), "ARMANDO\nPROMPTS", NAME_SIZE)


## La frase dentro del círculo central, en el tamaño más grande que quepa.
func _draw_phrase() -> void:
	var font: Font = get_theme_default_font()
	var center: Vector2 = Vector2(CIRCLE_CENTER.x * size.x, CIRCLE_CENTER.y * size.y)
	var radius: float = CIRCLE_RADIUS * size.y
	# El cuadrado inscrito en el círculo: lo que de verdad se puede usar.
	var box: float = radius * sqrt(2.0) * CIRCLE_TEXT_FILL
	var shown: String = _phrase.substr(0, int(_typed_chars))
	if shown.is_empty():
		return

	var font_size: int = PHRASE_SIZE_MAX
	# Se mide la frase completa, no la que va escrita, para que el tamaño no
	# cambie mientras se escribe.
	while font_size > PHRASE_SIZE_MIN:
		var measured: Vector2 = font.get_multiline_string_size(
			_phrase, HORIZONTAL_ALIGNMENT_CENTER, box, font_size)
		if measured.y <= box:
			break
		font_size -= 2

	var height: float = font.get_multiline_string_size(
		_phrase, HORIZONTAL_ALIGNMENT_CENTER, box, font_size).y
	var origin: Vector2 = Vector2(center.x - box * 0.5, center.y - height * 0.5 + font_size)
	draw_multiline_string_outline(font, origin, shown, HORIZONTAL_ALIGNMENT_CENTER,
		box, font_size, -1, PHRASE_OUTLINE, OUTLINE_COLOR)
	draw_multiline_string(font, origin, shown, HORIZONTAL_ALIGNMENT_CENTER,
		box, font_size, -1, PHRASE_COLOR)


## Lo de abajo: la orden, lo que va escrito y la cuenta regresiva. Todo se
## acomoda desde el borde inferior hacia arriba, así cabe en la franja oscura
## de la carta de ajuste sea cual sea el tamaño de la pantalla.
func _draw_input() -> void:
	var font: Font = get_theme_default_font()
	var bar: Rect2 = Rect2(Vector2(size.x * 0.28, size.y - BAR_BOTTOM - BAR_THICK),
		Vector2(size.x * 0.44, BAR_THICK))
	var timer_y: float = bar.position.y - TIMER_GAP
	var field: Rect2 = Rect2(Vector2(size.x * 0.28, timer_y - TIMER_SIZE - FIELD_HEIGHT),
		Vector2(size.x * 0.44, FIELD_HEIGHT))
	var order_y: float = field.position.y - ORDER_GAP

	_draw_outlined(font, Vector2(size.x * 0.5, order_y),
		"ESCRIBE: " + ArmandoPrompts.TAKEOVER_ANSWER, ORDER_SIZE, ORDER_COLOR)

	# El recuadro donde se escribe, sobre la franja oscura.
	draw_rect(field, BAR_BACK)
	DrawKit.soft_outline(self, field, ORDER_COLOR)
	var matches: bool = _target.begins_with(_normalize(_answer))
	var typed_width: float = font.get_string_size(_answer, HORIZONTAL_ALIGNMENT_LEFT, -1, TYPED_SIZE).x
	var baseline: float = field.end.y - (field.size.y - float(TYPED_SIZE)) * 0.5
	_draw_outlined(font, Vector2(field.get_center().x, baseline), _answer, TYPED_SIZE,
		TYPED_OK if matches else TYPED_BAD)
	# El cursor parpadeando al final de lo escrito.
	if fmod(_elapsed, 0.8) < 0.45:
		draw_rect(Rect2(Vector2(field.get_center().x + typed_width * 0.5 + 4.0, field.position.y + 9.0),
			Vector2(3.0, field.size.y - 18.0)), CARET_COLOR)

	# La cuenta regresiva: los segundos y su barra.
	_draw_outlined(font, Vector2(size.x * 0.5, timer_y),
		"%.1f s" % maxf(_time_left, 0.0), TIMER_SIZE, ORDER_COLOR)
	var left: float = clampf(_time_left / ArmandoPrompts.TAKEOVER_TIME, 0.0, 1.0)
	draw_rect(bar, BAR_BACK)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * left, bar.size.y)), ORDER_COLOR)


## Las bandas del parpadeo de estática.
func _draw_static() -> void:
	if _static_left <= 0.0:
		return
	var fade: float = _static_left / STATIC_TIME
	for i: int in STATIC_BANDS:
		var y: float = fmod(_elapsed * 160.0 + float(i) * size.y / float(STATIC_BANDS), size.y)
		var band: Rect2 = Rect2(Vector2(-STATIC_SLIP, y), Vector2(size.x + STATIC_SLIP * 2.0, 2.0 + float(i % 3)))
		draw_rect(band, Color(STATIC_COLOR.r, STATIC_COLOR.g, STATIC_COLOR.b, STATIC_COLOR.a * fade))


func _draw_outlined(font: Font, center: Vector2, text: String, font_size: int, color: Color) -> void:
	if text.is_empty():
		return
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at: Vector2 = Vector2(center.x - width * 0.5, center.y)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size,
		PHRASE_OUTLINE, OUTLINE_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_centered_lines(center: Vector2, text: String, font_size: int) -> void:
	var font: Font = get_theme_default_font()
	var lines: PackedStringArray = text.split("\n")
	var line_height: float = float(font_size) * 1.1
	var top: float = center.y - line_height * (float(lines.size()) - 1.0) * 0.5
	for i: int in lines.size():
		_draw_outlined(font, Vector2(center.x, top + i * line_height), lines[i], font_size, PHRASE_COLOR)

extends Control

## Armando Prompts tomando la pantalla de la PC. Tapa todo el escritorio con
## su cara, una de sus frases escribiéndose sola y la orden de escribir
## "YA BÁJALE". Si el jugador lo escribe a tiempo, se va; si no, avisa que
## falló y la PC se encarga del castigo.
##
## Si existe assets/art/characters/armando_pc (cualquier extensión) se usa esa
## imagen; si no, un recuadro provisional con su nombre.

## Se logró escribir la frase a tiempo.
signal survived()
## Se acabó el tiempo: hay que borrar el progreso de la tarea y quitar energía.
signal failed()

const FACE_PATH: String = "res://assets/art/characters/armando_pc"

## Velocidad con la que se escribe su frase, en letras por segundo.
const TYPE_SPEED: float = 34.0

const BACKDROP: Color = Color(0.06, 0.03, 0.02, 0.96)
const PLACEHOLDER_TOP: Color = Color(0.4, 0.17, 0.12)
const PLACEHOLDER_BOTTOM: Color = Color(0.18, 0.07, 0.05)
const PHRASE_COLOR: Color = Color(1.0, 0.86, 0.72)
const ORDER_COLOR: Color = Color(1.0, 0.5, 0.28)
const TYPED_OK: Color = Color(0.55, 0.95, 0.6)
const TYPED_BAD: Color = Color(1.0, 0.45, 0.4)
const BAR_BACK: Color = Color(0.2, 0.1, 0.08)

const PHRASE_SIZE: int = 26
const ORDER_SIZE: int = 34
const TYPED_SIZE: int = 40
const NAME_SIZE: int = 44
## Márgenes del bloque de texto dentro de la pantalla.
const SIDE_MARGIN: float = 48.0
const BAR_HEIGHT: float = 10.0

var is_active: bool = false

var _phrase: String = ""
var _typed_chars: float = 0.0
var _time_left: float = 0.0
var _answer: String = ""
var _texture: Texture2D = null
var _target: String = ""


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # No deja clicar el escritorio.
	_texture = GameAssets.load_texture(FACE_PATH)
	_target = _normalize(ArmandoPrompts.TAKEOVER_ANSWER)


## Lo llama la PC cuando Armando gana el dado. phrase es la frase al azar.
func play(phrase: String) -> void:
	_phrase = phrase
	_typed_chars = 0.0
	_time_left = ArmandoPrompts.TAKEOVER_TIME
	_answer = ""
	is_active = true
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if not is_active:
		return
	_typed_chars = minf(_typed_chars + TYPE_SPEED * delta, float(_phrase.length()))
	_time_left -= delta
	queue_redraw()
	if _time_left <= 0.0:
		_finish(false)


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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	_draw_face()
	var font: Font = get_theme_default_font()
	var width: float = size.x - SIDE_MARGIN * 2.0

	# La frase, escribiéndose sola.
	draw_multiline_string(font, Vector2(SIDE_MARGIN, size.y * 0.12),
		_phrase.substr(0, int(_typed_chars)), HORIZONTAL_ALIGNMENT_CENTER, width,
		PHRASE_SIZE, -1, PHRASE_COLOR)

	# La orden y lo que el jugador va escribiendo.
	var order_y: float = size.y - 150.0
	draw_string(font, Vector2(SIDE_MARGIN, order_y),
		"ESCRIBE: " + ArmandoPrompts.TAKEOVER_ANSWER, HORIZONTAL_ALIGNMENT_CENTER,
		width, ORDER_SIZE, ORDER_COLOR)
	var matches: bool = _target.begins_with(_normalize(_answer))
	draw_string(font, Vector2(SIDE_MARGIN, order_y + 52.0), _answer,
		HORIZONTAL_ALIGNMENT_CENTER, width, TYPED_SIZE,
		TYPED_OK if matches else TYPED_BAD)

	# La barra del tiempo que queda.
	var bar: Rect2 = Rect2(Vector2(SIDE_MARGIN, order_y + 78.0), Vector2(width, BAR_HEIGHT))
	draw_rect(bar, BAR_BACK)
	var left: float = clampf(_time_left / ArmandoPrompts.TAKEOVER_TIME, 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * left, bar.size.y)), ORDER_COLOR)


## Su cara, o un recuadro con su nombre mientras no exista la imagen.
func _draw_face() -> void:
	var box: Rect2 = Rect2(Vector2(size.x * 0.5 - size.y * 0.22, size.y * 0.3),
		Vector2(size.y * 0.44, size.y * 0.44))
	if _texture != null:
		# Con imagen, la cara toma toda la pantalla, como pidió el diseño.
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
		return
	DrawKit.gradient_rect(self, box, PLACEHOLDER_TOP, PLACEHOLDER_BOTTOM)
	DrawKit.soft_outline(self, box, ORDER_COLOR)
	_draw_centered(get_theme_default_font(), box.get_center(), "ARMANDO\nPROMPTS", NAME_SIZE)


func _draw_centered(font: Font, center: Vector2, text: String, font_size: int) -> void:
	var lines: PackedStringArray = text.split("\n")
	var line_height: float = float(font_size) * 1.1
	var top: float = center.y - line_height * (float(lines.size()) - 1.0) * 0.5
	for i: int in lines.size():
		var width: float = font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2(center.x - width * 0.5, top + i * line_height),
			lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, PHRASE_COLOR)

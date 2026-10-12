extends Control

## El 6 AM, como en los juegos originales: negro con "5 AM" grande al centro, a
## máquina de escribir y en blanco; el 5 se va hacia arriba como un rodillo y
## entra el 6. El texto **no cambia de color**: lo único que se mueve es la
## hora. Suena el despertador (campanadas de reloj), que **ya trae el grito de
## los niños al final**, y el confeti cae en ese último tramo. Solo si no está
## grabado el despertador se pide aparte el `ninos_yay`. Al terminar avisa.

## Ya acabó: quien la abrió sigue con el recorte de periódico.
signal finished()

## Medidos a 1080p y escalados con el alto de la ventana.
const REFERENCE_HEIGHT: float = 1080.0
const DIGIT_SIZE: float = 190.0
const SUFFIX_TEXT: String = " AM"
const WHITE: Color = Color(1.0, 1.0, 1.0)

## El rodillo: lo que tarda el 5 en salir y el 6 en entrar.
const ROLL_TIME: float = 0.8
## Lo que dura el confeti, que es también lo que se queda quieto el 6.
const CONFETTI_TIME: float = 4.0
## Si el despertador no se puede medir, lo que se le supone antes de los niños.
const FALLBACK_ALARM_TIME: float = 2.5
## Lo que espera antes de empezar a girar, para que se lea el 5.
const READ_TIME: float = 0.7
const FADE_OUT: float = 0.4

## La ventanita por donde se ve el dígito, medida a 1080p. Alta de más para que
## el dígito entre y salga sin que se le corten los bordes.
const WINDOW_SIZE: Vector2 = Vector2(170.0, 240.0)

var _window: Control = null
var _old_digit: Label = null
var _new_digit: Label = null
var _suffix: Label = null
var _text_root: Control = null
var _confetti: ConfettiFall = null
## Lo que lleva corrido el rodillo, de 0 a 1, para recolocar sin romper el giro.
var _roll_progress: float = 0.0:
	set(value):
		_roll_progress = value
		_place_digits()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_layout()
	resized.connect(_layout)
	AudioManager.play(Sounds.ALARM)
	var alarm: float = AudioManager.length(Sounds.ALARM)
	if alarm <= 0.0:
		alarm = FALLBACK_ALARM_TIME
	# El confeti cae en el último tramo del despertador, que es donde está el
	# grito de los niños; la pantalla acaba cuando acaba el audio.
	var confetti_at: float = maxf(READ_TIME + ROLL_TIME, alarm - CONFETTI_TIME)
	var tween: Tween = create_tween()
	tween.tween_interval(READ_TIME)
	tween.tween_callback(_roll)
	tween.tween_interval(confetti_at - READ_TIME)
	tween.tween_callback(_cheer)
	tween.tween_interval(CONFETTI_TIME)
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(_done)


func _build() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	# Todo el texto junto, para teñirlo de dorado de una sola pasada.
	_text_root = Control.new()
	_text_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_root.modulate = WHITE
	add_child(_text_root)

	# La ventanita recorta, así que el dígito que sobra no se ve.
	_window = Control.new()
	_window.clip_contents = true
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_root.add_child(_window)

	_old_digit = _make_digit("5")
	_window.add_child(_old_digit)
	# El 6 espera justo debajo del hueco.
	_new_digit = _make_digit("6")
	_window.add_child(_new_digit)

	_suffix = _make_digit(SUFFIX_TEXT)
	_suffix.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_root.add_child(_suffix)

	# El confeti va encima del reloj.
	_confetti = ConfettiFall.new()
	add_child(_confetti)


## El reloj se recoloca con el tamaño de la ventana, sin tocar el rodillo.
func _layout() -> void:
	var scale: float = size.y / REFERENCE_HEIGHT
	var window: Vector2 = WINDOW_SIZE * scale
	var font_size: int = maxi(1, roundi(DIGIT_SIZE * scale))
	var suffix_width: float = _suffix_width(font_size)
	var block_left: float = (size.x - (window.x + suffix_width)) * 0.5
	var top: float = size.y * 0.5 - window.y * 0.5

	_window.position = Vector2(block_left, top)
	_window.size = window
	for digit: Label in [_old_digit, _new_digit]:
		Fonts.apply(digit, Fonts.typewriter(), font_size)
		digit.size = window
	_place_digits()

	Fonts.apply(_suffix, Fonts.typewriter(), font_size)
	_suffix.position = Vector2(block_left + window.x, top)
	_suffix.size = Vector2(suffix_width, window.y)


## Dónde van los dos dígitos según lo corrido que vaya el rodillo.
func _place_digits() -> void:
	if _window == null or _old_digit == null or _new_digit == null:
		return
	var travel: float = _window.size.y
	_old_digit.position = Vector2(0.0, -travel * _roll_progress)
	_new_digit.position = Vector2(0.0, travel * (1.0 - _roll_progress))


func _suffix_width(font_size: int) -> float:
	var font: Font = Fonts.typewriter()
	if font == null:
		return float(font_size) * 2.2
	return font.get_string_size(SUFFIX_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _make_digit(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", WHITE)
	return label


## Los dos dígitos suben a la vez: el 5 se va por arriba y el 6 ocupa su sitio.
## El color no se toca: la hora se queda blanca de principio a fin.
func _roll() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "_roll_progress", 1.0, ROLL_TIME)


## El confeti, ya con el 6 puesto. El grito de los niños solo se pide aparte
## si no hay despertador grabado: el de verdad ya lo trae al final.
func _cheer() -> void:
	if not AudioManager.has_real_file(Sounds.ALARM):
		AudioManager.stop(Sounds.ALARM)
		AudioManager.play(Sounds.CHILDREN_CHEER)
	_confetti.play(CONFETTI_TIME)


func _done() -> void:
	visible = false
	# El despertador son 10 s: si no se corta aquí, se cuela en el periódico,
	# en el recibo y hasta en la noche siguiente, encima del ambiente.
	AudioManager.stop(Sounds.ALARM)
	finished.emit()


## Y si la pantalla se va antes de tiempo, lo mismo.
func _exit_tree() -> void:
	AudioManager.stop(Sounds.ALARM)
	AudioManager.stop(Sounds.CHILDREN_CHEER)

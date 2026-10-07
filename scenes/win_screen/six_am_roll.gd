extends Control

## El 6 AM, como en los juegos originales: negro con "5 AM" grande al centro, el
## 5 se va hacia arriba como un rodillo y entra el 6, el texto pasa de blanco a
## dorado, suena el despertador y luego la campana de la escuela con aplausos.
## Al terminar avisa, y la pantalla de la noche superada enseña lo suyo.

## Ya acabó: la pantalla de atrás puede mostrar el resto.
signal finished()

const DIGIT_SIZE: int = 150
const SUFFIX_SIZE: int = 150
const SUFFIX_TEXT: String = " AM"
const WHITE: Color = Color(1.0, 1.0, 1.0)
const GOLD: Color = Color(0.98, 0.84, 0.35)

## El rodillo: lo que tarda el 5 en salir y el 6 en entrar.
const ROLL_TIME: float = 1.5
## Lo que se queda quieto antes de seguir.
const HOLD_TIME: float = 3.0
## Lo que espera antes de empezar a girar, para que se lea el 5.
const READ_TIME: float = 0.7
const FADE_OUT: float = 0.4

## La ventanita por donde se ve el dígito. Alta de más para que el dígito entre
## y salga sin que se le corten los bordes.
const WINDOW_SIZE: Vector2 = Vector2(110.0, 190.0)

var _window: Control = null
var _old_digit: Label = null
var _new_digit: Label = null
var _text_root: Control = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	AudioManager.play_loop(Sounds.ALARM)
	var tween: Tween = create_tween()
	tween.tween_interval(READ_TIME)
	# El rodillo y el color van juntos: el 6 entra ya dorándose.
	tween.tween_callback(_roll)
	tween.tween_interval(ROLL_TIME)
	tween.tween_callback(_ring_bell)
	tween.tween_interval(HOLD_TIME)
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

	var suffix_width: float = _suffix_width()
	var block_left: float = (size.x - (WINDOW_SIZE.x + suffix_width)) * 0.5
	var top: float = size.y * 0.5 - WINDOW_SIZE.y * 0.5

	# La ventanita recorta, así que el dígito que sobra no se ve.
	_window = Control.new()
	_window.clip_contents = true
	_window.position = Vector2(block_left, top)
	_window.size = WINDOW_SIZE
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_root.add_child(_window)

	_old_digit = _make_digit("5")
	_old_digit.position = Vector2.ZERO
	_window.add_child(_old_digit)

	# El 6 espera justo debajo del hueco.
	_new_digit = _make_digit("6")
	_new_digit.position = Vector2(0.0, WINDOW_SIZE.y)
	_window.add_child(_new_digit)

	var suffix: Label = Label.new()
	suffix.text = SUFFIX_TEXT
	suffix.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	suffix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	suffix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(suffix, Fonts.typewriter(), SUFFIX_SIZE)
	suffix.add_theme_color_override("font_color", WHITE)
	suffix.position = Vector2(block_left + WINDOW_SIZE.x, top)
	suffix.size = Vector2(suffix_width, WINDOW_SIZE.y)
	_text_root.add_child(suffix)


func _suffix_width() -> float:
	var font: Font = Fonts.typewriter()
	if font == null:
		return 180.0
	return font.get_string_size(SUFFIX_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, SUFFIX_SIZE).x


func _make_digit(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(label, Fonts.typewriter(), DIGIT_SIZE)
	label.add_theme_color_override("font_color", WHITE)
	label.size = WINDOW_SIZE
	return label


## Los dos dígitos suben a la vez: el 5 se va por arriba y el 6 ocupa su sitio.
func _roll() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_old_digit, "position:y", -WINDOW_SIZE.y, ROLL_TIME)
	tween.parallel().tween_property(_new_digit, "position:y", 0.0, ROLL_TIME)
	tween.parallel().tween_property(_text_root, "modulate", GOLD, ROLL_TIME)


## La campana de la escuela con aplausos, ya con el 6 puesto.
func _ring_bell() -> void:
	AudioManager.stop(Sounds.ALARM)
	AudioManager.play(Sounds.SCHOOL_BELL)


func _done() -> void:
	visible = false
	finished.emit()

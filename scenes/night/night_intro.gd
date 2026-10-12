extends Control

## La pantalla de antes de cada noche, como la de los juegos originales: negro
## pelón con "12:00 AM" al centro y la noche debajo, a máquina de escribir y en
## blanco.
## Un golpe corto de estática al aparecer y otro al irse. Se pasa sola.

const HOUR_TEXT: String = "12:00 AM"
## Medidos a 1080p y escalados con el alto de la ventana, como en el menú.
const REFERENCE_HEIGHT: float = 1080.0
const HOUR_SIZE: float = 96.0
const NIGHT_SIZE: float = 52.0
const TEXT_COLOR: Color = Color(1.0, 1.0, 1.0)

## Dónde caen los dos renglones, en fracción del alto.
const HOUR_TOP: float = 0.40
const NIGHT_TOP: float = 0.53

## Lo que tarda en aparecer, lo que se queda y lo que tarda en irse: unos 2.5 s
## en total contando los dos golpes.
const FADE_IN: float = 0.5
const HOLD: float = 1.2
const FADE_OUT: float = 0.5
## El golpe de estática: lo fuerte que pega y lo que dura.
const STATIC_IDLE: float = 0.0
const STATIC_HIT: float = 0.75
const HIT_TIME: float = 0.3

var _static_layer: StaticFrames = null
var _static_strength: float = STATIC_IDLE:
	set(value):
		_static_strength = value
		ScreenFx.set_static_strength(_static_layer, value)

var _fade: float = 0.0:
	set(value):
		_fade = value
		if _texts != null:
			_texts.modulate.a = value

var _texts: Control = null
var _hour: Label = null
var _night: Label = null


func _ready() -> void:
	# Los bucles de la pantalla anterior se cortan aquí: un ambiente colgado
	# es lo que se oye encima del nuevo.
	AudioManager.stop_all_loops()
	_build()
	# La estática va encima del texto, así que el texto se arma primero.
	_static_layer = ScreenFx.add_static(self, STATIC_IDLE)
	_layout()
	resized.connect(_layout)

	var tween: Tween = create_tween()
	# Entra con un golpe que se va cayendo mientras aparece el texto.
	tween.tween_callback(_hit_static)
	tween.parallel().tween_property(self, "_fade", 1.0, FADE_IN)
	tween.tween_interval(HOLD)
	# Y se va con otro golpe, ya con el texto apagándose.
	tween.tween_callback(_hit_static)
	tween.parallel().tween_property(self, "_fade", 0.0, FADE_OUT)
	tween.tween_callback(_start_night)


## Sube la estática de golpe y la deja caer sola en los 0.3 s.
func _hit_static() -> void:
	_static_strength = STATIC_HIT
	create_tween().tween_property(self, "_static_strength", STATIC_IDLE, HIT_TIME)


func _build() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	# Los dos textos en un solo nodo, para apagarlos juntos sin tocar el fondo.
	_texts = Control.new()
	_texts.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texts.modulate.a = 0.0
	add_child(_texts)

	_hour = _make_label(HOUR_TEXT)
	_texts.add_child(_hour)
	_night = _make_label(_night_text())
	_texts.add_child(_night)


## "1ª noche", "2ª noche"... y la Custom Night por su nombre.
func _night_text() -> String:
	if GameManager.is_custom_night:
		return "Custom Night"
	return "%dª noche" % GameManager.current_night


func _layout() -> void:
	if _hour != null:
		Fonts.apply(_hour, Fonts.typewriter(), _font_size(HOUR_SIZE))
		_hour.position = Vector2(0.0, size.y * HOUR_TOP)
		_hour.size = Vector2(size.x, size.y * 0.12)
	if _night != null:
		Fonts.apply(_night, Fonts.typewriter(), _font_size(NIGHT_SIZE))
		_night.position = Vector2(0.0, size.y * NIGHT_TOP)
		_night.size = Vector2(size.x, size.y * 0.08)


func _font_size(measured: float) -> int:
	return maxi(1, roundi(measured * size.y / REFERENCE_HEIGHT))


func _make_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", TEXT_COLOR)
	return label


func _start_night() -> void:
	get_tree().change_scene_to_file(Screens.NIGHT)

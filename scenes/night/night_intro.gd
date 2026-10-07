extends Control

## La pantalla de antes de cada noche: "12:00 AM" grande y "Noche N" debajo,
## sobre negro, como en los juegos originales. Escrita a máquina y con un golpe
## de estática al aparecer y otro al irse. Se pasa sola.

const HOUR_TEXT: String = "12:00 AM"
const HOUR_SIZE: int = 72
const NIGHT_SIZE: int = 40
const TEXT_COLOR: Color = Color(0.93, 0.93, 0.95)

## Lo que tarda en aparecer, lo que se queda y lo que tarda en irse: unos 2.5 s
## en total contando los dos golpes.
const FADE_IN: float = 0.5
const HOLD: float = 1.2
const FADE_OUT: float = 0.5
## El golpe de estática: lo fuerte que pega y lo que tarda en caer al reposo.
const STATIC_IDLE: float = 0.04
const STATIC_HIT: float = 0.55
const HIT_TIME: float = 0.28

var _static_layer: ColorRect = null
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


func _ready() -> void:
	_build()
	# La estática va encima del texto, así que el texto se arma primero.
	_static_layer = ScreenFx.add_static(self, STATIC_IDLE)

	var tween: Tween = create_tween()
	# Entra con un golpe que se va cayendo mientras aparece el texto.
	tween.tween_callback(_hit_static)
	tween.parallel().tween_property(self, "_fade", 1.0, FADE_IN)
	tween.tween_interval(HOLD)
	# Y se va con otro golpe, ya con el texto apagándose.
	tween.tween_callback(_hit_static)
	tween.parallel().tween_property(self, "_fade", 0.0, FADE_OUT)
	tween.tween_callback(_start_night)


## Sube la estática de golpe y la deja caer sola.
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

	var hour: Label = _make_label(HOUR_TEXT, HOUR_SIZE)
	hour.offset_top = size.y * 0.36
	hour.offset_bottom = hour.offset_top + 96.0
	_texts.add_child(hour)

	var night_text: String = "Custom Night" if GameManager.is_custom_night \
		else "Noche %d" % GameManager.current_night
	var night: Label = _make_label(night_text, NIGHT_SIZE)
	night.offset_top = size.y * 0.5
	night.offset_bottom = night.offset_top + 56.0
	_texts.add_child(night)


func _make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(label, Fonts.typewriter(), font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	return label


func _start_night() -> void:
	get_tree().change_scene_to_file(Screens.NIGHT)

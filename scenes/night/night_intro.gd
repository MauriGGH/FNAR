extends Control

## La pantalla de antes de cada noche: "12:00 AM" grande y "Noche N" debajo,
## sobre negro, como en los juegos originales. Se pasa sola.

const HOUR_TEXT: String = "12:00 AM"
const HOUR_SIZE: int = 72
const NIGHT_SIZE: int = 40
const TEXT_COLOR: Color = Color(0.93, 0.93, 0.95)
## Lo que tarda en aparecer, lo que se queda y lo que tarda en irse.
const FADE_IN: float = 0.5
const HOLD: float = 1.6
const FADE_OUT: float = 0.6

var _fade: float = 0.0:
	set(value):
		_fade = value
		modulate.a = value


func _ready() -> void:
	modulate.a = 0.0
	_build_labels()
	var tween: Tween = create_tween()
	tween.tween_property(self, "_fade", 1.0, FADE_IN)
	tween.tween_interval(HOLD)
	tween.tween_property(self, "_fade", 0.0, FADE_OUT)
	tween.tween_callback(_start_night)


func _build_labels() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var hour: Label = _make_label(HOUR_TEXT, HOUR_SIZE)
	hour.offset_top = size.y * 0.36
	hour.offset_bottom = hour.offset_top + 96.0
	add_child(hour)

	var night_text: String = "Custom Night" if GameManager.is_custom_night \
		else "Noche %d" % GameManager.current_night
	var night: Label = _make_label(night_text, NIGHT_SIZE)
	night.offset_top = size.y * 0.5
	night.offset_bottom = night.offset_top + 56.0
	add_child(night)


func _make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	return label


func _start_night() -> void:
	get_tree().change_scene_to_file(Screens.NIGHT)

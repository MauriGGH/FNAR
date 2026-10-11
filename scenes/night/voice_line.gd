extends Control

## Dice una línea suelta de profe y le pone su subtítulo pequeño: Barcosa
## aporreando la puerta, Mamador cuando no encuentra nada.
##
## Si la línea ya está grabada en `assets/audio/voces/<id>.ogg`, se reproduce y
## el subtítulo dura lo que el audio. Si no, la dice la síntesis de voz y el
## subtítulo dura lo que se calcula por el largo del texto. En los dos casos el
## texto se lee igual, así que la mecánica se entiende desde el primer día.
##
## Va encima de los subtítulos de la llamada, para que no se tapen: una llamada
## de teléfono y un profe gritando en la puerta pueden coincidir.

const FONT_SIZE: int = 19
const TEXT_COLOR: Color = Color(0.92, 0.9, 0.84)
const BACKDROP: Color = Color(0.0, 0.0, 0.02, 0.55)
const PADDING: Vector2 = Vector2(16.0, 6.0)
## Dónde se apoya, en fracción del alto. Más arriba que la barra de la llamada.
const BOTTOM_MARGIN: float = 0.175
const MAX_WIDTH: float = 0.56
const FADE_TIME: float = 0.2

## Lo que se calcula que tarda en decirse una línea con la voz sintética.
const SECONDS_PER_WORD: float = 0.42
const MIN_TIME: float = 1.5
const MAX_TIME: float = 6.0

## Voz de la síntesis para estas líneas: en español y algo grave.
const TTS_LANGUAGE: String = "es"
const TTS_PITCH: float = 0.9
const TTS_RATE: float = 1.0
const TTS_VOLUME: int = 60

var _left: float = 0.0
var _sound_id: String = ""
var _panel: PanelContainer = null
var _label: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false
	modulate.a = 0.0


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Backdrop"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = BACKDROP
	box.set_corner_radius_all(3)
	box.content_margin_left = PADDING.x
	box.content_margin_right = PADDING.x
	box.content_margin_top = PADDING.y
	box.content_margin_bottom = PADDING.y
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.max_lines_visible = 2
	Fonts.apply(_label, Fonts.terminal(), FONT_SIZE)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_panel.add_child(_label)


## Dice una línea por su id. Si el id no existe, no hace nada.
func say(line_id: String) -> void:
	var text: String = VoiceLines.text_of(line_id)
	if text.is_empty():
		return
	_label.text = text
	_sound_id = line_id
	_left = _play(line_id, text)
	visible = true
	_layout()
	create_tween().tween_property(self, "modulate:a", 1.0, FADE_TIME)


## Reproduce la grabación si existe; si no, la dice la voz sintética. Devuelve
## cuánto tiene que quedarse el subtítulo.
func _play(line_id: String, text: String) -> float:
	if AudioManager.has_real_file(line_id):
		AudioManager.play(line_id)
		return maxf(AudioManager.length(line_id), MIN_TIME)
	_speak(text)
	return clampf(float(text.split(" ").size()) * SECONDS_PER_WORD, MIN_TIME, MAX_TIME)


func _speak(text: String) -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(TTS_LANGUAGE)
	if voices.is_empty():
		return
	# El TTS no sale por los buses, así que el deslizador de Voces va aquí.
	var volume: int = roundi(float(TTS_VOLUME) * AudioManager.voice_volume())
	DisplayServer.tts_speak(text, voices[0], volume, TTS_PITCH, TTS_RATE)


## Corta lo que esté diciendo. Lo usa el fin de noche.
func stop() -> void:
	if _left <= 0.0:
		return
	_left = 0.0
	if not _sound_id.is_empty():
		AudioManager.stop(_sound_id)
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()
	_hide()


func is_saying() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	if _left <= 0.0:
		_hide()


func _hide() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(func() -> void: visible = false)


func _layout() -> void:
	if _panel == null:
		return
	var width: float = size.x * MAX_WIDTH
	_label.custom_minimum_size = Vector2(width - PADDING.x * 2.0, 0.0)
	_panel.size = Vector2(width, 0.0)
	_panel.position = Vector2((size.x - width) * 0.5,
		size.y * (1.0 - BOTTOM_MARGIN) - _panel.size.y)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()

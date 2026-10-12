extends Control

## Los subtítulos de la llamada grabada de la noche. Van abajo al centro, sobre
## un fondo semitransparente, en VT323 y como mucho dos líneas, con el botón de
## "Silenciar llamada" al lado, como en los juegos originales.
##
## No bloquea nada: solo el botón recibe clics, todo lo demás pasa de largo, así
## que se sigue jugando con la llamada puesta.
##
## El tiempo no se cuenta aquí: se lee la posición del audio, así que si el
## juego da un tirón los subtítulos se recolocan solos.

## La llamada acabó, se silenció o no había nada que poner.
signal finished()

const MUTE_TEXT: String = "Silenciar llamada"
const FONT_SIZE: int = 26
const TEXT_COLOR: Color = Color(0.94, 0.94, 0.9)
const BACKDROP: Color = Color(0.0, 0.0, 0.02, 0.62)
const MAX_LINES: int = 2

## Dónde se apoya la barra y cuánto ocupa, en fracción de la pantalla.
const BOTTOM_MARGIN: float = 0.055
const WIDTH: float = 0.62
## Alto de la caja de texto: dos líneas más el aire de arriba y abajo.
const PADDING: Vector2 = Vector2(22.0, 10.0)
## Lo que tarda en aparecer y en irse.
const FADE_TIME: float = 0.25

var is_playing: bool = false

var _sound_id: String = ""
var _lines: Array[Dictionary] = []
var _current: int = -1
var _length: float = 0.0

var _panel: PanelContainer = null
var _label: Label = null
var _mute: Button = null


func _ready() -> void:
	# Pasa los clics: solo el botón se los queda.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false
	modulate.a = 0.0


func _build() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	_panel = PanelContainer.new()
	_panel.name = "Backdrop"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = BACKDROP
	box.set_corner_radius_all(4)
	box.content_margin_left = PADDING.x
	box.content_margin_right = PADDING.x
	box.content_margin_top = PADDING.y
	box.content_margin_bottom = PADDING.y
	_panel.add_theme_stylebox_override("panel", box)
	column.add_child(_panel)

	_label = Label.new()
	_label.name = "Subtitle"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Más de dos líneas se recortan: una frase larga no debe tapar la oficina.
	_label.max_lines_visible = MAX_LINES
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Fonts.apply(_label, Fonts.terminal(), FONT_SIZE)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_panel.add_child(_label)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)

	_mute = UiButton.make(MUTE_TEXT)
	_mute.custom_minimum_size = Vector2(230.0, 38.0)
	_mute.add_theme_font_size_override("font_size", 16)
	_mute.pressed.connect(mute)
	row.add_child(_mute)


func _layout() -> void:
	var column: Control = get_node_or_null("Column") as Control
	if column == null:
		return
	var width: float = size.x * WIDTH
	column.size = Vector2(width, 0.0)
	column.position = Vector2((size.x - width) * 0.5, 0.0)
	# Se apoya en el borde de abajo: la columna crece hacia arriba.
	column.position.y = size.y * (1.0 - BOTTOM_MARGIN) - column.size.y
	if _label != null:
		_label.custom_minimum_size = Vector2(width - PADDING.x * 2.0, 0.0)


## Arranca la llamada de esa noche. Si no hay audio, no hace nada y avisa.
func play(night: int) -> void:
	play_call(NightCalls.sound_id(night), NightCalls.subtitles(night))


## Cualquier llamada grabada: su audio y sus subtítulos. La de la noche sale
## de arriba; la del Mencho le pasa los suyos, que son un solo renglón.
func play_call(sound_id: String, lines: Array[Dictionary]) -> void:
	_sound_id = sound_id
	if not AudioManager.has_real_file(_sound_id):
		finished.emit()
		return
	_lines = lines
	_length = AudioManager.length(_sound_id)
	_current = -1
	is_playing = true
	_label.text = ""
	visible = true
	_layout()
	AudioManager.play(_sound_id)
	create_tween().tween_property(self, "modulate:a", 1.0, FADE_TIME)


## Silenciar: corta el audio y quita los subtítulos. Lo llama el botón, y
## también se usa al acabar la noche.
func mute() -> void:
	if not is_playing:
		return
	is_playing = false
	AudioManager.stop(_sound_id)
	# El archivo de la llamada es solo voz: el clac de colgar lo pone el juego.
	AudioManager.play(Sounds.PHONE_HANG_UP)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(func() -> void: visible = false)
	finished.emit()


func _process(_delta: float) -> void:
	if not is_playing:
		return
	var at: float = AudioManager.playback_position(_sound_id)
	# El audio dejó de sonar: se acabó la llamada.
	if not AudioManager.is_playing(_sound_id) and at <= 0.0:
		mute()
		return
	if _length > 0.0 and at >= _length - 0.05:
		mute()
		return
	_show_line_for(at)


## La frase que toca es la última que ya empezó. Cada una se queda hasta que
## entra la siguiente, así que basta con comparar contra su segundo de inicio.
func _show_line_for(at: float) -> void:
	var wanted: int = -1
	for i: int in _lines.size():
		if at >= float(_lines[i]["at"]):
			wanted = i
		else:
			break
	if wanted == _current:
		return
	_current = wanted
	_label.text = "" if wanted < 0 else str(_lines[wanted]["text"])
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()

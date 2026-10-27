extends Control

## La solicitud de empleo: al empezar una partida nueva el guardia escribe su
## nombre en la hoja (assets/art/screens/solicitud_empleo.png) y la firma con
## Enter. El nombre lo dicen Ureña cuando llama y Rochis cuando te atrapa, así
## que vale la pena escribirlo.
##
## No hay cajas ni botones: se escribe directo sobre el renglón de la hoja, con
## su cursor parpadeando y un "clac" de máquina por tecla. Las posiciones del
## renglón y de la firma salen de data/pantallas_campos.json.

const IMAGE: String = "res://assets/art/screens/solicitud_empleo"
const HINT_TEXT: String = "Escribe tu nombre · Enter para firmar · Esc para volver"
const HINT_SIZE: int = 18
const HINT_COLOR: Color = Color(0.7, 0.72, 0.74, 0.85)

## El cursor del renglón y lo que tarda en parpadear.
const CURSOR: String = "_"
const BLINK_TIME: float = 0.5
## La firma: lo que tarda en aparecer y lo que se queda antes de empezar.
const SIGNATURE_FADE: float = 0.4
const SIGNATURE_HOLD: float = 1.0

## Las grabaciones de la tecla que de verdad están en assets/audio/, y la
## última que sonó, para no repetirla.
var _key_sounds: Array[String] = []
var _last_key_sound: String = ""

var _name: String = ""
var _signed: bool = false
var _blink_on: bool = true
var _blink_left: float = BLINK_TIME

var _sheet: TextureRect = null
var _name_label: Label = null
var _signature: Label = null
var _hint: Label = null


func _ready() -> void:
	# Los bucles de la pantalla anterior se cortan aquí: un ambiente colgado
	# es lo que se oye encima del nuevo.
	AudioManager.stop_all_loops()
	_load_key_sounds()
	_build()
	_layout()
	resized.connect(_layout)
	_refresh_name()


func _build() -> void:
	# La hoja, a pantalla completa.
	_sheet = TextureRect.new()
	_sheet.texture = GameAssets.load_texture(IMAGE)
	_sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sheet.stretch_mode = TextureRect.STRETCH_SCALE
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_sheet)

	_name_label = _make_label(ScreenFields.color(ScreenFields.APPLICATION_NAME))
	add_child(_name_label)

	# La firma empieza invisible: aparece al apretar Enter.
	_signature = _make_label(ScreenFields.SIGNATURE_INK)
	_signature.modulate.a = 0.0
	add_child(_signature)

	_hint = Label.new()
	_hint.text = HINT_TEXT
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(_hint, Fonts.typewriter(), HINT_SIZE)
	_hint.add_theme_color_override("font_color", HINT_COLOR)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -52.0
	_hint.offset_bottom = -20.0
	add_child(_hint)


func _make_label(ink: Color) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", ink)
	return label


## Los dos textos van sobre los campos medidos de la hoja.
func _layout() -> void:
	_place(_name_label, ScreenFields.APPLICATION_NAME,
		ScreenFields.font_size(ScreenFields.APPLICATION_NAME, size.y))
	var signature_size: int = maxi(1, roundi(
		ScreenFields.SIGNATURE_SIZE_AT_1080 * size.y / ScreenFields.REFERENCE.y))
	# La firma es lo único que no es un campo impreso de la hoja: va de puño y
	# letra, así que la fuente no sale del JSON.
	_place(_signature, ScreenFields.APPLICATION_SIGNATURE, signature_size, Fonts.hand())


func _place(label: Label, field_id: String, font_size: int, font: Font = null) -> void:
	Fonts.apply(label, font if font != null else ScreenFields.font(field_id), font_size)
	var width: float = ScreenFields.width(field_id, size)
	if width <= 0.0:
		width = size.x * 0.3
	label.position = ScreenFields.position(field_id, size)
	label.size = Vector2(width, float(font_size) * 1.6)
	label.rotation = ScreenFields.rotation(field_id)


# --- Escribir -----------------------------------------------------------------

func _process(delta: float) -> void:
	if _signed:
		return
	_blink_left -= delta
	if _blink_left > 0.0:
		return
	_blink_left += BLINK_TIME
	_blink_on = not _blink_on
	_refresh_name()


## El renglón, con el cursor si toca.
func _refresh_name() -> void:
	var cursor: String = CURSOR if _blink_on and not _signed else ""
	_name_label.text = _name + cursor


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or _signed:
		return
	match key.keycode:
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_back()
			return
		KEY_ENTER, KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_sign()
			return
		KEY_BACKSPACE:
			get_viewport().set_input_as_handled()
			_erase()
			return
	# Cualquier carácter que se pueda escribir va al renglón.
	var typed: String = String.chr(key.unicode) if key.unicode >= 32 else ""
	if typed.is_empty():
		return
	get_viewport().set_input_as_handled()
	_type(typed)


func _type(character: String) -> void:
	if _name.length() >= NightConfig.MAX_NAME_LENGTH:
		return
	_name += character
	_clac()


func _erase() -> void:
	if _name.is_empty():
		return
	_name = _name.substr(0, _name.length() - 1)
	_clac()


## Cuáles de las tres grabaciones de la tecla están puestas. Se pregunta una
## sola vez, al abrir la hoja, y no en cada tecla.
func _load_key_sounds() -> void:
	for sound_id: String in Sounds.TYPEWRITER_KEYS:
		if AudioManager.has_real_file(sound_id):
			_key_sounds.append(sound_id)


## La grabación que le toca a esta tecla: una al azar, nunca la misma dos veces
## seguidas. Si no hubiera ninguna, la tecla se escribe sin sonido.
func _key_sound() -> String:
	if _key_sounds.is_empty():
		return ""
	var pool: Array[String] = []
	for sound_id: String in _key_sounds:
		if sound_id != _last_key_sound:
			pool.append(sound_id)
	# Con una sola grabación no hay de dónde elegir: se repite y ya.
	if pool.is_empty():
		pool = _key_sounds
	_last_key_sound = pool[randi() % pool.size()]
	return _last_key_sound


## El golpe de la tecla, y el cursor se queda prendido mientras se escribe.
func _clac() -> void:
	AudioManager.play(_key_sound())
	_blink_on = true
	_blink_left = BLINK_TIME
	_refresh_name()


# --- Firmar -------------------------------------------------------------------

## Firma la hoja y arranca la partida. Un nombre vacío no firma nada.
func _sign() -> void:
	var clean: String = _name.strip_edges()
	if clean.is_empty():
		return
	_signed = true
	_name = clean
	_refresh_name()
	_hint.visible = false
	_signature.text = clean
	var tween: Tween = create_tween()
	tween.tween_property(_signature, "modulate:a", 1.0, SIGNATURE_FADE)
	tween.tween_interval(SIGNATURE_HOLD)
	tween.tween_callback(_start)


## Partida nueva: se borra el progreso anterior y se guarda el nombre. El
## recorte 0 sale antes de la primera noche.
func _start() -> void:
	SaveGame.reset()
	SaveGame.set_player_name(_name)
	SaveGame.unlock_newspaper(Newspapers.FIRST_INDEX)
	GameManager.prepare_night(1)
	NewspaperScreen.pending_documents = []
	NewspaperScreen.next_scene = Screens.NIGHT_INTRO
	LoadingScreen.go_to(get_tree(), Screens.NEWSPAPER)


func _on_back() -> void:
	get_tree().change_scene_to_file(Screens.MAIN_MENU)

class_name WastedScreen
extends Control

## La pantalla de "WASTED", al estilo GTA. La usa el game over de Mamador y la
## va a usar la tarea de la baraja; lo único que cambia entre las dos es el
## texto de abajo, que se pasa como parámetro.
##
## La secuencia, en orden:
##   0.0  la imagen a pantalla completa, con un zoom lento que no para en toda
##        la secuencia (1.0 a 1.08)
##   0.4  se va a blanco y negro en 0.8 s y baja un poco de brillo; suena el
##        golpe de `wasted`
##   1.2  entra la franja negra del centro, de lado a lado
##   1.2  encima, "WASTED" escalando de 1.15 a 1.0
##   2.2  debajo de la franja, el texto que se le haya pasado
##   5.2  avisa de que terminó
##
## Se arma sola por código, así que basta con meterla como hijo de cualquier
## pantalla: la usa la noche y también la galería de Extras.

## Terminó la secuencia. Quien la abrió decide qué viene después.
signal finished()

const GREYSCALE_SHADER: String = "res://scenes/ui/greyscale.gdshader"
const IMAGE_PATH: String = "res://assets/art/jumpscares/jumpscare_%s"

# --- Tiempos (segundos desde que empieza) ------------------------------------
const DESATURATE_AT: float = 0.4
const DESATURATE_TIME: float = 0.8
const BAND_AT: float = 1.2
const BAND_FADE: float = 0.3
const TITLE_POP_TIME: float = 0.25
const SUBTITLE_AT: float = 2.2
const SUBTITLE_FADE: float = 0.3
## Lo que se queda quieta después de que entra el texto de abajo.
const HOLD_AFTER_SUBTITLE: float = 3.0
const TOTAL_TIME: float = 5.2

# --- Cómo se ve --------------------------------------------------------------
const ZOOM_FROM: float = 1.0
const ZOOM_TO: float = 1.08
## Lo que se le baja de brillo al pasar a blanco y negro.
const DARKEN: float = 0.22

const TITLE: String = "WASTED"
const TITLE_COLOR: Color = Color(0.761, 0.118, 0.118)   # #C21E1E
const SUBTITLE_COLOR: Color = Color(0.95, 0.95, 0.94)
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0)
## Medidos a 1080p y escalados con el alto.
const TITLE_SIZE_AT_1080: float = 150.0
const OUTLINE_AT_1080: float = 12.0
const REFERENCE_HEIGHT: float = 1080.0
## Lo chico que sale el texto de abajo respecto a WASTED.
const SUBTITLE_RATIO: float = 0.4
const TITLE_POP_FROM: float = 1.15

## La franja: de lado a lado, centrada, y este alto en fracción de la pantalla.
const BAND_HEIGHT: float = 0.16
const BAND_COLOR: Color = Color(0.0, 0.0, 0.0, 0.55)

var is_playing: bool = false

var _picture: TextureRect = null
var _band: ColorRect = null
var _title: Label = null
var _subtitle: Label = null
var _tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false


func _build() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_picture = TextureRect.new()
	_picture.name = "Picture"
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(GREYSCALE_SHADER):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load(GREYSCALE_SHADER)
		material.set_shader_parameter("amount", 0.0)
		material.set_shader_parameter("darken", 0.0)
		_picture.material = material
	add_child(_picture)

	_band = ColorRect.new()
	_band.name = "Band"
	_band.color = BAND_COLOR
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.modulate.a = 0.0
	add_child(_band)

	_title = _make_label(TITLE, TITLE_COLOR)
	add_child(_title)
	_subtitle = _make_label("", SUBTITLE_COLOR)
	add_child(_subtitle)


func _make_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.modulate.a = 0.0
	# El texto escala desde el centro, no desde la esquina.
	label.pivot_offset = Vector2.ZERO
	return label


## Arranca la secuencia. `image_id` es el nombre del jumpscare sin el prefijo
## (por ejemplo "mamador_militares"); `bottom_text`, lo que va bajo la franja.
func play(image_id: String, bottom_text: String) -> void:
	if is_playing:
		return
	is_playing = true
	visible = true
	_picture.texture = GameAssets.load_texture(IMAGE_PATH % image_id)
	_subtitle.text = bottom_text
	_layout()

	# Todo vuelve a su estado de arranque, por si se repite.
	_picture.scale = Vector2.ONE * ZOOM_FROM
	_band.modulate.a = 0.0
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	_set_grey(0.0, 0.0)

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	# El zoom corre por debajo de todo lo demás, de principio a fin.
	_tween.tween_property(_picture, "scale", Vector2.ONE * ZOOM_TO, TOTAL_TIME)
	# A los 0.4 s, a blanco y negro.
	_tween.tween_method(_set_grey_amount, 0.0, 1.0, DESATURATE_TIME) \
		.set_delay(DESATURATE_AT)
	_tween.tween_callback(func() -> void: AudioManager.play(Sounds.WASTED)) \
		.set_delay(DESATURATE_AT)
	# A los 1.2 s, la franja y el título.
	_tween.tween_property(_band, "modulate:a", 1.0, BAND_FADE).set_delay(BAND_AT)
	_tween.tween_property(_title, "modulate:a", 1.0, BAND_FADE).set_delay(BAND_AT)
	_tween.tween_method(_set_title_scale, TITLE_POP_FROM, 1.0, TITLE_POP_TIME) \
		.set_delay(BAND_AT).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# A los 2.2 s, el texto de abajo.
	_tween.tween_property(_subtitle, "modulate:a", 1.0, SUBTITLE_FADE) \
		.set_delay(SUBTITLE_AT)
	# Y al final, avisa.
	_tween.tween_callback(_on_finished).set_delay(TOTAL_TIME)


## Corta la secuencia donde esté, sin avisar. Lo usa el fin de noche.
func stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	AudioManager.stop(Sounds.WASTED)
	is_playing = false
	visible = false


func _on_finished() -> void:
	is_playing = false
	finished.emit()


func _set_grey_amount(value: float) -> void:
	_set_grey(value, DARKEN * value)


func _set_grey(amount: float, darken: float) -> void:
	var material: ShaderMaterial = _picture.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("amount", amount)
		material.set_shader_parameter("darken", darken)


## El título crece desde el centro de la franja, no desde su esquina.
func _set_title_scale(value: float) -> void:
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2.ONE * value


func _title_size() -> int:
	return maxi(24, roundi(TITLE_SIZE_AT_1080 * size.y / REFERENCE_HEIGHT))


func _layout() -> void:
	if _band == null:
		return
	var font: Font = Fonts.display()
	var title_size: int = _title_size()
	var outline: int = maxi(2, roundi(OUTLINE_AT_1080 * size.y / REFERENCE_HEIGHT))
	var band_height: float = size.y * BAND_HEIGHT

	# La franja, de lado a lado y centrada a lo alto.
	_band.position = Vector2(0.0, (size.y - band_height) * 0.5)
	_band.size = Vector2(size.x, band_height)

	Fonts.apply(_title, font, title_size)
	_title.add_theme_constant_override("outline_size", outline)
	_title.position = _band.position
	_title.size = _band.size
	_title.pivot_offset = _title.size * 0.5

	var small: int = maxi(14, roundi(float(title_size) * SUBTITLE_RATIO))
	Fonts.apply(_subtitle, font, small)
	_subtitle.add_theme_constant_override("outline_size", maxi(2, roundi(outline * SUBTITLE_RATIO)))
	_subtitle.position = Vector2(0.0, _band.position.y + band_height)
	_subtitle.size = Vector2(size.x, float(small) * 1.8)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_playing:
		_layout()

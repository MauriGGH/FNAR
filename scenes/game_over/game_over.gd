extends Control

## Pantalla de game over, al estilo de los juegos originales: un segundo de
## estática fuerte y, al aclararse, la cámara del lugar de donde salió el profe
## que te atrapó, en blanco y negro y con grano, como una cinta de vigilancia.
## Encima, "GAME OVER" y la causa escritas a máquina.
##
## Clic en cualquier lado vuelve al menú; el botón repite la misma noche.

const GREYSCALE_SHADER: String = "res://scenes/ui/greyscale.gdshader"

## Lo que dura la estática fuerte antes de que se vea la imagen.
const STATIC_TIME: float = 1.0
const STATIC_HEAVY: float = 0.85
const STATIC_IDLE: float = 0.14
## Lo que tarda la imagen en aparecer una vez baja la estática.
const IMAGE_FADE: float = 0.5
## Y lo que tarda el texto, ya con la imagen puesta.
const TEXT_FADE: float = 0.45

const TITLE_SIZE: int = 64
const CAUSE_SIZE: int = 26
const HINT_SIZE: int = 17
const HINT_COLOR: Color = Color(0.72, 0.7, 0.68, 0.8)
const HINT_TEXT: String = "clic para volver al menú"

@onready var cause_label: Label = $CauseLabel
@onready var title_label: Label = $TitleLabel
@onready var retry_button: Button = $RetryButton

var _picture: TextureRect = null
var _static_layer: ColorRect = null
var _can_leave: bool = false
var _static_strength: float = STATIC_HEAVY:
	set(value):
		_static_strength = value
		ScreenFx.set_static_strength(_static_layer, value)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_picture()
	_style_texts()
	_build_hint()
	_static_layer = ScreenFx.add_static(self, STATIC_HEAVY)
	# El botón y los textos se arman en la escena, así que hay que subirlos por
	# encima de la imagen y de la estática.
	for node_name: String in ["TitleLabel", "CauseLabel", "RetryButton"]:
		var node: Node = get_node_or_null(node_name)
		if node != null:
			move_child(node, get_child_count() - 1)

	retry_button.pressed.connect(_on_retry_pressed)
	_play_intro()


## La cámara de donde vino quien te atrapó, en blanco y negro. Si no se sabe
## quién fue, se queda el fondo oscuro de la escena.
func _build_picture() -> void:
	var texture: Texture2D = Extras.origin_camera_texture(GameManager.last_game_over_slug)
	if texture == null:
		return
	_picture = TextureRect.new()
	_picture.texture = texture
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.modulate.a = 0.0
	if ResourceLoader.exists(GREYSCALE_SHADER):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load(GREYSCALE_SHADER)
		_picture.material = material
	add_child(_picture)


## El título y la causa van a máquina de escribir, y empiezan apagados.
func _style_texts() -> void:
	Fonts.apply(title_label, Fonts.typewriter(), TITLE_SIZE)
	Fonts.apply(cause_label, Fonts.typewriter(), CAUSE_SIZE)
	cause_label.text = GameManager.last_game_over_cause
	title_label.modulate.a = 0.0
	cause_label.modulate.a = 0.0
	retry_button.modulate.a = 0.0
	retry_button.disabled = true


func _build_hint() -> void:
	var label: Label = Label.new()
	label.name = "Hint"
	label.text = HINT_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(label, Fonts.typewriter(), HINT_SIZE)
	label.add_theme_color_override("font_color", HINT_COLOR)
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -48.0
	label.offset_bottom = -20.0
	label.modulate.a = 0.0
	add_child(label)


## Estática fuerte, luego la imagen, luego el texto.
func _play_intro() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(STATIC_TIME)
	tween.tween_property(self, "_static_strength", STATIC_IDLE, IMAGE_FADE)
	if _picture != null:
		tween.parallel().tween_property(_picture, "modulate:a", 1.0, IMAGE_FADE)
	tween.tween_property(title_label, "modulate:a", 1.0, TEXT_FADE)
	tween.parallel().tween_property(cause_label, "modulate:a", 1.0, TEXT_FADE)
	tween.tween_property(retry_button, "modulate:a", 1.0, TEXT_FADE)
	var hint: Control = get_node_or_null("Hint") as Control
	if hint != null:
		tween.parallel().tween_property(hint, "modulate:a", 1.0, TEXT_FADE)
	tween.tween_callback(_allow_leaving)


func _allow_leaving() -> void:
	_can_leave = true
	retry_button.disabled = false
	retry_button.grab_focus()


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or not _can_leave:
		return
	get_tree().change_scene_to_file(Screens.MAIN_MENU)
	accept_event()


## Repetir la noche que se estaba jugando, con su misma configuración.
func _on_retry_pressed() -> void:
	LoadingScreen.go_to(get_tree(),
		Screens.NIGHT_INTRO if not GameManager.is_custom_night else Screens.NIGHT)

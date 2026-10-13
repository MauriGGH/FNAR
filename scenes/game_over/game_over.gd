extends Control

## Pantalla de game over, al estilo de los juegos originales: un segundo de
## estática fuerte y, al aclararse, la cámara del lugar de donde salió el profe
## que te atrapó, en blanco y negro y con grano, como una cinta de vigilancia.
## Encima, "GAME OVER" y la causa escritas a máquina.
##
## Clic en cualquier lado vuelve al menú; la lista de abajo, en VT323 como el
## resto de los menús, repite la noche o vuelve al menú.

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

const HINT: String = "flechas o W/S · Enter para elegir · clic para volver al menú"
## Dónde cae la lista, en fracción del alto.
const LIST_TOP: float = 0.6

@onready var cause_label: Label = $CauseLabel
@onready var title_label: Label = $TitleLabel

var _list: MenuList = null
var _hint: Label = null
var _picture: TextureRect = null
var _static_layer: StaticFrames = null
var _can_leave: bool = false
var _static_strength: float = STATIC_HEAVY:
	set(value):
		_static_strength = value
		ScreenFx.set_static_strength(_static_layer, value)


func _ready() -> void:
	# Los bucles de la noche se cortan, pero el grito del jumpscare se deja
	# acabar: su cola encima de la estática es parte del golpe.
	AudioManager.stop_all_loops()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_picture()
	_style_texts()
	_build_list()
	_static_layer = ScreenFx.add_static(self, STATIC_HEAVY)
	# Debajo de la estática que se ve, la que se oye.
	# Debajo de la estática visual, pero **esperando su turno**: si el grito del
	# susto o el golpe de WASTED siguen sonando, entra cuando acaben.
	AudioManager.play_in_sequence(Sounds.SEQ_SCARE, Sounds.UNEASY_STATIC_GAME_OVER)
	# Los textos se arman en la escena, así que hay que subirlos por encima de
	# la imagen y de la estática.
	for node_name: String in ["TitleLabel", "CauseLabel"]:
		var node: Node = get_node_or_null(node_name)
		if node != null:
			move_child(node, get_child_count() - 1)
	move_child(_list, get_child_count() - 1)
	_layout()
	resized.connect(_layout)
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


## Las dos salidas, en VT323 y con ">>", como todos los menús. Empiezan
## apagadas: aparecen cuando se aclara la estática.
func _build_list() -> void:
	_list = MenuList.new()
	_list.top = LIST_TOP
	_list.modulate.a = 0.0
	add_child(_list)
	_list.add_action("Repetir la noche", _on_retry_pressed)
	_list.add_action("Volver al menú",
		func() -> void: get_tree().change_scene_to_file(Screens.MAIN_MENU))
	_list.build()

	_hint = MenuStyle.hint(self, HINT)
	_hint.modulate.a = 0.0


func _layout() -> void:
	MenuStyle.place_hint(_hint, size)
	if _list != null:
		_list.layout()


## Estática fuerte, luego la imagen, luego el texto.
func _play_intro() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(STATIC_TIME)
	tween.tween_property(self, "_static_strength", STATIC_IDLE, IMAGE_FADE)
	if _picture != null:
		tween.parallel().tween_property(_picture, "modulate:a", 1.0, IMAGE_FADE)
	tween.tween_property(title_label, "modulate:a", 1.0, TEXT_FADE)
	tween.parallel().tween_property(cause_label, "modulate:a", 1.0, TEXT_FADE)
	tween.tween_property(_list, "modulate:a", 1.0, TEXT_FADE)
	tween.parallel().tween_property(_hint, "modulate:a", 1.0, TEXT_FADE)
	tween.tween_callback(_allow_leaving)


## Al salir del game over no se arrastra nada: ni la estática inquietante ni
## la cola del grito.
func _exit_tree() -> void:
	AudioManager.stop_all()


func _allow_leaving() -> void:
	_can_leave = true


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or not _can_leave:
		return
	get_tree().change_scene_to_file(Screens.MAIN_MENU)
	accept_event()


## Las teclas van a la lista en cuanto se puede salir.
func _input(event: InputEvent) -> void:
	if not _can_leave:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and _list.handle_key(key):
		get_viewport().set_input_as_handled()


## Repetir la noche que se estaba jugando, con su misma configuración.
func _on_retry_pressed() -> void:
	LoadingScreen.go_to(get_tree(),
		Screens.NIGHT_INTRO if not GameManager.is_custom_night else Screens.NIGHT)

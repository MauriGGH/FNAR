extends Control

## El menú principal. El título va como imagen si existe el arte; mientras no,
## como texto con la misma tipografía del juego. Custom Night y Extras se
## abren al pasar la noche 5, como en los juegos originales.

## El arte del título, para cuando exista. Si no está, se escribe el texto.
const TITLE_IMAGE_PATH: String = "res://assets/art/ui/titulo"
const TITLE_TEXT: String = "CINCO NOCHES EN LA\nCOORDINACIÓN DE SISTEMAS"
const TITLE_FONT_SIZE: int = 44
const TITLE_COLOR: Color = Color(0.93, 0.9, 0.84)
## Lo alto que se dibuja el título cuando sí hay imagen.
const TITLE_HEIGHT: float = 220.0

const BUTTON_GAP: float = 10.0
## Dónde van las estrellas, justo debajo del título.
const STARS_TOP: float = 282.0
const HINT_SIZE: int = 17
const HINT_COLOR: Color = Color(0.68, 0.7, 0.72, 0.85)
## Dónde empieza la columna de botones, en fracción del alto.
const COLUMN_TOP: float = 0.4

var _column: VBoxContainer = null
var _stars: StarRow = null
var _options: OptionsPanel = null


func _ready() -> void:
	MenuBackdrop.build(self)
	_build_title()
	_build_stars()
	_build_buttons()
	_build_hint()
	_layout()
	resized.connect(_layout)
	# Las opciones van encima de todo, así que se montan al final.
	_options = OptionsPanel.build(self)


## La columna de botones va centrada a mano, no con anclas: así se puede
## recolocar sola si cambia el tamaño de la ventana.
func _layout() -> void:
	if _column != null:
		_column.position = Vector2((size.x - UiButton.SIZE.x) * 0.5, size.y * COLUMN_TOP)
	if _stars != null:
		_stars.position = Vector2((size.x - _stars.size.x) * 0.5, STARS_TOP)


func _build_title() -> void:
	var texture: Texture2D = GameAssets.load_texture(TITLE_IMAGE_PATH)
	if texture != null:
		var image: TextureRect = TextureRect.new()
		image.texture = texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.set_anchors_preset(Control.PRESET_TOP_WIDE)
		image.offset_top = 46.0
		image.offset_bottom = 46.0 + TITLE_HEIGHT
		add_child(image)
		return
	var label: Label = Label.new()
	label.text = TITLE_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	label.add_theme_color_override("font_color", TITLE_COLOR)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("outline_size", 8)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 56.0
	label.offset_bottom = 56.0 + TITLE_HEIGHT
	add_child(label)


## Las tres estrellas del progreso. Se colocan en _layout(), como la columna.
func _build_stars() -> void:
	_stars = StarRow.new()
	add_child(_stars)
	_stars.earned = SaveGame.star_count()


func _build_buttons() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Buttons"
	column.add_theme_constant_override("separation", int(BUTTON_GAP))
	add_child(column)
	_column = column

	var locked: bool = not SaveGame.is_extras_unlocked()
	var new_game: Button = UiButton.make("Nueva partida")
	new_game.pressed.connect(_on_new_game)
	column.add_child(new_game)

	var continue_button: Button = UiButton.make(
		"Continuar — noche %d" % SaveGame.night_reached, not SaveGame.has_progress())
	continue_button.pressed.connect(_on_continue)
	column.add_child(continue_button)

	var custom: Button = UiButton.make("Custom Night", locked)
	custom.pressed.connect(_on_custom_night)
	column.add_child(custom)

	var extras: Button = UiButton.make("Extras", locked)
	extras.pressed.connect(_on_extras)
	column.add_child(extras)

	var options: Button = UiButton.make("Opciones")
	options.pressed.connect(func() -> void: _options.open())
	column.add_child(options)

	var quit_button: Button = UiButton.make("Salir")
	quit_button.pressed.connect(_on_quit)
	column.add_child(quit_button)


## La nota de abajo explica por qué hay cosas bloqueadas.
func _build_hint() -> void:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", HINT_SIZE)
	label.add_theme_color_override("font_color", HINT_COLOR)
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -56.0
	label.offset_bottom = -22.0
	if SaveGame.is_extras_unlocked():
		label.text = "Guardia: %s" % SaveGame.player_name
	else:
		label.text = "Custom Night y Extras se abren al pasar la noche %d" % NightConfig.EXTRAS_FROM_NIGHT
	add_child(label)


func _on_new_game() -> void:
	get_tree().change_scene_to_file(Screens.NAME_ENTRY)


func _on_continue() -> void:
	GameManager.prepare_night(SaveGame.night_reached)
	LoadingScreen.go_to(get_tree(), Screens.NIGHT_INTRO)


func _on_custom_night() -> void:
	get_tree().change_scene_to_file(Screens.CUSTOM_NIGHT)


func _on_extras() -> void:
	get_tree().change_scene_to_file(Screens.EXTRAS_MENU)


func _on_quit() -> void:
	get_tree().quit()

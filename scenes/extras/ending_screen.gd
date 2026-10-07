extends Control

## El final del juego, al pasar la noche 6. Sencillo a propósito: el gancho de
## verdad lo deja el último recorte de periódico.

const TITLE: String = "SOBREVIVISTE LAS SEIS NOCHES"
const BODY: String = "La coordinación quedó clausurada.\nEl responsable sigue sin ser identificado."
const TITLE_SIZE: int = 40
const BODY_SIZE: int = 24
const TITLE_COLOR: Color = Color(0.93, 0.9, 0.84)
const BODY_COLOR: Color = Color(0.74, 0.76, 0.78)


func _ready() -> void:
	MenuBackdrop.build(self)
	_add_label(TITLE, TITLE_SIZE, TITLE_COLOR, size.y * 0.3, 60.0)
	_add_label(BODY, BODY_SIZE, BODY_COLOR, size.y * 0.42, 100.0)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	column.position = Vector2((size.x - UiButton.SIZE.x) * 0.5, size.y * 0.64)
	var extras: Button = UiButton.make("Extras", not SaveGame.is_extras_unlocked())
	extras.pressed.connect(func() -> void: get_tree().change_scene_to_file(Screens.EXTRAS_MENU))
	column.add_child(extras)
	var menu: Button = UiButton.make("Volver al menú")
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(Screens.MAIN_MENU))
	column.add_child(menu)


func _add_label(text: String, font_size: int, color: Color, top: float, height: float) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = top
	label.offset_bottom = top + height
	add_child(label)

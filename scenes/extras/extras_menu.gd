extends Control

## El menú de Extras: expedientes, periódicos, jumpscares y Custom Night.
## Todo lo que no esté desbloqueado sale como silueta con "???".
## Las cuatro secciones viven en esta misma pantalla, para no multiplicar
## escenas por algo que es una galería.

enum Section { DOSSIERS, NEWSPAPERS, JUMPSCARES }

const TITLE_SIZE: int = 34
const TAB_FONT: int = 22
const TEXT_COLOR: Color = Color(0.93, 0.9, 0.84)
const LOCKED_TEXT: String = "???"

# Rejilla de fichas.
const CARD_SIZE: Vector2 = Vector2(188.0, 236.0)
const CARD_GAP: int = 14
const CARD_COLUMNS: int = 4
const CARD_NAME_SIZE: int = 18
const CARD_ROLE_SIZE: int = 14
const CARD_FILL: Color = Color(0.1, 0.11, 0.13, 0.8)
const CARD_BORDER: Color = Color(0.72, 0.74, 0.76, 0.6)
## La silueta de lo bloqueado.
const SILHOUETTE: Color = Color(0.06, 0.06, 0.07, 0.95)

## Nombre en pantalla, rol y una línea, por personaje. Los ids son los de
## data/extras.gd, los mismos que usa el código para las imágenes.
const SHEETS: Dictionary = {
	"barcosa": ["Barcosa", "rol Foxy", "Se esconde en la sala de servicio y corre por el pasillo."],
	"mamador": ["Mamador", "rol Freddy", "Baja de la sala de juntas a revisar que no cometas un delito federal."],
	"urena": ["Ureña", "rol Chica", "Lento, se pega al cristal y solo se ve con la linterna. Llama por teléfono."],
	"rochis": ["Rochis", "rol Bonnie", "Se levanta de su silla si no le pones el audio a tiempo."],
	"audel": ["Mago Eléctrico", "rol Balloon Boy", "Vive en el techo, tira la corriente y desconecta los cables."],
	"juan": ["Juan.exe", "rol Bonnie clásico", "Sin mecánica propia: al cristal y a esperar los destellos."],
	"armando": ["Armando Prompts", "rol Chica clásico", "Se cree genio y te toma la pantalla de la PC."],
	"come_trabas": ["Come Trabas", "rol Puppet", "La botarga con el alma de Santi. Solo la cuerda la mantiene quieta."],
}

var _section: Section = Section.DOSSIERS
var _content: Control = null


func _ready() -> void:
	MenuBackdrop.build(self)
	_build_header()
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = 150.0
	_content.offset_bottom = -90.0
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_build_footer()
	_show_section(Section.DOSSIERS)


func _build_header() -> void:
	var title: Label = Label.new()
	title.text = "EXTRAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28.0
	title.offset_bottom = 72.0
	add_child(title)

	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	tabs.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.offset_top = 86.0
	tabs.offset_bottom = 134.0
	add_child(tabs)
	for entry: Array in [[Section.DOSSIERS, "Expedientes"],
			[Section.NEWSPAPERS, "Periódicos"], [Section.JUMPSCARES, "Jumpscares"]]:
		var button: Button = UiButton.make(str(entry[1]))
		button.custom_minimum_size = Vector2(230.0, 44.0)
		button.add_theme_font_size_override("font_size", TAB_FONT)
		button.pressed.connect(_show_section.bind(entry[0] as Section))
		tabs.add_child(button)


func _build_footer() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.offset_top = -72.0
	row.offset_bottom = -20.0
	add_child(row)

	var custom: Button = UiButton.make("Custom Night")
	custom.custom_minimum_size = Vector2(260.0, 48.0)
	custom.pressed.connect(func() -> void: get_tree().change_scene_to_file(Screens.CUSTOM_NIGHT))
	row.add_child(custom)

	var back: Button = UiButton.make("Volver al menú")
	back.custom_minimum_size = Vector2(260.0, 48.0)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(Screens.MAIN_MENU))
	row.add_child(back)


func _show_section(section: Section) -> void:
	_section = section
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	match _section:
		Section.DOSSIERS:
			_build_dossiers()
		Section.NEWSPAPERS:
			_build_newspapers()
		Section.JUMPSCARES:
			_build_jumpscares()


## Una ficha por personaje. Las que no se han desbloqueado van en silueta.
func _build_dossiers() -> void:
	var grid: GridContainer = _make_grid()
	for character_id: String in Extras.DOSSIER_IDS:
		var sheet: Array = SHEETS.get(character_id, [character_id, "", ""])
		var unlocked: bool = SaveGame.has_dossier(character_id)
		grid.add_child(_make_card(
			Extras.dossier_texture(character_id) if unlocked else null,
			str(sheet[0]) if unlocked else LOCKED_TEXT,
			str(sheet[1]) if unlocked else "",
			str(sheet[2]) if unlocked else ""))


## Los recortes desbloqueados, para releerlos.
func _build_newspapers() -> void:
	var grid: GridContainer = _make_grid()
	for index: int in Newspapers.count():
		var unlocked: bool = SaveGame.has_newspaper(index)
		var clipping: Dictionary = Newspapers.clipping(index)
		var card: Control = _make_card(
			Newspapers.image(index) if unlocked else null,
			"Recorte %d" % index if unlocked else LOCKED_TEXT,
			str(clipping.get("date", "")) if unlocked else "",
			str(clipping.get("title", "")) if unlocked else "")
		if unlocked:
			card.gui_input.connect(_on_newspaper_input.bind(index))
			card.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(card)


## La galería de jumpscares: por ahora el nombre de cada causa ya vista.
func _build_jumpscares() -> void:
	var grid: GridContainer = _make_grid()
	for character_id: String in Extras.DOSSIER_IDS:
		var sheet: Array = SHEETS.get(character_id, [character_id, "", ""])
		var cause: String = str(sheet[0])
		var seen: bool = SaveGame.has_jumpscare(cause)
		# La galería usa las imágenes de jumpscare, no los expedientes.
		grid.add_child(_make_card(
			Extras.jumpscare_texture(character_id) if seen else null,
			cause if seen else LOCKED_TEXT,
			"visto" if seen else "",
			"Te atrapó al menos una vez." if seen else ""))


func _on_newspaper_input(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	NewspaperScreen.pending_index = index
	NewspaperScreen.next_scene = Screens.EXTRAS_MENU
	get_tree().change_scene_to_file(Screens.NEWSPAPER)


func _make_grid() -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = CARD_COLUMNS
	grid.add_theme_constant_override("h_separation", CARD_GAP)
	grid.add_theme_constant_override("v_separation", CARD_GAP)
	grid.position = Vector2(
		(size.x - (CARD_SIZE.x + CARD_GAP) * CARD_COLUMNS + CARD_GAP) * 0.5, 0.0)
	_content.add_child(grid)
	return grid


## Una ficha: imagen arriba (o silueta), nombre, rol y una línea.
func _make_card(texture: Texture2D, name_text: String, role_text: String, line_text: String) -> Control:
	var card: Panel = Panel.new()
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = CARD_FILL
	box.set_border_width_all(2)
	box.border_color = CARD_BORDER
	box.set_corner_radius_all(3)
	card.add_theme_stylebox_override("panel", box)

	var picture: Rect2 = Rect2(Vector2(8.0, 8.0), Vector2(CARD_SIZE.x - 16.0, 132.0))
	if texture != null:
		var image: TextureRect = TextureRect.new()
		image.texture = texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.clip_contents = true
		image.position = picture.position
		image.size = picture.size
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(image)
	else:
		var hole: ColorRect = ColorRect.new()
		hole.color = SILHOUETTE
		hole.position = picture.position
		hole.size = picture.size
		hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(hole)

	var name_label: Label = _card_label(name_text, CARD_NAME_SIZE, TEXT_COLOR)
	name_label.position = Vector2(8.0, picture.end.y + 6.0)
	name_label.size = Vector2(CARD_SIZE.x - 16.0, 24.0)
	card.add_child(name_label)

	var role_label: Label = _card_label(role_text, CARD_ROLE_SIZE, Color(0.7, 0.72, 0.74))
	role_label.position = Vector2(8.0, picture.end.y + 30.0)
	role_label.size = Vector2(CARD_SIZE.x - 16.0, 20.0)
	card.add_child(role_label)

	var line_label: Label = _card_label(line_text, CARD_ROLE_SIZE, Color(0.62, 0.64, 0.66))
	line_label.position = Vector2(8.0, picture.end.y + 52.0)
	line_label.size = Vector2(CARD_SIZE.x - 16.0, 48.0)
	line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(line_label)
	return card


func _card_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	return label


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(Screens.MAIN_MENU)
		get_viewport().set_input_as_handled()

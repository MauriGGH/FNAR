extends Control

## El menú de Extras: expedientes, periódicos, documentos y jumpscares. Todo lo
## que no esté desbloqueado sale oscurecido con "???".
##
## Las cuatro secciones viven en esta misma pantalla, para no multiplicar
## escenas por algo que es una galería. A la izquierda, la lista de secciones en
## VT323 con ">>" como todos los menús; a la derecha, lo que se esté viendo.

enum Section { DOSSIERS, NEWSPAPERS, DOCUMENTS, JUMPSCARES }

const TITLE: String = "EXTRAS"
const HINT: String = "flechas o W/S · Enter para elegir · Esc para volver"
const LOCKED_TEXT: String = "???"

## La columna de secciones ocupa la izquierda; las fichas van en lo que queda.
const CONTENT_LEFT: float = 0.33
const CONTENT_RIGHT: float = 0.98
const LIST_TOP: float = 0.26

# Rejilla de fichas. Sin paneles ni bordes: la imagen y su texto debajo.
const CARD_SIZE: Vector2 = Vector2(188.0, 236.0)
const CARD_GAP: int = 14
const CARD_COLUMNS: int = 3
## Dónde empieza la rejilla, en fracción del alto.
const GRID_TOP: float = 0.2
const CARD_NAME_SIZE: int = 18
const CARD_ROLE_SIZE: int = 14
## El hueco negro de lo que está bloqueado.
const SILHOUETTE: Color = Color(0.04, 0.04, 0.05, 1.0)

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
	"come_trabas": ["Come Trabas", "rol Puppet", "La botarga con el alma de Santi, alumno de Sistemas. Solo la cuerda la mantiene quieta."],
}

const JUMPSCARE_OVERLAY: GDScript = preload("res://scenes/night/jumpscare_overlay.gd")

var _section: Section = Section.DOSSIERS
## Las dos capas con las que la galería reproduce: la del salto de siempre y
## la de WASTED, que es la de Mamador.
var _jumpscare: Control = null
var _wasted: WastedScreen = null
var _content: Control = null
var _title: Label = null
var _hint: Label = null
var _list: MenuList = null


func _ready() -> void:
	MenuBackdrop.build(self)
	# El contenido va primero para que la lista y el título queden encima: los
	# expedientes se ven a pantalla completa y pasan por debajo de ellos.
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_title = MenuStyle.title(self, TITLE)
	_build_list()
	_hint = MenuStyle.hint(self, HINT)
	# La galería reproduce de verdad: estas dos capas van encima de todo.
	_jumpscare = JUMPSCARE_OVERLAY.new()
	_jumpscare.name = "JumpscareOverlay"
	_jumpscare.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_jumpscare.visible = false
	add_child(_jumpscare)
	_wasted = WastedScreen.new()
	_wasted.name = "WastedScreen"
	add_child(_wasted)
	_layout()
	resized.connect(_layout)
	_show_section(Section.DOSSIERS)


## La columna de secciones, más Custom Night y la salida.
func _build_list() -> void:
	_list = MenuList.new()
	_list.top = LIST_TOP
	add_child(_list)
	_list.add_action("Expedientes", _show_section.bind(Section.DOSSIERS))
	_list.add_action("Periódicos", _show_section.bind(Section.NEWSPAPERS))
	_list.add_action("Documentos", _show_section.bind(Section.DOCUMENTS))
	_list.add_action("Jumpscares", _show_section.bind(Section.JUMPSCARES))
	_list.add_action("Custom Night",
		func() -> void: get_tree().change_scene_to_file(Screens.CUSTOM_NIGHT))
	_list.add_action("Volver al menú",
		func() -> void: get_tree().change_scene_to_file(Screens.MAIN_MENU))
	_list.build()


func _layout() -> void:
	MenuStyle.place_title(_title, size, 0.1)
	MenuStyle.place_hint(_hint, size)
	if _list != null:
		_list.layout()


## Cambia de sección: tira lo que hubiera y arma lo nuevo. Le entra un int y
## no un Section porque también la llaman la lista y el panel de pruebas.
func _show_section(section: int) -> void:
	_section = section as Section
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	match _section:
		Section.DOSSIERS:
			_build_dossiers()
		Section.NEWSPAPERS:
			_build_newspapers()
		Section.DOCUMENTS:
			_build_documents()
		Section.JUMPSCARES:
			_build_jumpscares()


## Los expedientes, uno por pantalla. Las imágenes ya son la escena completa
## (la carpeta y el plano), así que no hay nada que recortar: se enseñan tal
## cual y se pasa de una a otra con las flechas o con clic. Los que todavía no
## se desbloquean salen desenfocados y oscuros, con "???" encima.
func _build_dossiers() -> void:
	var pages: Array[Dictionary] = []
	for character_id: String in Extras.DOSSIER_IDS:
		var sheet: Array = SHEETS.get(character_id, [character_id, "", ""])
		pages.append({
			"texture": Extras.dossier_texture(character_id),
			"unlocked": SaveGame.has_dossier(character_id),
			"caption": "%s · %s — %s" % [str(sheet[0]), str(sheet[1]), str(sheet[2])],
		})
	var gallery: ArtGallery = ArtGallery.new()
	_content.add_child(gallery)
	gallery.setup(pages)


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


## Las hojas que te han entregado: los recibos de pago y la carta de despido.
## Se desbloquean al verlas por primera vez.
func _build_documents() -> void:
	var grid: GridContainer = _make_grid()
	for document_id: String in Documents.IDS:
		var unlocked: bool = SaveGame.has_document(document_id)
		var card: Control = _make_card(
			Documents.texture(document_id) if unlocked else null,
			Documents.title(document_id) if unlocked else LOCKED_TEXT,
			"con tu nombre" if unlocked else "",
			Documents.source(document_id))
		if unlocked:
			card.gui_input.connect(_on_document_input.bind(document_id))
			card.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(card)


func _on_document_input(event: InputEvent, document_id: String) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	DocumentScreen.show_documents(get_tree(), [document_id], Screens.EXTRAS_MENU)


## La galería de jumpscares: por ahora el nombre de cada causa ya vista.
func _build_jumpscares() -> void:
	var grid: GridContainer = _make_grid()
	for character_id: String in Extras.DOSSIER_IDS:
		var sheet: Array = SHEETS.get(character_id, [character_id, "", ""])
		var cause: String = str(sheet[0])
		var seen: bool = SaveGame.has_jumpscare(cause)
		# La galería usa las imágenes de jumpscare, no los expedientes.
		var card: Control = _make_card(
			Extras.jumpscare_texture(character_id) if seen else null,
			cause if seen else LOCKED_TEXT,
			"visto" if seen else "",
			"Clic para verlo otra vez." if seen else "")
		if seen:
			card.gui_input.connect(_on_jumpscare_input.bind(character_id))
			card.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(card)


## Clic en una ficha: se reproduce. El de Mamador no es un salto, es la
## pantalla de WASTED, igual que en la noche.
func _on_jumpscare_input(event: InputEvent, character_id: String) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if character_id == "mamador":
		_wasted.play(JumpscareOverlay.mamador_image(), JumpscareOverlay.mamador_text())
		return
	_jumpscare.play(Extras.jumpscare_id(character_id))


func _on_newspaper_input(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	NewspaperScreen.pending_index = index
	NewspaperScreen.next_scene = Screens.EXTRAS_MENU
	get_tree().change_scene_to_file(Screens.NEWSPAPER)


## La rejilla va centrada en la mitad derecha, que es lo que deja libre la
## columna de secciones.
func _make_grid() -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = CARD_COLUMNS
	grid.add_theme_constant_override("h_separation", CARD_GAP)
	grid.add_theme_constant_override("v_separation", CARD_GAP)
	var region_left: float = size.x * CONTENT_LEFT
	var region_width: float = size.x * (CONTENT_RIGHT - CONTENT_LEFT)
	var grid_width: float = (CARD_SIZE.x + CARD_GAP) * CARD_COLUMNS - CARD_GAP
	grid.position = Vector2(region_left + (region_width - grid_width) * 0.5,
		size.y * GRID_TOP)
	_content.add_child(grid)
	return grid


## Una ficha: la imagen arriba (o el hueco negro si está bloqueada), el nombre,
## el rol y una línea. Sin panel, sin borde y sin sombra.
func _make_card(texture: Texture2D, name_text: String, role_text: String, line_text: String) -> Control:
	var card: Control = Control.new()
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	var name_label: Label = _card_label(name_text, CARD_NAME_SIZE, MenuStyle.TEXT)
	name_label.position = Vector2(8.0, picture.end.y + 6.0)
	name_label.size = Vector2(CARD_SIZE.x - 16.0, 24.0)
	card.add_child(name_label)

	var role_label: Label = _card_label(role_text, CARD_ROLE_SIZE, MenuStyle.DIM)
	role_label.position = Vector2(8.0, picture.end.y + 30.0)
	role_label.size = Vector2(CARD_SIZE.x - 16.0, 20.0)
	card.add_child(role_label)

	var line_label: Label = _card_label(line_text, CARD_ROLE_SIZE, MenuStyle.DIM)
	line_label.position = Vector2(8.0, picture.end.y + 52.0)
	line_label.size = Vector2(CARD_SIZE.x - 16.0, 48.0)
	line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(line_label)
	return card


func _card_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = MenuStyle.label(text, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.clip_text = true
	return label


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.keycode == KEY_ESCAPE and not key.echo:
		get_tree().change_scene_to_file(Screens.MAIN_MENU)
		get_viewport().set_input_as_handled()
		return
	# Con los expedientes abiertos, izquierda y derecha son para pasar página:
	# se las queda la galería, no la lista.
	if _section == Section.DOSSIERS \
			and key.keycode in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D]:
		return
	if _list.handle_key(key):
		get_viewport().set_input_as_handled()

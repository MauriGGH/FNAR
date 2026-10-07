class_name DocumentScreen
extends Control

## Un documento a pantalla completa: el recibo de la noche o la carta de
## despido. La hoja es la imagen tal cual; el nombre del jugador se escribe
## encima con la máquina de escribir, en el renglón que trae la hoja.
##
## Igual que el periódico, quien la abre deja apuntado qué hoja y a dónde ir
## después, porque change_scene_to_file no deja pasar datos.

static var pending_document: String = Documents.DISMISSAL
static var next_scene: String = Screens.MAIN_MENU
## Las hojas que faltan por enseñar. La noche 6 entrega dos seguidas: el recibo
## y la carta de despido.
static var queue: Array[String] = []


## El camino de entrada: una o varias hojas y a dónde ir cuando se acaben.
static func show_documents(tree: SceneTree, documents: Array[String], after: String) -> void:
	if documents.is_empty():
		tree.change_scene_to_file(after)
		return
	queue = documents.duplicate()
	next_scene = after
	pending_document = queue.pop_front()
	tree.change_scene_to_file(Screens.DOCUMENT)

const HINT_TEXT: String = "clic para continuar"
const HINT_SIZE: int = 17
const HINT_COLOR: Color = Color(0.7, 0.72, 0.74, 0.85)
const FADE_IN: float = 0.5
## Lo que hay que esperar antes de poder pasar, para que no se salte sin leer.
const MIN_READ_TIME: float = 0.8

var _texture: Texture2D = null
var _can_continue: bool = false
var _fade: float = 0.0:
	set(value):
		_fade = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_texture = Documents.texture(pending_document)
	var tween: Tween = create_tween()
	tween.tween_property(self, "_fade", 1.0, FADE_IN)
	tween.tween_interval(MIN_READ_TIME)
	tween.tween_callback(_allow_continue)
	_build_hint()


func _allow_continue() -> void:
	_can_continue = true


func _build_hint() -> void:
	var label: Label = Label.new()
	label.text = HINT_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(label, Fonts.typewriter(), HINT_SIZE)
	label.add_theme_color_override("font_color", HINT_COLOR)
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -46.0
	label.offset_bottom = -18.0
	add_child(label)


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed:
		_continue()
		accept_event()


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo \
			and key.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		_continue()
		get_viewport().set_input_as_handled()


func _continue() -> void:
	if not _can_continue:
		return
	# Si quedan hojas, se recarga esta misma pantalla con la siguiente.
	if not queue.is_empty():
		pending_document = queue.pop_front()
		get_tree().reload_current_scene()
		return
	get_tree().change_scene_to_file(next_scene)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0))
	if _texture == null:
		return
	# La hoja llena la pantalla: las imágenes vienen ya a 16:9.
	draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false,
		Color(1.0, 1.0, 1.0, _fade))
	_draw_name()


## El nombre, inclinado como si lo hubieran escrito a máquina sobre el renglón.
## La posición marca la esquina superior izquierda, así que hay que bajar por el
## ascenso de la fuente para dar con la línea base que pide draw_string.
func _draw_name() -> void:
	var font: Font = Fonts.typewriter()
	if font == null:
		return
	var font_size: int = Documents.name_font_size(size.y)
	var at: Vector2 = Documents.name_position(pending_document) * size
	draw_set_transform(at, Documents.name_tilt(pending_document), Vector2.ONE)
	draw_string(font, Vector2(0.0, font.get_ascent(font_size)), GameManager.player_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(Documents.INK, _fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

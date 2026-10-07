class_name DesktopIcon
extends Control

## Ícono del escritorio, dibujado a mano para no depender de imágenes.
## Diseño propio: nada de logos ni marcas.

signal pressed(icon_id: String)

enum Glyph { TERMINAL, NETWORK, TASKS, CLAUDIO }

const ICON_SIZE: Vector2 = Vector2(104.0, 102.0)
const GLYPH_SIZE: float = 56.0
const GLYPH_TOP: float = 6.0

const SELECTION_COLOR: Color = Color(0.25, 0.55, 0.65, 0.35)
const SELECTION_BORDER: Color = Color(0.55, 0.85, 0.9, 0.7)
const INK: Color = Color(0.82, 0.88, 0.9)
const SCREEN_INK: Color = Color(0.1, 0.14, 0.16)
const GREEN_INK: Color = Color(0.4, 0.95, 0.5)
const PAPER: Color = Color(0.76, 0.75, 0.68)
## El crema de Claudio, el mismo de su ventana.
const CREAM: Color = Color(0.96, 0.93, 0.86)

var icon_id: String = ""
var glyph: Glyph = Glyph.TERMINAL

var _hovered: bool = false
var _label: Label = null


func setup(new_id: String, new_glyph: Glyph, text: String) -> void:
	icon_id = new_id
	glyph = new_glyph
	name = new_id
	custom_minimum_size = ICON_SIZE
	size = ICON_SIZE
	_label = Label.new()
	_label.text = text
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(0.0, GLYPH_TOP + GLYPH_SIZE + 4.0)
	_label.size = Vector2(ICON_SIZE.x, 34.0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 17)
	add_child(_label)


func _ready() -> void:
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func _on_hover(hovered: bool) -> void:
	_hovered = hovered
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	pressed.emit(icon_id)
	accept_event()


func _draw() -> void:
	if _hovered:
		draw_rect(Rect2(Vector2.ZERO, size), SELECTION_COLOR)
		draw_rect(Rect2(Vector2.ZERO, size), SELECTION_BORDER, false, 1.0)

	var origin: Vector2 = Vector2((size.x - GLYPH_SIZE) * 0.5, GLYPH_TOP)
	var box: Rect2 = Rect2(origin, Vector2(GLYPH_SIZE, GLYPH_SIZE))
	match glyph:
		Glyph.TERMINAL:
			_draw_terminal(box)
		Glyph.NETWORK:
			_draw_network(box)
		Glyph.TASKS:
			_draw_tasks(box)
		Glyph.CLAUDIO:
			_draw_claudio(box)


## Monitor con el prompt y el cursor.
func _draw_terminal(box: Rect2) -> void:
	draw_rect(box, SCREEN_INK)
	draw_rect(box, INK, false, 2.0)
	var line_y: float = box.position.y + 16.0
	var left: float = box.position.x + 9.0
	draw_line(Vector2(left, line_y), Vector2(left + 7.0, line_y + 6.0), GREEN_INK, 2.0)
	draw_line(Vector2(left + 7.0, line_y + 6.0), Vector2(left, line_y + 12.0), GREEN_INK, 2.0)
	draw_rect(Rect2(Vector2(left + 13.0, line_y + 2.0), Vector2(18.0, 3.0)), GREEN_INK)
	draw_rect(Rect2(Vector2(left, line_y + 20.0), Vector2(9.0, 10.0)), GREEN_INK)


## Tres equipos unidos por cables.
func _draw_network(box: Rect2) -> void:
	var top: Vector2 = box.position + Vector2(box.size.x * 0.5, 10.0)
	var left: Vector2 = box.position + Vector2(10.0, box.size.y - 14.0)
	var right: Vector2 = box.position + Vector2(box.size.x - 10.0, box.size.y - 14.0)
	draw_line(top, left, INK, 2.0)
	draw_line(top, right, INK, 2.0)
	draw_line(left, right, INK, 2.0)
	for point: Vector2 in [top, left, right]:
		var node_box: Rect2 = Rect2(point - Vector2(9.0, 7.0), Vector2(18.0, 14.0))
		draw_rect(node_box, SCREEN_INK)
		draw_rect(node_box, GREEN_INK, false, 2.0)


## Tabla de tareas con su paloma.
func _draw_tasks(box: Rect2) -> void:
	draw_rect(box, PAPER)
	draw_rect(box, INK, false, 2.0)
	draw_rect(Rect2(box.position + Vector2(box.size.x * 0.3, -4.0), Vector2(box.size.x * 0.4, 9.0)), SCREEN_INK)
	for i: int in 3:
		var y: float = box.position.y + 20.0 + i * 11.0
		draw_rect(Rect2(Vector2(box.position.x + 9.0, y), Vector2(box.size.x - 26.0, 3.0)), SCREEN_INK)
	var check: Vector2 = box.position + Vector2(box.size.x - 20.0, box.size.y - 22.0)
	draw_line(check, check + Vector2(5.0, 6.0), GREEN_INK, 3.0)
	draw_line(check + Vector2(5.0, 6.0), check + Vector2(14.0, -8.0), GREEN_INK, 3.0)


## El logo de Claudio sobre su cuadrito crema.
func _draw_claudio(box: Rect2) -> void:
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = CREAM
	card.set_corner_radius_all(8)
	card.set_border_width_all(2)
	card.border_color = ClaudioLogo.ORANGE_DARK
	draw_style_box(card, box)
	ClaudioLogo.draw_logo(self, box.get_center(), box.size.x * 0.34)

class_name PcWindow
extends Control

## Marco de ventana del escritorio retro: cuerpo, barra de título, botón de
## cerrar y arrastre por la barra de título. El contenido de cada ventana son
## sus hijos normales, puestos a partir de los 30 px de arriba.

signal close_requested()
## Avisa que le hicieron clic, para pasar al frente de las demás ventanas.
signal focused()

@export var window_title: String = "Ventana"
@export var closable: bool = true
## La ventana de Claudio tiene su propia paleta (crema y naranja terracota),
## así que los colores se pueden cambiar por ventana en vez de estar fijos.
@export var body_color: Color = BODY_COLOR
@export var title_color: Color = TITLE_COLOR
@export var border_color: Color = BORDER_COLOR
@export var title_text_color: Color = Color(1.0, 1.0, 1.0)
## Si es true, dibuja el logo de Claudio a la izquierda del título.
@export var show_claudio_logo: bool = false

const TITLE_HEIGHT: float = 28.0
const BODY_COLOR: Color = Color(0.1, 0.12, 0.15)
const TITLE_COLOR: Color = Color(0.08, 0.32, 0.34)
const BORDER_COLOR: Color = Color(0.42, 0.56, 0.58)
const TITLE_FONT_SIZE: int = 18
## Hueco que se le deja al logo de Claudio en la barra de título.
const LOGO_SPACE: float = 30.0
const LOGO_RADIUS: float = 8.5

var title_label: Label = null

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # La ventana no deja pasar clics al escritorio.
	resized.connect(_layout_chrome)

	title_label = Label.new()
	title_label.text = window_title
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.add_theme_color_override("font_color", title_text_color)
	add_child(title_label)

	if closable:
		var close_button: Button = Button.new()
		close_button.name = "CloseButton"
		close_button.text = "X"
		close_button.focus_mode = Control.FOCUS_NONE
		close_button.add_theme_font_size_override("font_size", 15)
		close_button.pressed.connect(close_requested.emit)
		add_child(close_button)

	_layout_chrome()


func set_window_title(text: String) -> void:
	window_title = text
	if title_label != null:
		title_label.text = text


func _layout_chrome() -> void:
	if title_label != null:
		# Con logo, el título se corre para dejarle su hueco.
		var left: float = LOGO_SPACE if show_claudio_logo else 10.0
		title_label.position = Vector2(left, 2.0)
		title_label.size = Vector2(maxf(size.x - left - 36.0, 10.0), TITLE_HEIGHT - 4.0)
	var close_button: Button = get_node_or_null("CloseButton")
	if close_button != null:
		close_button.position = Vector2(size.x - 28.0, 3.0)
		close_button.size = Vector2(24.0, TITLE_HEIGHT - 6.0)
	queue_redraw()


## Cualquier clic en la ventana la trae al frente, pero no se consume: el
## control de abajo (un botón, la consola) igual recibe el clic.
## Y si el clic cae en la barra de título, la ventana se arrastra.
func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed:
			focused.emit()
			if click.position.y <= TITLE_HEIGHT:
				_dragging = true
				_drag_offset = click.position
		else:
			_dragging = false
		return

	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null or not _dragging:
		return
	position += motion.position - _drag_offset
	_clamp_inside_parent()


## La ventana no se puede sacar del escritorio.
func _clamp_inside_parent() -> void:
	var parent: Control = get_parent() as Control
	if parent == null:
		return
	position = position.clamp(Vector2.ZERO, (parent.size - size).max(Vector2.ZERO))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), body_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, TITLE_HEIGHT)), title_color)
	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 1.0)
	if show_claudio_logo:
		ClaudioLogo.draw_logo(self, Vector2(14.0, TITLE_HEIGHT * 0.5), LOGO_RADIUS)

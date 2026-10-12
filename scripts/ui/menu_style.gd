class_name MenuStyle
extends RefCounted

## El acabado de todos los menús, en un solo lugar: negro, VT323 blanco y nada
## más. Sin paneles grises, sin bordes redondeados, sin sombras y sin degradados,
## como los menús de los juegos originales.
##
## Quedan fuera a propósito la PC, el patch panel y las hojas (documentos,
## recibos, periódicos), que tienen su propia estética.

## Todo está medido a 1080p y se escala con el alto de la ventana.
const REFERENCE_HEIGHT: float = 1080.0

## El tamaño de cada cosa, a 1080p. Van grandes a propósito: en una pantalla
## de verdad, y de lejos, lo chico no se lee.
const TITLE_SIZE: float = 56.0
const OPTION_SIZE: float = 44.0
const SMALL_SIZE: float = 22.0

const TEXT: Color = Color(0.95, 0.95, 0.93)
## Lo secundario (pies de pantalla, valores, notas).
const DIM: Color = Color(0.68, 0.7, 0.72)
## Lo que no se puede elegir.
const DISABLED: Color = Color(0.32, 0.33, 0.35)
const MARKER_COLOR: Color = Color(0.98, 0.84, 0.35)

## El negro de las capas que se abren encima de algo (la pausa, las opciones).
## El negro de una capa que se abre encima de otro menú. Va al 90 %: lo de
## abajo no se tiene que poder leer.
const BACKDROP: Color = Color(0.0, 0.0, 0.0, 0.9)

## La columna de texto: dónde empieza el marcador y dónde el texto.
const LEFT_MARGIN: float = 0.055
const TEXT_INDENT: float = 0.105


## El tamaño de letra que toca para esta ventana.
static func font_size(base: float, screen_height: float) -> int:
	return maxi(10, roundi(base * screen_height / REFERENCE_HEIGHT))


## Una etiqueta de menú: VT323, sin fondo y que no estorba al mouse.
static func label(text: String, color: Color = TEXT) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font", Fonts.terminal())
	node.add_theme_color_override("font_color", color)
	return node


## El negro de fondo de una capa. Devuelve el rectángulo, ya metido.
static func backdrop(parent: Control, color: Color = BACKDROP) -> ColorRect:
	var dim: ColorRect = ColorRect.new()
	dim.name = "Backdrop"
	dim.color = color
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dim)
	return dim


## El título de una pantalla: VT323 grande y en mayúsculas, a la izquierda.
## Hay que colocarlo con place_title() cuando se sepa el tamaño.
static func title(parent: Control, text: String) -> Label:
	var node: Label = label(text.to_upper(), TEXT)
	node.name = "Title"
	parent.add_child(node)
	return node


## Coloca el título en la esquina de arriba a la izquierda de la columna.
static func place_title(node: Label, screen: Vector2, top: float = 0.08) -> void:
	if node == null:
		return
	node.add_theme_font_size_override("font_size", font_size(TITLE_SIZE, screen.y))
	node.position = Vector2(screen.x * LEFT_MARGIN, screen.y * top)
	node.size = Vector2(screen.x * 0.8, screen.y * 0.1)


## El pie de pantalla, chiquito y centrado abajo: "Esc para volver" y demás.
static func hint(parent: Control, text: String) -> Label:
	var node: Label = label(text, DIM)
	node.name = "Hint"
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	node.offset_top = -56.0
	node.offset_bottom = -22.0
	parent.add_child(node)
	return node


## Vuelve a poner el tamaño del pie, que también se escala.
static func place_hint(node: Label, screen: Vector2) -> void:
	if node != null:
		node.add_theme_font_size_override("font_size", font_size(SMALL_SIZE, screen.y))


## El blip de moverse por un menú y el de aceptar, que es el mismo un poco más
## agudo. Los menús no los piden a mano: los toca MenuList.
const ACCEPT_PITCH: float = 1.25


static func blip(accept: bool = false) -> void:
	AudioManager.set_pitch(Sounds.MENU_BLIP, ACCEPT_PITCH if accept else 1.0)
	AudioManager.play(Sounds.MENU_BLIP)

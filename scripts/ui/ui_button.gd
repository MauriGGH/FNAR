class_name UiButton
extends RefCounted

## Botones de menú con el mismo acabado en todas las pantallas: gris
## translúcido con borde fino, como la barra de cámaras. Los bloqueados se
## ven apagados y con un candado en el texto.

const SIZE: Vector2 = Vector2(420.0, 56.0)
const FONT_SIZE: int = 28
const IDLE: Color = Color(0.1, 0.11, 0.13, 0.72)
const HOVER: Color = Color(0.18, 0.2, 0.23, 0.85)
const PRESSED: Color = Color(0.26, 0.28, 0.32, 0.9)
const LOCKED_FILL: Color = Color(0.08, 0.08, 0.09, 0.55)
const BORDER: Color = Color(0.84, 0.86, 0.88, 0.75)
const LOCKED_BORDER: Color = Color(0.45, 0.46, 0.48, 0.5)
const TEXT: Color = Color(0.93, 0.94, 0.95)
const LOCKED_TEXT: Color = Color(0.52, 0.53, 0.55)
const LOCKED_SUFFIX: String = "  (bloqueado)"


## Un botón listo para meter en un contenedor. locked lo deja inservible.
static func make(text: String, locked: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = text + (LOCKED_SUFFIX if locked else "")
	button.disabled = locked
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = SIZE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", LOCKED_TEXT)
	button.add_theme_stylebox_override("normal", _box(IDLE, BORDER))
	button.add_theme_stylebox_override("hover", _box(HOVER, BORDER))
	button.add_theme_stylebox_override("pressed", _box(PRESSED, BORDER))
	button.add_theme_stylebox_override("disabled", _box(LOCKED_FILL, LOCKED_BORDER))
	return button


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.set_border_width_all(2)
	box.border_color = border
	box.set_corner_radius_all(3)
	box.set_content_margin_all(8.0)
	return box

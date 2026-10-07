class_name Fonts
extends RefCounted

## Las tres tipografías del juego, en un solo lugar. El Theme global pone
## Oswald en todo (menús, botones, etiquetas); las otras dos se piden aquí y se
## ponen como override donde toca.
##
## - VT323: lo que sale de una pantalla o un aparato (cámaras, PC, relojes).
## - Special Elite: lo escrito a máquina (documentos, causa de game over,
##   intro de noche).
## - Oswald: menús y botones.
##
## Las fuentes se cargan una vez y se quedan en caché, porque varias pantallas
## piden la misma.

const TERMINAL_PATH: String = "res://assets/fonts/VT323-Regular.ttf"
const TYPEWRITER_PATH: String = "res://assets/fonts/SpecialElite-Regular.ttf"
const MENU_PATH: String = "res://assets/fonts/Oswald-Variable.ttf"

## El peso de Oswald para los títulos. Es una fuente variable, así que el grosor
## se pide por eje en vez de cargar otro archivo.
const MENU_BOLD_WEIGHT: int = 600

static var _cache: Dictionary = {}


## La de las pantallas y los aparatos.
static func terminal() -> Font:
	return _load_font(TERMINAL_PATH)


## La de máquina de escribir.
static func typewriter() -> Font:
	return _load_font(TYPEWRITER_PATH)


## La de los menús.
static func menu() -> Font:
	return _load_font(MENU_PATH)


## Oswald en grueso, para títulos.
static func menu_bold() -> Font:
	if _cache.has("menu_bold"):
		return _cache["menu_bold"] as Font
	var base: Font = menu()
	if base == null:
		return null
	var variation: FontVariation = FontVariation.new()
	variation.base_font = base
	variation.variation_opentype = {"wght": MENU_BOLD_WEIGHT}
	_cache["menu_bold"] = variation
	return variation


## Le pone fuente y tamaño a un Label, un Button o cualquier Control, sin que
## cada pantalla tenga que repetir los dos overrides.
static func apply(control: Control, font: Font, font_size: int = 0) -> void:
	if control == null:
		return
	if font != null:
		control.add_theme_font_override("font", font)
	if font_size > 0:
		control.add_theme_font_size_override("font_size", font_size)


static func _load_font(path: String) -> Font:
	if _cache.has(path):
		return _cache[path] as Font
	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null
	var font: Font = load(path) as Font
	_cache[path] = font
	return font

class_name Fonts
extends RefCounted

## Las tres tipografías del juego, en un solo lugar. El Theme global pone
## Oswald en todo (menús, botones, etiquetas); las otras dos se piden aquí y se
## ponen como override donde toca.
##
## - VT323: lo que sale de una pantalla o un aparato (cámaras, PC, relojes).
## - Special Elite: lo escrito a máquina (documentos, hojas, formularios).
## - Oswald: menús y botones.
## - Share Tech Mono: el reloj de la intro de noche.
## - DSEG14 Classic: el display de siete segmentos del 6 AM.
## - Reenie Beanie: lo escrito a mano (la firma y la nota del recibo).
##
## Las fuentes se cargan una vez y se quedan en caché, porque varias pantallas
## piden la misma.

const TERMINAL_PATH: String = "res://assets/fonts/VT323-Regular.ttf"
const TYPEWRITER_PATH: String = "res://assets/fonts/SpecialElite-Regular.ttf"
const MENU_PATH: String = "res://assets/fonts/Oswald-Variable.ttf"
## La de los titulones tipo GTA (la pantalla de WASTED). Si no está, se cae a
## Oswald en negritas, que es lo más parecido que hay en el proyecto.
const DISPLAY_PATH: String = "res://assets/fonts/pricedown.otf"
## La monoespaciada de la intro de noche.
const MONO_PATH: String = "res://assets/fonts/ShareTechMono-Regular.ttf"
## La de segmentos, la del reloj de las 6 AM.
const DIGITAL_PATH: String = "res://assets/fonts/DSEG14Classic-Bold.ttf"
## La de puño y letra: la firma de la solicitud y la nota del recibo.
const HAND_PATH: String = "res://assets/fonts/ReenieBeanie-Regular.ttf"

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


## La de los titulones. Si falta, Oswald en grueso.
static func display() -> Font:
	var font: Font = _load_font(DISPLAY_PATH)
	return font if font != null else menu_bold()


## La monoespaciada de la intro de noche.
static func mono() -> Font:
	return _load_font(MONO_PATH)


## La de segmentos del reloj de las 6 AM.
static func digital() -> Font:
	return _load_font(DIGITAL_PATH)


## La escrita a mano.
static func hand() -> Font:
	return _load_font(HAND_PATH)


## La fuente que pide un dato por su nombre (lo que traen los campos de
## data/pantallas_campos.json). Si no se reconoce, la de los menús.
static func by_name(font_name: String) -> Font:
	match font_name:
		"VT323":
			return terminal()
		"SpecialElite":
			return typewriter()
		"ShareTechMono":
			return mono()
		"DSEG14":
			return digital()
		"ReenieBeanie":
			return hand()
	return menu()


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

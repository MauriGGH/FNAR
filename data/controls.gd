class_name Controls
extends RefCounted

## Los controles de verdad del juego, para el tutorial de la noche 1 y para el
## botón "Controles" de la pausa.
##
## No se inventa ninguna tecla aquí. Las que están en el mapa de entrada se
## leen del mapa (si cambias la tecla en project.godot, el tutorial cambia
## solo). Las que estaban a fuego en el código se definen **una sola vez** en
## este archivo y los scripts que las usan las piden de aquí, así que tampoco
## pueden desincronizarse.

# --- Acciones del mapa de entrada --------------------------------------------
const ACTION_TURN_LEFT: String = "turn_left"
const ACTION_TURN_RIGHT: String = "turn_right"
const ACTION_CAMERAS: String = "toggle_cameras"

# --- Teclas que no pasan por el mapa -----------------------------------------
## La linterna se mantiene con esta tecla. La usa office.gd.
const FLASHLIGHT_KEY: Key = KEY_CTRL
## La pausa. La usa pause_menu.gd, y también cierra el tutorial.
const PAUSE_KEY: Key = KEY_ESCAPE


## Las líneas del tutorial: {"keys": lo que hay que pulsar, "what": para qué}.
static func lines() -> Array[Dictionary]:
	var look: String = "%s  /  %s" % [keys_of(ACTION_TURN_LEFT), keys_of(ACTION_TURN_RIGHT)]
	return [
		{"keys": look, "what": "Cambiar de vista (el mouse mueve la que ves)"},
		{"keys": keys_of(ACTION_CAMERAS), "what": "Abrir y cerrar el monitor"},
		{"keys": "Clic", "what": "Cambiar de cámara: en el mapa del monitor"},
		{"keys": key_name(FLASHLIGHT_KEY), "what": "Linterna: mantener (o clic en el cristal)"},
		{"keys": "Clic", "what": "Puerta: la caja de la chapa"},
		{"keys": "Clic", "what": "Breaker: en la vista de la izquierda"},
		{"keys": "Clic", "what": "PC: el monitor del escritorio"},
		{"keys": "Clic", "what": "Llamada: el botón de silenciar"},
		{"keys": key_name(PAUSE_KEY), "what": "Pausa"},
	]


## Las teclas de una acción, tal como están en el mapa de entrada, separadas
## por barras. Vacío si la acción no existe.
static func keys_of(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	var names: PackedStringArray = PackedStringArray()
	for event: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key == null:
			continue
		var code: Key = key.physical_keycode if key.physical_keycode != 0 else key.keycode
		var name: String = key_name(code)
		if not name.is_empty() and not name in names:
			names.append(name)
	return " / ".join(names)


## El nombre corto de una tecla, para enseñarlo en pantalla.
static func key_name(code: Key) -> String:
	match code:
		KEY_LEFT:
			return "←"
		KEY_RIGHT:
			return "→"
		KEY_UP:
			return "↑"
		KEY_DOWN:
			return "↓"
		KEY_SPACE:
			return "Espacio"
		KEY_ESCAPE:
			return "Esc"
		KEY_CTRL:
			return "Ctrl"
	return OS.get_keycode_string(code)

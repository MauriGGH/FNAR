class_name DebugKeys
extends RefCounted

## Lo único que queda del viejo sistema de teclas: F1 abre y cierra el panel
## de pruebas. Todo lo demás se hace con botones dentro del panel, así no hay
## que acordarse de ninguna combinación.
##
## El interruptor vive en NightConfig, junto a TEST_MODE. Con
## NightConfig.DEBUG_KEYS en false ni F1 responde y el panel no existe.

## La tecla que abre y cierra el panel de pruebas.
const TOGGLE_KEY: Key = KEY_F1


## true si el panel de pruebas está disponible en esta compilación.
static func is_enabled() -> bool:
	return NightConfig.DEBUG_KEYS


## true si el evento es F1 y la depuración está encendida.
static func is_toggle(event: InputEvent) -> bool:
	if not is_enabled():
		return false
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	return key.keycode == TOGGLE_KEY


## El nombre de la tecla, para enseñarlo en pantalla.
static func toggle_label() -> String:
	return OS.get_keycode_string(TOGGLE_KEY)

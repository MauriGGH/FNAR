class_name DebugKeys
extends RefCounted

## Todas las teclas de depuración en un solo lugar: la tecla, la acción y la
## descripción que sale en la ayuda de F3. Antes estaban repartidas como
## literales por cada script de profe, así que no había manera de listarlas.
##
## Con DEBUG_KEYS en false ninguna responde y la ayuda no se enseña: así va
## la versión para amigos, sin tener que tocar ni un script de personaje.

## El interruptor general. En la versión para jugar, false.
const DEBUG_KEYS: bool = true

# Las acciones, por nombre, para que nadie se equivoque escribiendo la cadena.
const HELP: String = "help"
const INFINITE_POWER: String = "infinite_power"
const BARCOSA_RUN: String = "barcosa_run"
const MAMADOR_HALLWAY: String = "mamador_hallway"
const COME_TRABAS_WIND: String = "come_trabas_wind"
const AUDEL_DISCHARGE: String = "audel_discharge"
const AUDEL_LADDER: String = "audel_ladder"
const URENA_GLASS: String = "urena_glass"
const URENA_CALL: String = "urena_call"
const ROCHIS_STAND: String = "rochis_stand"
const JUAN_GLASS: String = "juan_glass"
const ARMANDO_GLASS: String = "armando_glass"
const ARMANDO_PC: String = "armando_pc"

## El registro, en el orden en que sale en la ayuda.
const KEYS: Array[Dictionary] = [
	{"key": KEY_F3, "action": HELP, "text": "esta ayuda, las zonas de clic y el estado de los profes"},
	{"key": KEY_F8, "action": INFINITE_POWER, "text": "energía infinita"},
	{"key": KEY_F4, "action": BARCOSA_RUN, "text": "Barcosa sale corriendo"},
	{"key": KEY_F6, "action": MAMADOR_HALLWAY, "text": "Mamador al pasillo norte"},
	{"key": KEY_F7, "action": COME_TRABAS_WIND, "text": "cuerda del Come Trabas al 5 %"},
	{"key": KEY_F9, "action": AUDEL_DISCHARGE, "text": "descarga del pararrayos"},
	{"key": KEY_F10, "action": AUDEL_LADDER, "text": "Mago Eléctrico a la escalera"},
	{"key": KEY_1, "action": URENA_GLASS, "text": "Ureña al cristal"},
	{"key": KEY_2, "action": URENA_CALL, "text": "llamada de Ureña"},
	{"key": KEY_3, "action": ROCHIS_STAND, "text": "Rochis de pie"},
	{"key": KEY_5, "action": JUAN_GLASS, "text": "Juan.exe al cristal"},
	{"key": KEY_6, "action": ARMANDO_GLASS, "text": "Armando al cristal"},
	{"key": KEY_7, "action": ARMANDO_PC, "text": "Armando toma la pantalla de la PC"},
]


## true si el evento es la tecla de esa acción y la depuración está encendida.
## Ya filtra las repeticiones por tecla mantenida.
static func matches(event: InputEvent, action: String) -> bool:
	if not DEBUG_KEYS:
		return false
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	return key.keycode == key_of(action)


## La tecla de una acción, o KEY_NONE si no está en el registro.
static func key_of(action: String) -> Key:
	for entry: Dictionary in KEYS:
		if str(entry["action"]) == action:
			return entry["key"] as Key
	return KEY_NONE


## El nombre de la tecla de una acción, para enseñarlo en pantalla.
static func label_of(action: String) -> String:
	var key: Key = key_of(action)
	return "" if key == KEY_NONE else OS.get_keycode_string(key)


## La ayuda de F3, una línea por tecla.
static func help_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if not DEBUG_KEYS:
		return lines
	lines.append("[DEPURACIÓN]")
	for entry: Dictionary in KEYS:
		lines.append("%s  %s" % [OS.get_keycode_string(entry["key"] as Key), entry["text"]])
	return lines

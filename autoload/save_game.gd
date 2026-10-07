extends Node

## Autoload. El archivo de guardado, en user://save.cfg. Guarda lo mínimo:
## hasta qué noche llegó el jugador, su nombre, qué recortes de periódico y
## qué expedientes lleva desbloqueados, y qué jumpscares ya vio.
##
## Se escribe en cuanto algo cambia, así que cerrar el juego de golpe no
## pierde nada. Si el archivo no existe o está roto, se empieza de cero sin
## quejarse.

signal changed()

const SAVE_PATH: String = "user://save.cfg"

const SECTION_PROGRESS: String = "progreso"
const SECTION_UNLOCKS: String = "desbloqueos"

## La noche a la que puede entrar "Continuar". Empieza en la 1.
var night_reached: int = 1
var player_name: String = GameManager.PLAYER_NAME

## Ids de lo desbloqueado. Se guardan como listas para poder crecer sin
## tocar el formato del archivo.
var newspapers: Array[int] = []
var dossiers: Array[String] = []
var jumpscares: Array[String] = []


func _ready() -> void:
	load_game()


## true si ya hay una partida empezada que valga la pena continuar.
func has_progress() -> bool:
	return night_reached > 1 or not newspapers.is_empty()


## true si ya pasó la noche que hace falta para Custom Night y Extras.
func is_extras_unlocked() -> bool:
	return night_reached > NightConfig.EXTRAS_FROM_NIGHT


func set_player_name(new_name: String) -> void:
	player_name = _clean_name(new_name)
	GameManager.player_name = player_name
	save_game()


## Deja apuntado que pasó esa noche: la siguiente queda disponible.
func mark_night_cleared(night: int) -> void:
	night_reached = maxi(night_reached, mini(night + 1, NightConfig.LAST_NIGHT))
	save_game()


func unlock_newspaper(index: int) -> void:
	if index in newspapers:
		return
	newspapers.append(index)
	newspapers.sort()
	save_game()


func unlock_dossier(character_id: String) -> void:
	if character_id.is_empty() or character_id in dossiers:
		return
	dossiers.append(character_id)
	save_game()


func unlock_jumpscare(cause: String) -> void:
	if cause.is_empty() or cause in jumpscares:
		return
	jumpscares.append(cause)
	save_game()


func has_newspaper(index: int) -> bool:
	return index in newspapers


func has_dossier(character_id: String) -> bool:
	return character_id in dossiers


func has_jumpscare(cause: String) -> bool:
	return cause in jumpscares


## Borra la partida. La usa "Nueva partida".
func reset() -> void:
	night_reached = 1
	newspapers.clear()
	dossiers.clear()
	jumpscares.clear()
	save_game()


func save_game() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION_PROGRESS, "night_reached", night_reached)
	file.set_value(SECTION_PROGRESS, "player_name", player_name)
	file.set_value(SECTION_UNLOCKS, "newspapers", newspapers)
	file.set_value(SECTION_UNLOCKS, "dossiers", dossiers)
	file.set_value(SECTION_UNLOCKS, "jumpscares", jumpscares)
	file.save(SAVE_PATH)
	changed.emit()


func load_game() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return  # Primera vez: se queda con los valores de arranque.
	night_reached = clampi(int(file.get_value(SECTION_PROGRESS, "night_reached", 1)),
		1, NightConfig.LAST_NIGHT)
	player_name = _clean_name(str(file.get_value(SECTION_PROGRESS, "player_name", player_name)))
	newspapers = _to_int_array(file.get_value(SECTION_UNLOCKS, "newspapers", []))
	dossiers = _to_string_array(file.get_value(SECTION_UNLOCKS, "dossiers", []))
	jumpscares = _to_string_array(file.get_value(SECTION_UNLOCKS, "jumpscares", []))
	GameManager.player_name = player_name


## El nombre no puede quedar vacío ni pasarse de largo.
func _clean_name(raw: String) -> String:
	var clean: String = raw.strip_edges()
	if clean.is_empty():
		return GameManager.PLAYER_NAME
	return clean.substr(0, NightConfig.MAX_NAME_LENGTH)


func _to_int_array(value: Variant) -> Array[int]:
	var out: Array[int] = []
	for item: Variant in (value as Array if value is Array else []):
		out.append(int(item))
	return out


func _to_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	for item: Variant in (value as Array if value is Array else []):
		out.append(str(item))
	return out

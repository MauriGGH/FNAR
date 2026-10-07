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
const SECTION_OPTIONS: String = "opciones"

## El volumen de arranque de cada bus, antes de que el jugador toque nada.
const DEFAULT_BUS_VOLUME: float = 0.8

## La noche a la que puede entrar "Continuar". Empieza en la 1.
var night_reached: int = 1
var player_name: String = GameManager.PLAYER_NAME

## Ids de lo desbloqueado. Se guardan como listas para poder crecer sin
## tocar el formato del archivo.
var newspapers: Array[int] = []
var dossiers: Array[String] = []
var jumpscares: Array[String] = []
var documents: Array[String] = []

## Las noches que se pasaron de verdad. night_reached no sirve para esto: se
## topa en la última, así que pasar la 5 y pasar la 6 lo dejan igual, y las
## estrellas del menú sí tienen que distinguirlas.
var nights_cleared: Array[int] = []
## Ganar una Custom Night con los ocho profes en 20, que vale la tercera estrella.
var custom_mastered: bool = false
## Los retos de Custom Night que ya se ganaron, por su id.
var challenges_won: Array[String] = []

## Opciones. La pantalla completa la pone y la lee DisplayManager.
var fullscreen: bool = true
## El volumen de cada bus de audio, de 0 a 1. Lo pone y lo lee AudioManager.
var bus_volumes: Dictionary = {}


func _ready() -> void:
	load_game()


## true si ya hay una partida empezada que valga la pena continuar.
func has_progress() -> bool:
	return night_reached > 1 or not newspapers.is_empty()


## true si ya pasó la noche que hace falta para Custom Night y Extras.
func is_extras_unlocked() -> bool:
	return night_reached > NightConfig.EXTRAS_FROM_NIGHT


## El volumen de un bus, de 0 a 1. Lo que no se ha tocado nunca arranca al 80 %,
## que deja margen para subirlo sin que sature.
func bus_volume(bus: String) -> float:
	return clampf(float(bus_volumes.get(bus, DEFAULT_BUS_VOLUME)), 0.0, 1.0)


func set_bus_volume(bus: String, value: float) -> void:
	var clamped: float = clampf(value, 0.0, 1.0)
	if is_equal_approx(bus_volume(bus), clamped):
		return
	bus_volumes[bus] = clamped
	save_game()


func set_fullscreen(enabled: bool) -> void:
	if fullscreen == enabled:
		return
	fullscreen = enabled
	save_game()


func set_player_name(new_name: String) -> void:
	player_name = _clean_name(new_name)
	GameManager.player_name = player_name
	save_game()


## Deja apuntado que pasó esa noche: la siguiente queda disponible.
func mark_night_cleared(night: int) -> void:
	night_reached = maxi(night_reached, mini(night + 1, NightConfig.LAST_NIGHT))
	if not night in nights_cleared:
		nights_cleared.append(night)
		nights_cleared.sort()
	save_game()


func has_cleared_night(night: int) -> bool:
	return night in nights_cleared


## Ganó una Custom Night con todo en 20.
func mark_custom_mastered() -> void:
	if custom_mastered:
		return
	custom_mastered = true
	save_game()


## Deja apuntado que se ganó un reto de Custom Night.
func mark_challenge_won(challenge_id: String) -> void:
	if challenge_id.is_empty() or challenge_id in challenges_won:
		return
	challenges_won.append(challenge_id)
	save_game()


func has_won_challenge(challenge_id: String) -> bool:
	return challenge_id in challenges_won


## Las estrellas del menú: la noche 5, la noche 6 y la Custom Night al máximo.
func star_count() -> int:
	var stars: int = 0
	if has_cleared_night(NightConfig.EXTRAS_FROM_NIGHT):
		stars += 1
	if has_cleared_night(NightConfig.LAST_NIGHT):
		stars += 1
	if custom_mastered:
		stars += 1
	return stars


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


func unlock_document(document_id: String) -> void:
	if document_id.is_empty() or document_id in documents:
		return
	documents.append(document_id)
	save_game()


func has_document(document_id: String) -> bool:
	return document_id in documents


func has_newspaper(index: int) -> bool:
	return index in newspapers


func has_dossier(character_id: String) -> bool:
	return character_id in dossiers


func has_jumpscare(cause: String) -> bool:
	return cause in jumpscares


## Borra la partida. Las opciones no son progreso: la pantalla completa se queda.
func reset() -> void:
	night_reached = 1
	newspapers.clear()
	dossiers.clear()
	jumpscares.clear()
	documents.clear()
	nights_cleared.clear()
	custom_mastered = false
	challenges_won.clear()
	save_game()


func save_game() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION_PROGRESS, "night_reached", night_reached)
	file.set_value(SECTION_PROGRESS, "player_name", player_name)
	file.set_value(SECTION_UNLOCKS, "newspapers", newspapers)
	file.set_value(SECTION_UNLOCKS, "dossiers", dossiers)
	file.set_value(SECTION_UNLOCKS, "jumpscares", jumpscares)
	file.set_value(SECTION_UNLOCKS, "documents", documents)
	file.set_value(SECTION_PROGRESS, "nights_cleared", nights_cleared)
	file.set_value(SECTION_PROGRESS, "custom_mastered", custom_mastered)
	file.set_value(SECTION_PROGRESS, "challenges_won", challenges_won)
	file.set_value(SECTION_OPTIONS, "fullscreen", fullscreen)
	file.set_value(SECTION_OPTIONS, "bus_volumes", bus_volumes)
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
	documents = _to_string_array(file.get_value(SECTION_UNLOCKS, "documents", []))
	nights_cleared = _to_int_array(file.get_value(SECTION_PROGRESS, "nights_cleared", []))
	custom_mastered = bool(file.get_value(SECTION_PROGRESS, "custom_mastered", false))
	challenges_won = _to_string_array(file.get_value(SECTION_PROGRESS, "challenges_won", []))
	fullscreen = bool(file.get_value(SECTION_OPTIONS, "fullscreen", true))
	bus_volumes = file.get_value(SECTION_OPTIONS, "bus_volumes", {}) as Dictionary
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

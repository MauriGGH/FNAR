extends Node

## Autoload. Lleva el reloj de la noche y decide victoria o game over.
## Todo lo demás se entera por señales; nadie llama a nadie de forma rígida.

signal night_started(night: int)
signal hour_changed(hour: int)  # 0 = 12 AM ... 6 = 6 AM
signal night_won(night: int)
signal game_over(cause: String)
signal task_completed(task_id: String)
signal ai_window_changed(is_open: bool)

## El nombre del guardia. Por ahora es una constante; la pantalla para
## escribirlo llega con el menú (hito 6), y entonces player_name cambiará.
const PLAYER_NAME: String = "Guardia"

var player_name: String = PLAYER_NAME
var current_night: int = 1
var current_hour: int = NightConfig.START_HOUR
var is_night_active: bool = false
var last_game_over_cause: String = ""
## La ventana del Asistente IA sigue abierta aunque el jugador baje la PC:
## es justo lo que delata al guardia ante Mamador.
var is_ai_window_open: bool = false

var _hour_elapsed: float = 0.0
# Quién tiene reservado el pasillo ahora mismo, o null si está libre.
var _hallway_holder: Node = null
# Ids de las tareas que el jugador ya terminó esta noche.
var _completed_tasks: Dictionary = {}
# Las tareas de la noche se sortean una sola vez, al empezar.
var _night_tasks: Array = []

## El patch panel de la sala de servidores: qué puerto le toca a cada cámara y
## cuáles tumbó una descarga de Audel. Es estado de la noche, como las tareas.
var patch_panel: PatchPanelModel = PatchPanelModel.new()
## Mientras el guardia está en la sala de servidores no vigila la oficina.
var is_in_server_room: bool = false

## Custom Night: cuando está activa, los niveles de IA salen de aquí en vez
## de la tabla de data/nights.gd. La clave es la del profe (Nights.BARCOSA...).
var is_custom_night: bool = false
var custom_levels: Dictionary = {}


func _ready() -> void:
	PowerManager.power_depleted.connect(_on_power_depleted)


## Arranca la noche desde las 12 AM con la energía llena.
## Deja lista la noche que se va a jugar, sin arrancarla: la pantalla de
## "12:00 AM / Noche N" va antes, y es night.tscn la que llama a start_night().
func prepare_night(night: int) -> void:
	current_night = clampi(night, 1, NightConfig.LAST_NIGHT)
	is_custom_night = false
	custom_levels.clear()


## Deja lista una Custom Night con los niveles que eligió el jugador.
func prepare_custom_night(levels: Dictionary) -> void:
	current_night = NightConfig.LAST_NIGHT
	is_custom_night = true
	custom_levels = levels.duplicate()


## El nivel que le toca a un profe esta noche: el de la tabla, o el que eligió
## el jugador si es Custom Night.
func ai_level_for(key: String) -> int:
	if is_custom_night:
		return clampi(int(custom_levels.get(key, 0)), 0, Nights.MAX_AI_LEVEL)
	return Nights.ai_level(current_night, key)


func start_night(night: int = current_night) -> void:
	current_night = night
	current_hour = NightConfig.START_HOUR
	_hour_elapsed = 0.0
	last_game_over_cause = ""
	_hallway_holder = null
	_completed_tasks.clear()
	_night_tasks = Tasks.pick_for_night(current_night)
	patch_panel.reset_for_night()
	is_in_server_room = false
	is_ai_window_open = false
	is_night_active = true
	PowerManager.reset()
	PowerManager.set_draining(true)
	night_started.emit(current_night)
	hour_changed.emit(current_hour)


## Termina la noche con una causa de muerte, por ejemplo "Te quedaste sin energía".
func trigger_game_over(cause: String) -> void:
	if not is_night_active:
		return
	is_night_active = false
	PowerManager.set_draining(false)
	last_game_over_cause = cause
	game_over.emit(cause)


# --- Tareas y pago ------------------------------------------------------------

## Tareas que pide la noche actual, sorteadas al empezar.
func night_tasks() -> Array:
	return _night_tasks


func complete_task(task_id: String) -> void:
	if _completed_tasks.has(task_id):
		return
	_completed_tasks[task_id] = true
	task_completed.emit(task_id)


func is_task_completed(task_id: String) -> bool:
	return _completed_tasks.has(task_id)


func completed_task_count() -> int:
	return _completed_tasks.size()


## Lo que le pagan al guardia por las tareas que terminó.
func payment() -> int:
	return completed_task_count() * Tasks.PAYMENT_PER_TASK


## La PC avisa aquí cuando se abre o se cierra la ventana del asistente.
func set_ai_window_open(is_open: bool) -> void:
	if is_ai_window_open == is_open:
		return
	is_ai_window_open = is_open
	ai_window_changed.emit(is_ai_window_open)


# --- Reserva del pasillo ------------------------------------------------------
# El pasillo es de uno a la vez: si Barcosa lo está usando, Mamador espera,
# y al revés. Quien lo reserva es el responsable de liberarlo al terminar.

## Intenta reservar el pasillo. Devuelve false si ya lo tiene otro profe.
func reserve_hallway(holder: Node) -> bool:
	if _hallway_holder != null and _hallway_holder != holder:
		return false
	_hallway_holder = holder
	return true


## Libera el pasillo, pero solo si de verdad lo tenía este profe.
func release_hallway(holder: Node) -> void:
	if _hallway_holder == holder:
		_hallway_holder = null


func is_hallway_free() -> bool:
	return _hallway_holder == null


func hallway_holder() -> Node:
	return _hallway_holder


## Qué tan avanzada va la noche, en horas con decimales: 2.5 son las 2:30 AM.
## Lo usa el teléfono para sonar entre las 2 y las 4.
func night_progress() -> float:
	return float(current_hour) + clampf(_hour_elapsed / NightConfig.hour_duration(), 0.0, 1.0)


## Texto del reloj para el HUD: la hora 0 se muestra como 12 AM.
func hour_text() -> String:
	var hour: int = 12 if current_hour == 0 else current_hour
	return "%d AM" % hour


func _process(delta: float) -> void:
	if not is_night_active:
		return
	_hour_elapsed += delta
	var hour_duration: float = NightConfig.hour_duration()
	while _hour_elapsed >= hour_duration:
		_hour_elapsed -= hour_duration
		current_hour += 1
		hour_changed.emit(current_hour)
		if current_hour >= NightConfig.END_HOUR:
			_win_night()
			return


func _win_night() -> void:
	is_night_active = false
	PowerManager.set_draining(false)
	night_won.emit(current_night)


func _on_power_depleted() -> void:
	trigger_game_over("Te quedaste sin energía.")

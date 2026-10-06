extends Node

## Autoload. Lleva el reloj de la noche y decide victoria o game over.
## Todo lo demás se entera por señales; nadie llama a nadie de forma rígida.

signal night_started(night: int)
signal hour_changed(hour: int)  # 0 = 12 AM ... 6 = 6 AM
signal night_won(night: int)
signal game_over(cause: String)

var current_night: int = 1
var current_hour: int = NightConfig.START_HOUR
var is_night_active: bool = false
var last_game_over_cause: String = ""

var _hour_elapsed: float = 0.0


func _ready() -> void:
	PowerManager.power_depleted.connect(_on_power_depleted)


## Arranca la noche desde las 12 AM con la energía llena.
func start_night(night: int = current_night) -> void:
	current_night = night
	current_hour = NightConfig.START_HOUR
	_hour_elapsed = 0.0
	last_game_over_cause = ""
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

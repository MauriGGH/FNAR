extends Node

## Autoload. La pantalla completa: el juego arranca así (lo dice project.godot),
## F11 la alterna desde cualquier pantalla y la opción queda guardada en
## save.cfg, para que la próxima vez arranque como el jugador la dejó.
##
## Vive en un autoload porque F11 tiene que funcionar en todas las pantallas sin
## que cada una repita el mismo código.

signal fullscreen_changed(is_fullscreen: bool)

## La tecla que la alterna.
const TOGGLE_KEY: Key = KEY_F11


func _ready() -> void:
	# El autoload sigue vivo con el árbol pausado: F11 debe funcionar en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# SaveGame ya cargó su archivo, así que aquí ya se sabe cómo la dejó.
	apply(SaveGame.fullscreen)


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


## La pone o la quita y lo guarda.
func set_fullscreen(enabled: bool) -> void:
	apply(enabled)
	SaveGame.set_fullscreen(enabled)


func toggle() -> void:
	set_fullscreen(not is_fullscreen())


## Solo cambia la ventana, sin guardar: lo usa el arranque.
func apply(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if enabled
		else DisplayServer.WINDOW_MODE_WINDOWED)
	fullscreen_changed.emit(enabled)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != TOGGLE_KEY:
		return
	toggle()
	get_viewport().set_input_as_handled()

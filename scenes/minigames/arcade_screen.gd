class_name ArcadeScreen
extends Control

## La maquinita completa: el lienzo de 160x90 dentro de un SubViewport, el
## shader de pantalla CRT encima, el arranque con estática y bip, el apagón de
## tele vieja al salir, y los tres niveles con su final.
##
## Sale **entre noches**: la pantalla de 6 AM decide si toca (30 %) y, si sí,
## cambia aquí; al acabar, siga o no con el tótem, se va al periódico.

## El nivel que toca jugar y a dónde ir después. Los pone quien la abre, porque
## change_scene_to_file no deja pasar datos.
static var pending_level: int = 1
static var next_scene: String = Screens.NEWSPAPER
## Solo para el panel de pruebas: arrancar el nivel 3 en su persecución.
static var pending_part_c: bool = false

enum Step { BOOT, PLAYING, ENDING, OVER, SHUTDOWN }

const LEVEL_SCRIPTS: Array[GDScript] = [
	preload("res://scenes/minigames/arcade_posada.gd"),
	preload("res://scenes/minigames/arcade_bienvenida.gd"),
	preload("res://scenes/minigames/arcade_junta.gd"),
]
const ENDING_SCRIPT: GDScript = preload("res://scenes/minigames/arcade_ending.gd")
const OVER_SCRIPT: GDScript = preload("res://scenes/minigames/arcade_over.gd")

## El cartel del nivel, abajo a la derecha.
const LEVEL_LABEL: String = "NIVEL %d"

@onready var container: SubViewportContainer = $Frame/Viewport
@onready var viewport: SubViewport = $Frame/Viewport/SubViewport
@onready var static_layer: StaticFrames = $Boot
@onready var level_label: Label = $LevelLabel

var _step: Step = Step.BOOT
var _elapsed: float = 0.0
var _level: int = 1
var _playing: ArcadeLevel = null
var _won: bool = false
var _left: bool = false


func _ready() -> void:
	_level = clampi(pending_level, 1, Arcade.LEVELS)
	level_label.text = LEVEL_LABEL % _level
	# El rótulo del nivel también en VT323: todo lo de la maquinita es de
	# pantalla, nada de la tipografía de los menús.
	Fonts.apply(level_label, Fonts.terminal(), Arcade.LABEL_SIZE)
	container.material.set_shader_parameter("shutdown", 1.0)
	container.material.set_shader_parameter("lines", float(Arcade.SIZE.y))
	_fit()
	# Al montar la escena el tamaño todavía puede ser cero: se vuelve a colocar
	# en cuanto la ventana le diga cuánto mide.
	_fit.call_deferred()
	resized.connect(_fit)
	# Arranca como una tele: medio segundo de estática y un bip.
	ScreenFx.set_static_strength(static_layer, 1.0)
	AudioManager.play(Sounds.ARCADE_BOOT)
	_step = Step.BOOT


## El lienzo se escala en pasos enteros y se centra: así no se deforma ni un
## píxel, que es de lo que vive el pixel art. El SubViewport no se redimensiona
## a mano: con `stretch` puesto, su tamaño es el del recuadro dividido entre
## `stretch_shrink`, así que el recuadro mide 160x90 por la escala y el encogido
## es esa misma escala.
func _fit() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var scale: int = maxi(1, floori(minf(size.x / float(Arcade.SIZE.x),
		size.y / float(Arcade.SIZE.y))))
	var drawn: Vector2 = Vector2(Arcade.SIZE) * float(scale)
	container.stretch_shrink = scale
	container.size = drawn
	container.position = ((size - drawn) * 0.5).round()


func _process(delta: float) -> void:
	_elapsed += delta
	match _step:
		Step.BOOT:
			var left: float = 1.0 - _elapsed / Arcade.BOOT_TIME
			ScreenFx.set_static_strength(static_layer, maxf(left, 0.0))
			if _elapsed >= Arcade.BOOT_TIME:
				_start_level()
		Step.SHUTDOWN:
			# La imagen se aplasta hasta ser una raya y se apaga.
			var t: float = clampf(1.0 - _elapsed / Arcade.SHUTDOWN_TIME, 0.0, 1.0)
			container.material.set_shader_parameter("shutdown", t)
			if _elapsed >= Arcade.SHUTDOWN_TIME:
				_leave()
		_:
			pass


func _start_level() -> void:
	_step = Step.PLAYING
	_elapsed = 0.0
	_playing = LEVEL_SCRIPTS[_level - 1].new()
	_playing.name = "Level"
	viewport.add_child(_playing)
	_playing.won.connect(_on_level_won)
	_playing.lost.connect(_on_level_lost)
	_playing.start(_level)
	# El panel de pruebas puede pedir el nivel 3 directo en su persecución.
	if pending_part_c and _playing is ArcadeJunta:
		(_playing as ArcadeJunta).start_at_escape()
	pending_part_c = false
	AudioManager.play_loop(Sounds.arcade_music(_level))


## Lo logró: música fuera y entra el final del altar.
func _on_level_won() -> void:
	AudioManager.stop(Sounds.arcade_music(_level))
	_won = true
	_step = Step.ENDING
	_elapsed = 0.0
	_playing.queue_free()
	var ending: ArcadeEnding = ENDING_SCRIPT.new()
	ending.name = "Ending"
	viewport.add_child(ending)
	ending.ready_to_close.connect(_on_ending_done)
	ending.start(_level)
	_playing = ending


## Se quedó sin vidas o sin tiempo: "GAME OVER" con su estática, y **el nivel
## no avanza**: la próxima vez que salga la maquinita toca el mismo.
func _on_level_lost() -> void:
	AudioManager.stop(Sounds.arcade_music(_level))
	ScreenFx.set_static_strength(static_layer, 0.5)
	_step = Step.OVER
	_elapsed = 0.0
	_playing.queue_free()
	var over: ArcadeOver = OVER_SCRIPT.new()
	over.name = "Over"
	viewport.add_child(over)
	over.ready_to_close.connect(_shutdown)
	_playing = null


func _on_ending_done() -> void:
	GameManager.give_totem()
	# Pasado el nivel, y solo entonces, la próxima vez toca el siguiente.
	SaveGame.advance_arcade_level()
	_shutdown()


func _shutdown() -> void:
	if _step == Step.SHUTDOWN:
		return
	_step = Step.SHUTDOWN
	_elapsed = 0.0


func _leave() -> void:
	if _left:
		return  # Una sola vez: _process sigue llamando mientras no cambie la escena.
	_left = true
	AudioManager.stop_all_loops()
	get_tree().change_scene_to_file(next_scene)


## Escape se salta la maquinita: cuenta como no jugada.
func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		if _playing != null and _playing is ArcadeLevel:
			(_playing as ArcadeLevel).is_running = false
		_shutdown()
		get_viewport().set_input_as_handled()

class_name ArcadeLevel
extends Node2D

## Base de los tres minijuegos de la maquinita. Lo que comparten: el lienzo de
## 160x90, el fondo, el reloj, los sprites dibujados con filtro nearest y el
## texto del HUD en píxeles.
##
## Cada nivel hereda y pone lo suyo en `_setup()`, `_tick()` y `_paint()`.

## Lo logró: toca el final del altar.
signal won()
## Se acabó el tiempo.
signal lost()

## Lo que le queda, si el nivel lleva reloj.
var time_left: float = 0.0
var is_running: bool = false

var _background: Texture2D = null
var _sprites: Dictionary = {}
var _elapsed: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Arranca el nivel. `level` es su número, para el fondo y el rótulo.
func start(level: int) -> void:
	_background = Arcade.background(level)
	time_left = Arcade.TIME_LIMIT
	_elapsed = 0.0
	is_running = true
	_setup()
	queue_redraw()


func _process(delta: float) -> void:
	if not is_running:
		return
	_elapsed += delta
	if uses_timer():
		time_left -= delta
		if time_left <= 0.0:
			is_running = false
			lost.emit()
			return
	_tick(delta)
	queue_redraw()


## Los niveles 1 y 2 llevan reloj; el 3 no, que es solo caminar.
func uses_timer() -> bool:
	return true


func elapsed() -> float:
	return _elapsed


func _finish() -> void:
	is_running = false
	won.emit()


# --- Lo que cada nivel rellena ------------------------------------------------

func _setup() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _paint() -> void:
	pass


## El texto de arriba a la izquierda, tipo "VASOS 3/8".
func hud_text() -> String:
	return ""


# --- Dibujo -------------------------------------------------------------------

func _draw() -> void:
	if _background != null:
		draw_texture(_background, Vector2.ZERO)
	_paint()
	_draw_hud()


## Un sprite por su nombre, con los pies en `at` y centrado a lo ancho. Así las
## posiciones del diseño son "donde pisa", que es como se piensa un plataformas.
func blit(name: String, at: Vector2, flip: bool = false) -> void:
	var texture: Texture2D = _sprite(name)
	if texture == null:
		return
	var box: Vector2 = texture.get_size()
	var corner: Vector2 = Vector2(roundf(at.x - box.x * 0.5), roundf(at.y - box.y))
	if not flip:
		draw_texture(texture, corner)
		return
	# Volteado: con una transformada de escala −1 en X, apoyada en el borde
	# derecho del recorte. Con un Rect2 de ancho negativo **no** sirve: el
	# sprite sale espejeado pero corrido su propio ancho hacia la derecha.
	draw_set_transform(corner + Vector2(box.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture(texture, Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _sprite(name: String) -> Texture2D:
	if not _sprites.has(name):
		_sprites[name] = Arcade.sprite(name)
	return _sprites[name]


## El HUD: el contador del nivel arriba a la izquierda y el reloj a la derecha.
func _draw_hud() -> void:
	var text: String = hud_text()
	if not text.is_empty():
		ArcadeFont.draw_text(self, Arcade.TEXT_MARGIN, text, Arcade.TEXT_COLOR)
	if not uses_timer():
		return
	var clock: String = "%02d" % ceili(maxf(time_left, 0.0))
	ArcadeFont.draw_text(self, Vector2(float(Arcade.SIZE.x) - Arcade.TEXT_MARGIN.x
		- ArcadeFont.width(clock), Arcade.TEXT_MARGIN.y), clock, Arcade.TEXT_COLOR)

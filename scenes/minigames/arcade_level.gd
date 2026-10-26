class_name ArcadeLevel
extends Node2D

## Base de los tres minijuegos de la maquinita. Lo que comparten:
##
## - El lienzo de 160x90 y el fondo, **repetido a lo largo del mundo**: los
##   niveles miden de cuatro a cinco pantallas y la cámara sigue a Santi.
## - Las **tres vidas** (corazones arriba a la izquierda), el contador del
##   objetivo arriba al centro y el reloj arriba a la derecha.
## - El golpe: parpadeo, un segundo de invencibilidad y una vida menos. Con cero
##   vidas, o sin tiempo, el nivel se pierde.
## - Los sprites con filtro nearest y el texto con la fuente de 3x5 píxeles.
##
## Cada nivel hereda y pone lo suyo en `_setup()`, `_tick()` y `_paint()`.
## **`_paint()` dibuja en coordenadas del mundo**: la cámara ya está aplicada
## cuando lo llaman, así que no hay que restarle nada a mano.

## Lo logró: toca el final del altar.
signal won()
## Se quedó sin vidas o sin tiempo.
signal lost()

## Lo que le queda de reloj y de vidas.
var time_left: float = 0.0
var lives: int = Arcade.LIVES
var is_running: bool = false
## Lo ancho que es este mundo y por dónde va la cámara.
var world_width: float = float(Arcade.SIZE.x)
var camera_x: float = 0.0
## Mientras sea mayor que cero, Santi parpadea y no le pueden pegar otra vez.
var invincible_left: float = 0.0

var _background: Texture2D = null
var _sprites: Dictionary = {}
var _elapsed: float = 0.0
var _level: int = 1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Arranca el nivel. `level` es su número, para el fondo y el ancho del mundo.
func start(level: int) -> void:
	_level = level
	_background = Arcade.background(level)
	world_width = Arcade.world_width(level)
	time_left = Arcade.time_limit(level)
	lives = Arcade.LIVES
	invincible_left = 0.0
	camera_x = 0.0
	_elapsed = 0.0
	is_running = true
	_setup()
	_update_camera()
	queue_redraw()


func _process(delta: float) -> void:
	if not is_running:
		return
	_elapsed += delta
	if invincible_left > 0.0:
		invincible_left -= delta
	if uses_timer():
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			_give_up()
			return
	_tick(delta)
	_update_camera()
	queue_redraw()


## Cobra un golpe: una vida menos y un segundo de gracia. Devuelve true si
## todavía queda vida, para que el nivel sepa si recolocar a Santi o no.
## Durante la invencibilidad no cuenta: no se pierden dos vidas de un roce.
func hurt() -> bool:
	if not is_running or invincible_left > 0.0:
		return true
	lives -= 1
	invincible_left = Arcade.HURT_FLICKER_TIME
	AudioManager.play(Sounds.ARCADE_HURT)
	if lives <= 0:
		_give_up()
		return false
	return true


## Se acabó: ni vidas ni tiempo.
func _give_up() -> void:
	is_running = false
	lost.emit()


## Mientras parpadea, Santi se dibuja a ratos: así se nota que te pegaron.
func is_blinking() -> bool:
	return invincible_left > 0.0 \
		and fmod(invincible_left * Arcade.HURT_FLICKER_HZ, 1.0) < 0.5


func _finish() -> void:
	is_running = false
	won.emit()


func elapsed() -> float:
	return _elapsed


## La cámara va centrada en Santi y no se sale del mundo.
func _update_camera() -> void:
	var half: float = float(Arcade.SIZE.x) * 0.5
	camera_x = clampf(focus_x() - half + Arcade.CAMERA_AHEAD, 0.0,
		maxf(world_width - float(Arcade.SIZE.x), 0.0))


# --- Lo que cada nivel rellena ------------------------------------------------

func _setup() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _paint() -> void:
	pass


## A quién sigue la cámara.
func focus_x() -> float:
	return 0.0


## Los tres llevan reloj.
func uses_timer() -> bool:
	return true


## El contador del objetivo, que va arriba al centro ("VASOS 3/15").
func hud_text() -> String:
	return ""


# --- Dibujo -------------------------------------------------------------------

func _draw() -> void:
	_use_camera()
	_draw_background()
	_paint()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_hud()


## Deja puesta la cámara. Lo que se dibuje a partir de aquí va en coordenadas
## del mundo.
func _use_camera() -> void:
	draw_set_transform(Vector2(-roundf(camera_x), 0.0), 0.0, Vector2.ONE)


## El fondo, repetido a lo largo del mundo. Es una sola foto de 160x90: con
## cinco pantallas de ancho se dibuja cinco veces seguidas.
func _draw_background() -> void:
	if _background == null:
		return
	var copies: int = ceili(world_width / float(Arcade.SIZE.x))
	for copy: int in copies:
		draw_texture(_background, Vector2(float(copy * Arcade.SIZE.x), 0.0))


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
	# Al acabar se devuelve la cámara, no la identidad: si no, lo que viniera
	# detrás se dibujaría sin desplazar.
	draw_set_transform(corner + Vector2(box.x - roundf(camera_x), 0.0),
		0.0, Vector2(-1.0, 1.0))
	draw_texture(texture, Vector2.ZERO)
	_use_camera()


func _sprite(name: String) -> Texture2D:
	if not _sprites.has(name):
		_sprites[name] = Arcade.sprite(name)
	return _sprites[name]


## Una tabla de madera: el canto y, encima, su filo más claro.
func draw_plank(rect: Rect2, color: Color = Arcade.PLANK_COLOR,
		top: Color = Arcade.PLANK_TOP) -> void:
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), top)


# --- El HUD -------------------------------------------------------------------

## Corazones a la izquierda, el objetivo al centro y el reloj a la derecha.
func _draw_hud() -> void:
	_draw_hearts()
	var text: String = hud_text()
	if not text.is_empty():
		var left: float = float(Arcade.SIZE.x) * 0.5 - ArcadeFont.width(text) * 0.5
		ArcadeFont.draw_text(self, Vector2(left, Arcade.TEXT_MARGIN.y), text,
			Arcade.TEXT_COLOR)
	if not uses_timer():
		return
	var clock: String = "%03d" % ceili(time_left)
	var color: Color = Arcade.WARNING_COLOR if time_left <= Arcade.TIME_WARNING \
		else Arcade.TEXT_COLOR
	ArcadeFont.draw_text(self, Vector2(float(Arcade.SIZE.x) - Arcade.TEXT_MARGIN.x
		- ArcadeFont.width(clock), Arcade.TEXT_MARGIN.y), clock, color)


## Las vidas, dibujadas píxel a píxel: un corazón de 7x6 por vida, las gastadas
## en rojo apagado.
func _draw_hearts() -> void:
	for i: int in Arcade.LIVES:
		var at: Vector2 = Arcade.HEART_AT + Vector2(float(i) * Arcade.HEART_STEP, 0.0)
		var color: Color = Arcade.HEART_COLOR if i < lives else Arcade.HEART_EMPTY
		# Dos bultos arriba y una punta abajo, que es un corazón en siete de
		# ancho sin que parezca otra cosa.
		draw_rect(Rect2(at + Vector2(1.0, 0.0), Vector2(2.0, 1.0)), color)
		draw_rect(Rect2(at + Vector2(4.0, 0.0), Vector2(2.0, 1.0)), color)
		draw_rect(Rect2(at + Vector2(0.0, 1.0), Vector2(7.0, 2.0)), color)
		draw_rect(Rect2(at + Vector2(1.0, 3.0), Vector2(5.0, 1.0)), color)
		draw_rect(Rect2(at + Vector2(2.0, 4.0), Vector2(3.0, 1.0)), color)
		draw_rect(Rect2(at + Vector2(3.0, 5.0), Vector2(1.0, 1.0)), color)

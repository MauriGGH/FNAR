class_name ArcadeEnding
extends ArcadeLevel

## El final, después de cualquier nivel: negro con un haz de luz, el altar de la
## Virgen al centro, la silueta de Sergio a un lado y Santi al otro. El texto se
## escribe letra por letra y, al acabar, el tótem es tuyo.

## Ya se escribió todo y se aguantó un momento.
signal ready_to_close()

## El charco de luz, calculado una vez como imagen: así tiene bordes suaves de
## verdad y no se nota ninguna figura geométrica.
var _glow: Texture2D = null
var _typed: float = 0.0
var _hold: float = 0.0
var _done: bool = false


func uses_timer() -> bool:
	return false


func hud_text() -> String:
	return ""


func _setup() -> void:
	_typed = 0.0
	_hold = 0.0
	_done = false
	if _glow == null:
		_glow = _build_glow()
	AudioManager.play(Sounds.AURA)


func _tick(delta: float) -> void:
	if _done:
		return
	_typed += delta * Arcade.TYPE_SPEED
	if _typed < float(Arcade.ENDING_TEXT.length()):
		return
	_hold += delta
	if _hold >= Arcade.ENDING_HOLD:
		_done = true
		is_running = false
		ready_to_close.emit()


func _draw() -> void:
	# Aquí no hay fondo del nivel: es negro con el haz.
	draw_rect(Rect2(Vector2.ZERO, Vector2(Arcade.SIZE)), Color(0.02, 0.02, 0.04))
	_draw_beam()
	_draw_glow()
	blit("altar", Arcade.ALTAR_AT)
	blit("sergio", Arcade.SERGIO_AT)
	blit("santi_idle", Arcade.SANTI_AT)
	_draw_text()


## El haz que cae sobre el altar, de tiras finas para que se vea difuminado.
func _draw_beam() -> void:
	var strips: int = 18
	var strip: float = Arcade.BEAM_WIDTH / float(strips)
	for i: int in strips:
		var away: float = absf(float(i) - float(strips - 1) * 0.5) / (float(strips) * 0.5)
		var alpha: float = Arcade.BEAM_ALPHA * pow(1.0 - clampf(away, 0.0, 1.0), 2.0)
		draw_rect(Rect2(
			Vector2(Arcade.ALTAR_AT.x - Arcade.BEAM_WIDTH * 0.5 + strip * float(i), 0.0),
			Vector2(strip, Arcade.ALTAR_AT.y)), Color(1.0, 0.98, 0.9, alpha))


## El charco de luz del suelo. Sin él las dos siluetas quedarían negro sobre
## negro: son recortes casi puros de sombra.
func _draw_glow() -> void:
	if _glow != null:
		draw_texture(_glow, Vector2.ZERO)


## La luz, pixel a pixel: una elipse que se apaga hacia fuera, así que no se le
## ve ninguna arista.
func _build_glow() -> Texture2D:
	var image: Image = Image.create(Arcade.SIZE.x, Arcade.SIZE.y, false,
		Image.FORMAT_RGBA8)
	for y: int in Arcade.SIZE.y:
		for x: int in Arcade.SIZE.x:
			var away: Vector2 = (Vector2(float(x), float(y)) - Arcade.GLOW_CENTER) \
				/ Arcade.GLOW_RADIUS
			var distance: float = away.length()
			if distance >= 1.0:
				continue
			var alpha: float = Arcade.GLOW_ALPHA * pow(1.0 - distance, 2.0)
			image.set_pixel(x, y, Color(0.92, 0.9, 0.82, alpha))
	return ImageTexture.create_from_image(image)


## El texto, letra por letra y centrado abajo. Se centra por el ancho de la
## frase completa, no por lo que lleva escrito: así no se va moviendo.
func _draw_text() -> void:
	var shown: String = Arcade.ENDING_TEXT.substr(0,
		mini(int(_typed), Arcade.ENDING_TEXT.length()))
	if shown.is_empty():
		return
	var left: float = float(Arcade.SIZE.x) * 0.5 \
		- ArcadeFont.width(Arcade.ENDING_TEXT) * 0.5
	ArcadeFont.draw_text(self, Vector2(left, Arcade.ENDING_TEXT_Y), shown,
		Arcade.TEXT_COLOR)

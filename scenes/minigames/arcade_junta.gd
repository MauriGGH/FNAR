class_name ArcadeJunta
extends ArcadeLevel

## Nivel 3, "La junta": la botarga camina por el pasillo **solo hacia la
## derecha**, detrás del hombre de traje. Las luces del techo parpadean y en la
## pared aparece y desaparece "AYÚDANOS".
##
## Al llegar, la puerta de la sala se abre, entran los dos, se cierra, la
## pantalla se pone roja y suena la cajita musical distorsionada. No hay reloj:
## este nivel no se puede perder, solo se camina hacia lo que ya pasó.

enum Step { WALKING, ENTERING, CLOSED, DONE }

var _at: Vector2 = Vector2(Arcade.START_X, Arcade.HALL_Y)
var _step: Step = Step.WALKING
var _step_elapsed: float = 0.0
var _moving: bool = false
var _light: float = 1.0
var _help_visible: bool = false
var _help_left: float = Arcade.HELP_OFF


func _setup() -> void:
	_at = Vector2(Arcade.START_X, Arcade.HALL_Y)
	_step = Step.WALKING
	_step_elapsed = 0.0
	_light = 1.0
	_help_visible = false
	_help_left = Arcade.HELP_OFF


## Sin reloj: aquí no se pierde.
func uses_timer() -> bool:
	return false


func hud_text() -> String:
	return ""


func _tick(delta: float) -> void:
	_flicker(delta)
	_help(delta)
	match _step:
		Step.WALKING:
			_walk(delta)
		Step.ENTERING:
			_step_elapsed += delta
			if _step_elapsed >= Arcade.DOOR_TIME:
				_step = Step.CLOSED
				_step_elapsed = 0.0
				AudioManager.play(Sounds.ARCADE_MUSIC_BOX)
		Step.CLOSED:
			_step_elapsed += delta
			if _step_elapsed >= Arcade.RED_TIME:
				_step = Step.DONE
				_finish()
		Step.DONE:
			pass


## Solo hacia delante: atrás ya no se puede volver.
func _walk(delta: float) -> void:
	_moving = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	if _moving:
		_at.x += Arcade.WALK_SPEED * delta
	if _at.x < Arcade.DOOR.position.x - 6.0:
		return
	_step = Step.ENTERING
	_step_elapsed = 0.0


## Las luces del techo: a ratos se van casi del todo.
func _flicker(delta: float) -> void:
	var wave: float = sin(elapsed() * 7.0) * sin(elapsed() * 2.3 + 1.1)
	_light = lerpf(_light, lerpf(Arcade.FLICKER_MIN, Arcade.FLICKER_MAX,
		clampf(0.5 + wave, 0.0, 1.0)), clampf(delta * 9.0, 0.0, 1.0))


func _help(delta: float) -> void:
	_help_left -= delta
	if _help_left > 0.0:
		return
	_help_visible = not _help_visible
	_help_left = Arcade.HELP_ON if _help_visible else Arcade.HELP_OFF


func _paint() -> void:
	# La sala con la puerta cerrada: todo rojo y nada más.
	if _step == Step.CLOSED or _step == Step.DONE:
		draw_rect(Rect2(Vector2.ZERO, Vector2(Arcade.SIZE)), Arcade.RED)
		return
	if _help_visible:
		ArcadeFont.draw_text(self, Arcade.HELP_AT, Arcade.HELP_TEXT,
			Arcade.HELP_COLOR)
	if _step == Step.ENTERING:
		# Entrando: los dos ya se metieron, solo se ve el hueco de la puerta.
		draw_rect(Rect2(Arcade.DOOR.position, Arcade.DOOR.size), Color(0.1, 0.0, 0.02,
			clampf(_step_elapsed / Arcade.DOOR_TIME, 0.0, 1.0)))
	else:
		blit("traje_back", Vector2(minf(_at.x + Arcade.SUIT_AHEAD,
			Arcade.DOOR.position.x + 10.0), Arcade.HALL_Y))
		blit(_botarga_frame(), _at)
	# La oscuridad del pasillo, que sube y baja con las luces.
	draw_rect(Rect2(Vector2.ZERO, Vector2(Arcade.SIZE)),
		Color(0.0, 0.0, 0.02, (1.0 - _light) * 0.75))


func _botarga_frame() -> String:
	if not _moving:
		return "botarga_idle"
	return "botarga_walk1" if fmod(elapsed(), 0.34) < 0.17 else "botarga_walk2"

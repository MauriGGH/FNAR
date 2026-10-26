class_name ArcadeJunta
extends ArcadeLevel

## Nivel 3, "La junta": ya no es solo caminar. Son tres partes seguidas por el
## mismo pasillo de cinco pantallas.
##
## **A, seguirlo** (unos 60 s): el hombre de traje camina despacio y cada tanto
## se para y voltea. Avisa: se le prenden los **ojos rojos 0.6 s antes**. Si al
## voltear te ve **en movimiento** y a menos de 40 px, te cuesta una vida; te
## salva quedarte quieto, o estar detrás de una maceta, una columna o un marco
## de puerta. Y si te quedas **más de una pantalla atrás durante 3 s**, sale
## "LO PERDISTE" y también te cuesta una vida: él te espera mientras tanto.
##
## **B, la oscuridad** (desde `L3_DARK_FROM`): se va la luz. Solo se ve un
## círculo alrededor de Santi y la veladora del fondo. Hay huecos que solo se
## ven de cerca, y en medio la botarga tirada con su "AYÚDANOS".
##
## **C, el escape**: la puerta de la sala se cierra, un segundo de rojo y el de
## traje viene **rápido**. Hay que volver por el pasillo saltando las sillas
## tiradas. Si te alcanza no es un rasguño: se pierde la vida entera y **se
## repite la parte C** desde el principio; si era la última, se acabó.

enum Step { FOLLOW, DARK, DOOR, RED, ESCAPE, DONE }
enum Suit { WALKING, TURNING, WATCHING }

var _at: Vector2 = Vector2.ZERO
var _speed_y: float = 0.0
var _on_floor: bool = true
var _facing: int = 1
var _moving: bool = false
var _step: Step = Step.FOLLOW
var _step_elapsed: float = 0.0

## El hombre de traje en la parte A: dónde va, qué está haciendo y cuánto le
## queda de eso.
var _suit_x: float = 0.0
var _suit: Suit = Suit.WALKING
var _suit_left: float = 0.0
## Lo que llevas perdido de vista y el aviso en pantalla.
var _lost_left: float = 0.0
var _notice_left: float = 0.0
var _notice: String = ""
## El parpadeo de las luces y el letrero de la botarga.
var _light: float = 1.0
var _help_visible: bool = false
var _help_left: float = Arcade.HELP_OFF


func _setup() -> void:
	_at = Vector2(Arcade.START_X, Arcade.HALL_Y)
	_speed_y = 0.0
	_on_floor = true
	_step = Step.FOLLOW
	_step_elapsed = 0.0
	_suit_x = Arcade.START_X + Arcade.SUIT_AHEAD
	_begin_walking()
	_lost_left = 0.0
	_notice_left = 0.0
	_light = 1.0


## Para el panel de pruebas: empezar directamente en la persecución.
func start_at_escape() -> void:
	_at = Vector2(Arcade.L3_DOOR - 10.0, Arcade.HALL_Y)
	_begin_escape()


## Si el nivel se va (perdiste, o saliste con Esc) la música se queda con el
## tono de la persecución puesto y la próxima partida arrancaría acelerada.
func _exit_tree() -> void:
	AudioManager.set_pitch(Sounds.arcade_music(3), 1.0)


func focus_x() -> float:
	return _at.x


func hud_text() -> String:
	if _notice_left > 0.0:
		return _notice
	match _step:
		Step.FOLLOW:
			return "SIGUELO"
		Step.DARK:
			return "A OSCURAS"
		Step.ESCAPE:
			return "CORRE"
	return ""


func _tick(delta: float) -> void:
	_flicker(delta)
	_help(delta)
	if _notice_left > 0.0:
		_notice_left -= delta
	_step_elapsed += delta
	match _step:
		Step.FOLLOW:
			_walk(delta)
			_move_suit(delta)
			if _at.x >= Arcade.L3_DARK_FROM:
				_step = Step.DARK
				_step_elapsed = 0.0
		Step.DARK:
			_walk(delta)
			_check_dark_holes()
			if _at.x >= Arcade.L3_DOOR - 8.0:
				_step = Step.DOOR
				_step_elapsed = 0.0
				AudioManager.play(Sounds.ARCADE_MUSIC_BOX)
		Step.DOOR:
			if _step_elapsed >= Arcade.DOOR_TIME:
				_step = Step.RED
				_step_elapsed = 0.0
		Step.RED:
			if _step_elapsed >= Arcade.RED_TIME:
				_begin_escape()
		Step.ESCAPE:
			_walk(delta)
			_run_from_suit(delta)
		Step.DONE:
			pass


# --- Caminar ------------------------------------------------------------------

## En las partes A y B solo se avanza hacia la derecha: atrás ya no se vuelve.
## En la C es al revés, de vuelta por donde vino.
func _walk(delta: float) -> void:
	var push: float = 0.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		push += 1.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		push -= 1.0
	if _step != Step.ESCAPE:
		push = maxf(push, 0.0)
	_moving = push != 0.0
	if _moving:
		_facing = signi(roundi(push))
	_at.x = clampf(_at.x + push * Arcade.WALK_SPEED * delta, 6.0, world_width - 6.0)

	# En el escape hay sillas que saltar.
	var jump: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) \
		or Input.is_key_pressed(KEY_W)
	if jump and _on_floor:
		_speed_y = -Arcade.JUMP_SPEED
		_on_floor = false
		AudioManager.play(Sounds.ARCADE_JUMP)
	_speed_y += Arcade.GRAVITY * delta
	_at.y += _speed_y * delta
	if _at.y >= Arcade.HALL_Y:
		_at.y = Arcade.HALL_Y
		_speed_y = 0.0
		_on_floor = true


# --- Parte A: seguirlo --------------------------------------------------------

func _begin_walking() -> void:
	_suit = Suit.WALKING
	_suit_left = randf_range(Arcade.SUIT_WALK_TIME.x, Arcade.SUIT_WALK_TIME.y)


## Camina, se para a mirar y vuelve a caminar. Mientras te quedas atrás, te
## espera: no tiene sentido que se vaya solo.
func _move_suit(delta: float) -> void:
	var behind: float = _suit_x - _at.x
	if behind > Arcade.LOST_DISTANCE:
		_lost_left += delta
		if _lost_left >= Arcade.LOST_PATIENCE:
			_lost_left = 0.0
			_show(Arcade.LOST_TEXT)
			hurt()
		return  # Te espera.
	_lost_left = 0.0
	_suit_left -= delta
	match _suit:
		Suit.WALKING:
			_suit_x = minf(_suit_x + Arcade.SUIT_WALK * delta, Arcade.L3_DOOR)
			# El aviso: los ojos se prenden antes de voltear.
			if _suit_left <= Arcade.EYES_WARNING:
				_suit = Suit.TURNING
		Suit.TURNING:
			if _suit_left <= 0.0:
				_suit = Suit.WATCHING
				_suit_left = randf_range(Arcade.SUIT_WATCH_TIME.x,
					Arcade.SUIT_WATCH_TIME.y)
		Suit.WATCHING:
			_check_seen()
			if _suit_left <= 0.0:
				_begin_walking()


## Volteado y mirando: te pilla si te mueves cerca y no estás tapado.
func _check_seen() -> void:
	if not _moving or absf(_suit_x - _at.x) > Arcade.SEEN_RANGE:
		return
	if _behind_cover():
		return
	_show("TE VIO")
	hurt()


## ¿Está detrás de una maceta, una columna o un marco de puerta?
func _behind_cover() -> bool:
	for cover: Vector2 in Arcade.L3_COVER:
		if _at.x > cover.x and _at.x < cover.x + cover.y:
			return true
	return false


func _show(text: String) -> void:
	_notice = text
	_notice_left = 1.4


# --- Parte B: la oscuridad ----------------------------------------------------

## Los huecos del tramo a oscuras: caerse cuesta una vida y te deja justo
## delante del hueco, no al principio.
func _check_dark_holes() -> void:
	for hole: Vector2 in Arcade.L3_DARK_HOLES:
		if _at.x > hole.x and _at.x < hole.x + hole.y and _on_floor:
			if hurt():
				_at.x = hole.x - 8.0
			return


# --- Parte C: el escape -------------------------------------------------------

func _begin_escape() -> void:
	_step = Step.ESCAPE
	_step_elapsed = 0.0
	_suit_x = _at.x + Arcade.ESCAPE_HEAD_START
	_suit = Suit.WALKING
	# La música se acelera: es lo único que cambia de tono en todo el juego.
	AudioManager.set_pitch(Sounds.arcade_music(3), Arcade.ESCAPE_PITCH)


## Viene detrás, un poco más lento que tú: lo que te alcanza son los tropiezos
## con las sillas. Llegar al final del pasillo es ganar.
func _run_from_suit(delta: float) -> void:
	_suit_x -= Arcade.ESCAPE_SUIT_SPEED * delta
	if _at.x <= Arcade.START_X + 2.0:
		_step = Step.DONE
		AudioManager.set_pitch(Sounds.arcade_music(3), 1.0)
		_finish()
		return
	# Las sillas frenan: hay que saltarlas.
	for chair: Vector2 in Arcade.L3_CHAIRS:
		if absf(_at.x - chair.x) < chair.y * 0.5 \
				and _at.y > Arcade.HALL_Y - Arcade.CHAIR_HEIGHT:
			_at.x = chair.x + chair.y * 0.5
			break
	if _suit_x - _at.x > 8.0:
		return
	# Te alcanzó: la vida entera y, si queda alguna, se repite la parte C.
	if not hurt():
		return
	_show("TE ALCANZO")
	_at = Vector2(Arcade.L3_DOOR - 10.0, Arcade.HALL_Y)
	_suit_x = _at.x + Arcade.ESCAPE_HEAD_START


# --- Ambiente -----------------------------------------------------------------

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


# --- Dibujo -------------------------------------------------------------------

func _paint() -> void:
	if _step == Step.RED or _step == Step.DONE:
		draw_rect(Rect2(Vector2(camera_x, 0.0), Vector2(Arcade.SIZE)), Arcade.RED)
		return

	for cover: Vector2 in Arcade.L3_COVER:
		_draw_cover(cover)
	for chair: Vector2 in Arcade.L3_CHAIRS:
		if _step == Step.ESCAPE:
			draw_rect(Rect2(Vector2(chair.x - chair.y * 0.5,
				Arcade.HALL_Y - Arcade.CHAIR_HEIGHT),
				Vector2(chair.y, Arcade.CHAIR_HEIGHT)), Arcade.CHAIR_COLOR)
	# La puerta de la sala, al final del pasillo.
	draw_rect(Rect2(Vector2(Arcade.L3_DOOR, 22.0), Vector2(14.0, 40.0)),
		Arcade.RED if _step != Step.DOOR else Arcade.COVER_COLOR)

	if _step == Step.DARK:
		_draw_dark_props()
	if _step == Step.FOLLOW or _step == Step.ESCAPE:
		_draw_suit()
	if not is_blinking():
		blit(_santi_frame(), _at, _facing < 0)
	if _step == Step.DARK:
		_draw_darkness()
	# La oscuridad del pasillo, que sube y baja con las luces.
	if _step != Step.DARK:
		draw_rect(Rect2(Vector2(camera_x, 0.0), Vector2(Arcade.SIZE)),
			Color(0.0, 0.0, 0.02, (1.0 - _light) * 0.75))


## Macetas, columnas y marcos: bultos donde esconderse.
func _draw_cover(cover: Vector2) -> void:
	var rect: Rect2 = Rect2(Vector2(cover.x, Arcade.HALL_Y - Arcade.COVER_HEIGHT),
		Vector2(cover.y, Arcade.COVER_HEIGHT))
	draw_rect(rect, Arcade.COVER_COLOR)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), Arcade.COVER_TOP)


## Lo que hay en el tramo a oscuras: los huecos y la botarga con su letrero.
func _draw_dark_props() -> void:
	for hole: Vector2 in Arcade.L3_DARK_HOLES:
		draw_rect(Rect2(Vector2(hole.x, Arcade.HALL_Y),
			Vector2(hole.y, float(Arcade.SIZE.y) - Arcade.HALL_Y)),
			Arcade.HOLE_COLOR)
	blit("botarga_idle", Vector2(Arcade.L3_SUIT_BODY, Arcade.HALL_Y))
	if _help_visible:
		ArcadeFont.draw_text(self,
			Vector2(Arcade.L3_SUIT_BODY - 18.0, Arcade.HALL_Y - 40.0),
			Arcade.HELP_TEXT, Arcade.HELP_COLOR)


## El negro de la parte B, con el círculo alrededor de Santi recortado fila por
## fila, y la veladora del fondo parpadeando por encima.
func _draw_darkness() -> void:
	var dark: Color = Color(0.0, 0.0, 0.01, 0.97)
	var radius: float = Arcade.DARK_RADIUS
	for row: int in Arcade.SIZE.y:
		var y: float = float(row)
		var dy: float = absf(y - (_at.y - 12.0))
		var half: float = 0.0
		if dy < radius:
			half = sqrt(radius * radius - dy * dy)
		var fade: float = clampf(1.0 - (radius - dy) / Arcade.DARK_SOFT, 0.0, 1.0)
		var shade: Color = Color(dark.r, dark.g, dark.b, dark.a * maxf(fade, 0.0))
		if half <= 0.0:
			draw_rect(Rect2(Vector2(camera_x, y), Vector2(float(Arcade.SIZE.x), 1.0)),
				dark)
			continue
		draw_rect(Rect2(Vector2(camera_x, y), Vector2(_at.x - half - camera_x, 1.0)), dark)
		draw_rect(Rect2(Vector2(_at.x + half, y),
			Vector2(camera_x + float(Arcade.SIZE.x) - (_at.x + half), 1.0)), dark)
		draw_rect(Rect2(Vector2(_at.x - half, y), Vector2(half * 2.0, 1.0)), shade)
	# La veladora del fondo, que es lo único que se ve a lo lejos.
	var candle: Vector2 = Vector2(camera_x + float(Arcade.SIZE.x) * Arcade.CANDLE_AT.x,
		float(Arcade.SIZE.y) * Arcade.CANDLE_AT.y)
	var flicker: float = 0.6 + 0.4 * sin(elapsed() * 11.0) * sin(elapsed() * 3.3)
	draw_rect(Rect2(candle - Vector2(1.0, 2.0), Vector2(2.0, 3.0)),
		Color(1.0, 0.8, 0.4, clampf(flicker, 0.2, 1.0)))
	blit("veladora", candle + Vector2(0.0, 9.0))


## El de traje: de espaldas mientras camina, volteado cuando mira, y con los
## ojos rojos el medio segundo de antes.
func _draw_suit() -> void:
	var watching: bool = _suit == Suit.WATCHING or _suit == Suit.TURNING
	blit("traje_side" if watching else "traje_back",
		Vector2(_suit_x, Arcade.HALL_Y), _suit_x > _at.x)
	if _suit != Suit.TURNING and _suit != Suit.WATCHING:
		return
	var eyes: Vector2 = Vector2(_suit_x, Arcade.HALL_Y - 28.0)
	draw_rect(Rect2(eyes + Vector2(-3.0, 0.0), Vector2(2.0, 2.0)), Arcade.EYES_COLOR)
	draw_rect(Rect2(eyes + Vector2(1.0, 0.0), Vector2(2.0, 2.0)), Arcade.EYES_COLOR)


func _santi_frame() -> String:
	if not _on_floor:
		return "santi_jump"
	if not _moving:
		return "santi_idle"
	return "santi_walk1" if fmod(elapsed(), 0.3) < 0.15 else "santi_walk2"

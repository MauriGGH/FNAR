class_name ArcadeBienvenida
extends ArcadeLevel

## Nivel 2, "La bienvenida": la botarga reparte **ocho globos** por un patio de
## cuatro pantallas y media. Solo puede cargar **uno a la vez**, así que cada
## entrega son dos viajes: al puesto de la izquierda por el globo y hasta el
## alumno que toque.
##
## Lo que lo complica:
##
## - Los **ventiladores del techo** revientan el globo si saltas debajo. No
##   quitan vida, pero hay que volver por otro.
## - Desde la **cuarta entrega**, el hombre de traje aparece por el borde de la
##   pantalla y la persigue; con cada entrega va más rápido, y al final corre
##   más que ella. Si la alcanza, una vida menos y él vuelve al borde.

enum Step { EMPTY, CARRYING, DONE }

var _at: Vector2 = Vector2.ZERO
var _speed_y: float = 0.0
var _on_floor: bool = true
var _facing: int = -1
var _step: Step = Step.EMPTY
var _given: int = 0
var _moving: bool = false
## Los alumnos que todavía están ahí.
var _present: Array[bool] = []
## Dónde va el hombre de traje, y si ya salió.
var _suit_x: float = 0.0
var _suit_chasing: bool = false
## Lo que le queda de quedarse quieto en el borde antes de volver a por ella.
var _suit_wait: float = 0.0
## Lo que lleva con los pies en el suelo, para el respiro del aterrizaje.
var _grounded: float = 999.0


func _setup() -> void:
	_at = Vector2(Arcade.L2_STAND, Arcade.GROUND_Y)
	_speed_y = 0.0
	_on_floor = true
	_step = Step.EMPTY
	_given = 0
	_suit_chasing = false
	_suit_x = 0.0
	_suit_wait = 0.0
	_present.clear()
	for i: int in Arcade.L2_STUDENTS.size():
		_present.append(true)


func focus_x() -> float:
	return _at.x


func hud_text() -> String:
	return "GLOBOS %d/%d" % [_given, Arcade.STUDENTS]


func _tick(delta: float) -> void:
	if _step == Step.DONE:
		return
	_move(delta)
	_check_fans()
	if _step == Step.EMPTY:
		_try_pickup()
	else:
		_try_deliver()
	_move_suit(delta)


func _move(delta: float) -> void:
	var push: float = 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		push -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		push += 1.0
	_moving = push != 0.0
	if _moving:
		_facing = signi(roundi(push))
	_at.x = clampf(_at.x + push * Arcade.WALK_SPEED * delta, 8.0, world_width - 8.0)

	var jump: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) \
		or Input.is_key_pressed(KEY_W)
	if jump and _on_floor:
		_speed_y = -Arcade.JUMP_SPEED
		_on_floor = false
		AudioManager.play(Sounds.ARCADE_JUMP)
	_speed_y += Arcade.GRAVITY * delta
	_at.y += _speed_y * delta
	if _at.y >= Arcade.GROUND_Y:
		_at.y = Arcade.GROUND_Y
		_speed_y = 0.0
		if not _on_floor:
			_grounded = 0.0  # Acaba de caer: le queda el respiro.
		else:
			_grounded += delta
		_on_floor = true
	else:
		_grounded = 0.0


## En el puesto se toma un globo.
func _try_pickup() -> void:
	if absf(_at.x - Arcade.L2_STAND) > Arcade.REACH:
		return
	if _given >= Arcade.STUDENTS:
		_step = Step.DONE
		_finish()
		return
	_step = Step.CARRYING
	AudioManager.play(Sounds.ARCADE_PICK)


## Con el globo encima, acercarse a un alumno que siga ahí se lo entrega, y ese
## alumno desaparece en el acto.
func _try_deliver() -> void:
	for i: int in Arcade.L2_STUDENTS.size():
		if not _present[i]:
			continue
		if absf(_at.x - Arcade.L2_STUDENTS[i]) > Arcade.REACH:
			continue
		_present[i] = false
		_step = Step.EMPTY
		_given += 1
		AudioManager.play(Sounds.ARCADE_PICK)
		# Desde la cuarta, el de traje ya no se despega.
		if _given >= Arcade.SUIT_FROM_DELIVERY and not _suit_chasing:
			_suit_chasing = true
			_suit_x = _edge_behind()
			_suit_wait = Arcade.SUIT_RECOVER
		if _given >= Arcade.STUDENTS:
			_step = Step.DONE
			_finish()
		return


## Las aspas revientan el globo al saltar debajo. De pie no alcanzan: solo
## pillan a la botarga con la cabeza por encima de `FAN_REACH_Y`.
func _check_fans() -> void:
	if _step != Step.CARRYING:
		return
	var head: float = _at.y - 33.0
	if head > Arcade.FAN_REACH_Y:
		return
	for fan: Vector2 in Arcade.L2_FANS:
		if absf(_at.x - fan.x) < Arcade.FAN_RADIUS:
			_step = Step.EMPTY
			AudioManager.play(Sounds.ARCADE_HURT)
			return


## El de traje camina hacia ella, cada vez más rápido. Si la toca, una vida
## menos y vuelve al borde de la pantalla.
func _move_suit(delta: float) -> void:
	if not _suit_chasing:
		return
	# Después de pillarla se queda un momento en el borde: es el respiro que
	# necesita ella para despegarse del puesto.
	if _suit_wait > 0.0:
		_suit_wait -= delta
		return
	var reached: float = clampf(float(_given - Arcade.SUIT_FROM_DELIVERY)
		/ float(maxi(Arcade.STUDENTS - Arcade.SUIT_FROM_DELIVERY, 1)), 0.0, 1.0)
	var speed: float = lerpf(Arcade.SUIT_SPEED_FIRST, Arcade.SUIT_SPEED_LAST, reached)
	_suit_x += signf(_at.x - _suit_x) * speed * delta
	# Pasarle por encima de un salto vale: **solo pilla a quien va por el suelo**.
	if absf(_at.x - _suit_x) > Arcade.SUIT_CATCH or not _on_floor \
			or _grounded < Arcade.LAND_GRACE:
		return
	if not hurt():
		return
	_suit_x = _edge_behind()
	_suit_wait = Arcade.SUIT_RECOVER


## Por dónde vuelve a aparecer: **por el borde que ella deja atrás**. Si
## reapareciera siempre por la izquierda, al volver al puesto lo tendría encima
## otra vez y se iría otra vida cada segundo.
func _edge_behind() -> float:
	if _facing > 0:
		return camera_x - 10.0
	return camera_x + float(Arcade.SIZE.x) + 10.0


func _paint() -> void:
	# El puesto: el manojo de globos, mientras queden por repartir.
	if _given < Arcade.STUDENTS:
		blit("globo_rojo", Arcade.TENT_BALLOONS[0])
		blit("globo_azul", Arcade.TENT_BALLOONS[1])
	for i: int in Arcade.L2_STUDENTS.size():
		if _present[i]:
			blit("alumno_%d" % (i % 4 + 1),
				Vector2(Arcade.L2_STUDENTS[i], Arcade.GROUND_Y))
	for fan: Vector2 in Arcade.L2_FANS:
		_draw_fan(fan)
	if _suit_chasing:
		blit("traje_side", Vector2(_suit_x, Arcade.GROUND_Y), _suit_x > _at.x)
	if not is_blinking():
		blit(_botarga_frame(), _at, _facing < 0)
	# El globo que lleva en la mano.
	if _step == Step.CARRYING:
		blit("globo_rojo", _at + Vector2(float(_facing) * Arcade.CARRIED_BALLOON.x,
			Arcade.CARRIED_BALLOON.y))


## Un ventilador: su tubo y dos aspas que giran.
func _draw_fan(fan: Vector2) -> void:
	draw_rect(Rect2(Vector2(fan.x - 1.0, 0.0), Vector2(2.0, fan.y)), Arcade.FAN_COLOR)
	var spin: float = sin(elapsed() * Arcade.FAN_SPIN)
	var span: float = Arcade.FAN_RADIUS * spin
	draw_rect(Rect2(Vector2(fan.x - absf(span), fan.y), Vector2(absf(span) * 2.0, 2.0)),
		Arcade.FAN_COLOR)
	draw_rect(Rect2(Vector2(fan.x - 2.0, fan.y - 1.0), Vector2(4.0, 4.0)),
		Arcade.FAN_COLOR)


func _botarga_frame() -> String:
	if not _on_floor:
		return "botarga_idle"
	if not _moving:
		return "botarga_idle"
	return "botarga_walk1" if fmod(elapsed(), 0.34) < 0.17 else "botarga_walk2"

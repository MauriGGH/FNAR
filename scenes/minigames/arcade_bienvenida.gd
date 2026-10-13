class_name ArcadeBienvenida
extends ArcadeLevel

## Nivel 2, "La bienvenida": la botarga reparte globos a cinco alumnos. Se toma
## un globo en la carpa, se lleva al alumno y se vuelve por el siguiente.
##
## La vuelta es lo que da miedo: **cada vez que entregas uno y regresas a la
## carpa, el alumno al que ya le diste desaparece** y el hombre de traje está un
## poco más cerca. Al quinto no queda ninguno y él está pegado a la botarga.

enum Step { EMPTY, CARRYING, DONE }

var _at: Vector2 = Vector2(120.0, Arcade.GROUND_Y)
var _facing: int = -1
var _step: Step = Step.EMPTY
var _given: int = 0
## Los alumnos que todavía están ahí.
var _present: Array[bool] = []
## A quién le acabo de dar, para que desaparezca al volver a la carpa.
var _pending: int = -1
var _moving: bool = false


func _setup() -> void:
	_at = Arcade.TENT_PICKUP
	_step = Step.EMPTY
	_given = 0
	_pending = -1
	_present.clear()
	for i: int in Arcade.STUDENTS:
		_present.append(true)


func hud_text() -> String:
	return "GLOBOS %d/%d" % [_given, Arcade.STUDENTS]


func _tick(delta: float) -> void:
	if _step == Step.DONE:
		return
	_move(delta)
	if _step == Step.EMPTY:
		_try_pickup()
	else:
		_try_deliver()


func _move(delta: float) -> void:
	var push: float = 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		push -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		push += 1.0
	_moving = push != 0.0
	if _moving:
		_facing = signi(roundi(push))
	_at.x = clampf(_at.x + push * Arcade.WALK_SPEED * delta, 8.0,
		float(Arcade.SIZE.x) - 8.0)


## En la carpa se toma un globo. Y es también donde se cobra la desaparición
## del alumno anterior.
func _try_pickup() -> void:
	if absf(_at.x - Arcade.TENT_PICKUP.x) > Arcade.REACH:
		return
	if _pending >= 0:
		_present[_pending] = false
		_pending = -1
	if _given >= Arcade.STUDENTS:
		_step = Step.DONE
		_finish()
		return
	_step = Step.CARRYING
	AudioManager.play(Sounds.ARCADE_PICK)


## Con el globo encima, acercarse a un alumno que siga ahí se lo entrega.
func _try_deliver() -> void:
	for i: int in Arcade.STUDENT_SPOTS.size():
		if not _present[i] or i == _pending:
			continue
		if absf(_at.x - Arcade.STUDENT_SPOTS[i].x) > Arcade.REACH:
			continue
		_step = Step.EMPTY
		_given += 1
		_pending = i
		AudioManager.play(Sounds.ARCADE_PICK)
		return


## Dónde está el hombre de traje: detrás de la botarga, a la distancia que le
## toque según los globos entregados.
func _suit_x() -> float:
	var index: int = clampi(_given, 0, Arcade.SUIT_GAP.size() - 1)
	return clampf(_at.x + Arcade.SUIT_GAP[index], 10.0, float(Arcade.SIZE.x) - 10.0)


func _paint() -> void:
	# El manojo de la carpa, mientras queden globos por repartir.
	if _given < Arcade.STUDENTS:
		blit("globo_rojo", Arcade.TENT_BALLOONS[0])
		blit("globo_azul", Arcade.TENT_BALLOONS[1])
	for i: int in Arcade.STUDENT_SPOTS.size():
		if _present[i]:
			blit("alumno_%d" % (i % 4 + 1), Arcade.STUDENT_SPOTS[i])
	blit("traje_side", Vector2(_suit_x(), Arcade.GROUND_Y))
	blit(_botarga_frame(), _at, _facing < 0)
	# El globo que lleva en la mano.
	if _step == Step.CARRYING:
		blit("globo_rojo", _at + Vector2(float(_facing) * Arcade.CARRIED_BALLOON.x,
			Arcade.CARRIED_BALLOON.y))


func _botarga_frame() -> String:
	if not _moving:
		return "botarga_idle"
	return "botarga_walk1" if fmod(elapsed(), 0.34) < 0.17 else "botarga_walk2"

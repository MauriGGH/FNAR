class_name ArcadePosada
extends ArcadeLevel

## Nivel 1, "La posada": Santi recorre el patio saltando entre las mesas y
## juntando los ocho vasitos. Al final está el termo verde-naranja; al tocarlo
## aparece el hombre de traje a su lado, la pantalla se queda quieta un segundo
## y Santi ya es la botarga.
##
## No hay enemigos y caerse no castiga: se vuelve a subir. Las mesas y el piso
## están medidos sobre el fondo, en `data/arcade.gd`.

enum Step { PLAYING, FROZEN, DONE }

var _at: Vector2 = Vector2(14.0, Arcade.FLOOR_Y)
var _speed_y: float = 0.0
var _on_floor: bool = true
var _facing: int = 1
var _taken: Array[bool] = []
var _cups: int = 0
var _step: Step = Step.PLAYING
var _freeze_left: float = 0.0


func _setup() -> void:
	_at = Vector2(14.0, Arcade.FLOOR_Y)
	_speed_y = 0.0
	_cups = 0
	_step = Step.PLAYING
	_taken.clear()
	for i: int in Arcade.CUPS:
		_taken.append(false)


func hud_text() -> String:
	return "VASOS %d/%d" % [_cups, Arcade.CUPS]


func _tick(delta: float) -> void:
	if _step == Step.FROZEN:
		_freeze_left -= delta
		if _freeze_left <= 0.0:
			_step = Step.DONE
			_finish()
		return
	if _step != Step.PLAYING:
		return
	_move(delta)
	_pick_cups()
	_check_thermos()


## Las flechas o WASD mueven, espacio o arriba salta. La gravedad y el suelo
## salen de las mesas: la que esté bajo sus pies es su piso.
func _move(delta: float) -> void:
	var push: float = 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		push -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		push += 1.0
	if push != 0.0:
		_facing = signi(roundi(push))
	_at.x = clampf(_at.x + push * Arcade.WALK_SPEED * delta, 8.0,
		float(Arcade.SIZE.x) - 8.0)

	var jump: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) \
		or Input.is_key_pressed(KEY_W)
	if jump and _on_floor:
		_speed_y = -Arcade.JUMP_SPEED
		_on_floor = false
		AudioManager.play(Sounds.ARCADE_JUMP)

	_speed_y += Arcade.GRAVITY * delta
	var next_y: float = _at.y + _speed_y * delta
	var ground: float = _ground_under(_at.x, _at.y, next_y)
	if next_y >= ground:
		_at.y = ground
		_speed_y = 0.0
		_on_floor = true
	else:
		_at.y = next_y
		_on_floor = false


## Qué hay bajo sus pies: la mesa que esté cruzando hacia abajo, o el piso.
func _ground_under(x: float, from_y: float, to_y: float) -> float:
	var ground: float = Arcade.FLOOR_Y
	for table: Rect2 in Arcade.TABLES:
		if x < table.position.x or x > table.position.x + table.size.x:
			continue
		var top: float = table.position.y
		# Solo cuenta si venía de arriba: así se puede pasar por debajo.
		if from_y <= top and to_y >= top:
			ground = minf(ground, top)
	return ground


func _pick_cups() -> void:
	for i: int in Arcade.CUP_SPOTS.size():
		if _taken[i]:
			continue
		if _at.distance_to(Arcade.CUP_SPOTS[i]) > 9.0:
			continue
		_taken[i] = true
		_cups += 1
		AudioManager.play(Sounds.ARCADE_PICK)


## El termo solo se puede tomar con los ocho vasitos juntados.
func _check_thermos() -> void:
	if _cups < Arcade.CUPS:
		return
	if _at.distance_to(Arcade.THERMOS_AT) > 10.0:
		return
	_step = Step.FROZEN
	_freeze_left = Arcade.FREEZE_TIME
	AudioManager.play(Sounds.ARCADE_PICK)


func _paint() -> void:
	for i: int in Arcade.CUP_SPOTS.size():
		if not _taken[i]:
			blit("vaso", Arcade.CUP_SPOTS[i])
	if _cups >= Arcade.CUPS or _step != Step.PLAYING:
		blit("termo", Arcade.THERMOS_AT)
	if _step == Step.PLAYING:
		blit(_santi_frame(), _at, _facing < 0)
		return
	# Congelado: ya está el hombre de traje y Santi es la botarga.
	blit("traje_back", Arcade.THERMOS_AT + Vector2(10.0, 0.0))
	blit("botarga_idle", _at, _facing < 0)


## Quieto, caminando (dos cuadros) o en el aire.
func _santi_frame() -> String:
	if not _on_floor:
		return "santi_jump"
	var moving: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) \
		or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	if not moving:
		return "santi_idle"
	return "santi_walk1" if fmod(elapsed(), 0.3) < 0.15 else "santi_walk2"

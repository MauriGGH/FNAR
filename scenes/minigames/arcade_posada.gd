class_name ArcadePosada
extends ArcadeLevel

## Nivel 1, "La posada": Santi recorre el patio —**cinco pantallas de ancho**—
## por sus dos pisos, juntando los **quince vasitos** y esquivando a los
## borrachos y a las piñatas, hasta el termo verde-naranja del final.
##
## Los dos pisos son el patio de abajo (con las mesas de la foto como escalón) y
## un entarimado arriba, al que se sube por escaleras de tres peldaños. El piso
## de abajo **tiene huecos**: caerse cuesta una vida y te devuelve a la última
## plataforma en la que estabas a salvo.
##
## Las medidas están todas en `data/arcade.gd`. Con la gravedad y el salto de
## ahí, Santi sube 24 px y alcanza 40 px de largo, así que ningún hueco pasa de
## 22 px ni ningún peldaño de 12.

enum Step { PLAYING, FROZEN, DONE }

var _at: Vector2 = Vector2.ZERO
var _speed: Vector2 = Vector2.ZERO
var _on_floor: bool = true
var _facing: int = 1
var _taken: Array[bool] = []
var _cups: int = 0
var _step: Step = Step.PLAYING
var _freeze_left: float = 0.0
## Dónde estaba la última vez que pisó suelo firme, para devolverlo ahí.
var _safe_at: Vector2 = Vector2.ZERO
## Lo que le queda de resbalón, y por dónde van los borrachos.
var _slip_left: float = 0.0
var _drunks: Array[float] = []
var _drunk_dir: Array[int] = []
## Todas las plataformas del nivel, ya en coordenadas del mundo.
var _platforms: Array[Rect2] = []


func _setup() -> void:
	_at = Vector2(Arcade.START_X, Arcade.FLOOR_Y)
	_safe_at = _at
	_speed = Vector2.ZERO
	_slip_left = 0.0
	_cups = 0
	_step = Step.PLAYING
	_taken.clear()
	for i: int in Arcade.L1_CUPS.size():
		_taken.append(false)
	# Las mesas de la foto, los peldaños y el entarimado de arriba, todo junto.
	_platforms = Arcade.tables(1)
	_platforms.append_array(Arcade.L1_STAIRS)
	_platforms.append_array(Arcade.L1_UPPER)
	_drunks.clear()
	_drunk_dir.clear()
	for patrol: Rect2 in Arcade.L1_DRUNKS:
		_drunks.append(patrol.position.x)
		_drunk_dir.append(1)


func focus_x() -> float:
	return _at.x


func hud_text() -> String:
	return "VASOS %d/%d" % [_cups, Arcade.CUPS]


func _tick(delta: float) -> void:
	_move_drunks(delta)
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
	_check_hazards()
	_check_thermos()


## Las flechas o WASD mueven, espacio o arriba salta. En los charcos de ponche
## el agarre se va al suelo y Santi sigue de largo un segundo.
func _move(delta: float) -> void:
	var push: float = 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		push -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		push += 1.0
	if push != 0.0:
		_facing = signi(roundi(push))
	if _slip_left > 0.0:
		_slip_left -= delta
	var grip: float = Arcade.SLIP_GRIP if _slip_left > 0.0 else Arcade.NORMAL_GRIP
	_speed.x = lerpf(_speed.x, push * Arcade.WALK_SPEED,
		clampf(delta * grip, 0.0, 1.0))
	_at.x = clampf(_at.x + _speed.x * delta, 6.0, world_width - 6.0)

	var jump: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) \
		or Input.is_key_pressed(KEY_W)
	if jump and _on_floor:
		_speed.y = -Arcade.JUMP_SPEED
		_on_floor = false
		AudioManager.play(Sounds.ARCADE_JUMP)

	_speed.y += Arcade.GRAVITY * delta
	var next_y: float = _at.y + _speed.y * delta
	var ground: float = _ground_under(_at.x, _at.y, next_y)
	if next_y >= ground:
		_at.y = ground
		_speed.y = 0.0
		_on_floor = true
		_land()
	else:
		_at.y = next_y
		_on_floor = false
	# Por debajo del lienzo ya no hay nada: se cayó por un hueco.
	if _at.y > float(Arcade.SIZE.y) + 6.0:
		_fall()


## Qué hay bajo sus pies: la plataforma que esté cruzando hacia abajo, o el
## piso, que solo existe donde no hay hueco.
func _ground_under(x: float, from_y: float, to_y: float) -> float:
	var ground: float = INF
	if not _is_hole(x):
		ground = Arcade.FLOOR_Y
	for plank: Rect2 in _platforms:
		if x < plank.position.x or x > plank.position.x + plank.size.x:
			continue
		var top: float = plank.position.y
		# Solo cuenta si venía de arriba: así se puede pasar por debajo.
		if from_y <= top and to_y >= top:
			ground = minf(ground, top)
	return ground


func _is_hole(x: float) -> bool:
	for hole: Vector2 in Arcade.L1_HOLES:
		if x > hole.x and x < hole.x + hole.y:
			return true
	return false


## Acaba de pisar: si el sitio es firme, se apunta como el último seguro, y si
## es un charco, empieza a resbalar.
func _land() -> void:
	if not _is_hole(_at.x):
		_safe_at = _at
	for puddle: Vector2 in Arcade.L1_PUDDLES:
		if _at.y == Arcade.FLOOR_Y and _at.x > puddle.x \
				and _at.x < puddle.x + puddle.y:
			_slip_left = Arcade.SLIP_TIME
			return


## Se cayó por un hueco: una vida menos y de vuelta a la última plataforma.
func _fall() -> void:
	if not hurt():
		return
	_at = _safe_at
	_speed = Vector2.ZERO
	_on_floor = true
	_slip_left = 0.0


func _pick_cups() -> void:
	for i: int in Arcade.L1_CUPS.size():
		if _taken[i]:
			continue
		if _at.distance_to(Arcade.L1_CUPS[i]) > Arcade.CUP_REACH:
			continue
		_taken[i] = true
		_cups += 1
		AudioManager.play(Sounds.ARCADE_PICK)


## Los borrachos van y vienen por su tramo; las piñatas se columpian.
func _move_drunks(delta: float) -> void:
	for i: int in _drunks.size():
		var patrol: Rect2 = Arcade.L1_DRUNKS[i]
		_drunks[i] += float(_drunk_dir[i]) * patrol.size.y * delta
		if _drunks[i] <= patrol.position.x:
			_drunks[i] = patrol.position.x
			_drunk_dir[i] = 1
		elif _drunks[i] >= patrol.position.x + patrol.size.x:
			_drunks[i] = patrol.position.x + patrol.size.x
			_drunk_dir[i] = -1


## ¿Le dio algo? Los borrachos pegan a ras de suelo y las piñatas en el aire.
func _check_hazards() -> void:
	for i: int in _drunks.size():
		var patrol: Rect2 = Arcade.L1_DRUNKS[i]
		if absf(_at.x - _drunks[i]) < Arcade.HIT_RANGE.x \
				and absf(_at.y - patrol.position.y) < Arcade.HIT_RANGE.y:
			_take_hit()
			return
	for pinata: Vector2 in Arcade.L1_PINATA:
		var at: Vector2 = _pinata_at(pinata)
		if absf(_at.x - at.x) < Arcade.PINATA_SIZE \
				and absf((_at.y - 10.0) - at.y) < Arcade.PINATA_SIZE:
			_take_hit()
			return


## Dónde está una piñata ahora mismo: se columpia sobre su gancho.
func _pinata_at(pinata: Vector2) -> Vector2:
	var swing: float = sin(elapsed() * pinata.y)
	return Vector2(pinata.x + swing * Arcade.PINATA_SWING,
		Arcade.PINATA_ROPE + absf(swing) * 2.0)


## Un golpe cualquiera: una vida y un empujón hacia atrás, para despegarse.
## Mientras dura el parpadeo no se repite: si no, el empujón se aplicaba cada
## cuadro y te dejaba clavado encima de lo que te pegó.
func _take_hit() -> void:
	if invincible_left > 0.0:
		return
	if not hurt():
		return
	_speed = Vector2(float(-_facing) * Arcade.WALK_SPEED, -Arcade.JUMP_SPEED * 0.4)
	_on_floor = false


## El termo solo se puede tomar con los quince vasitos juntados.
func _check_thermos() -> void:
	if _cups < Arcade.CUPS:
		return
	if _at.distance_to(Arcade.L1_THERMOS) > 10.0:
		return
	_step = Step.FROZEN
	_freeze_left = Arcade.FREEZE_TIME
	AudioManager.play(Sounds.ARCADE_PICK)


func _paint() -> void:
	# El piso de arriba, las escaleras y los huecos, que el fondo no trae.
	for hole: Vector2 in Arcade.L1_HOLES:
		draw_rect(Rect2(Vector2(hole.x, Arcade.FLOOR_Y),
			Vector2(hole.y, float(Arcade.SIZE.y) - Arcade.FLOOR_Y)),
			Arcade.HOLE_COLOR)
	for plank: Rect2 in Arcade.L1_STAIRS:
		draw_plank(plank)
	for plank: Rect2 in Arcade.L1_UPPER:
		draw_plank(plank)
	for puddle: Vector2 in Arcade.L1_PUDDLES:
		draw_rect(Rect2(Vector2(puddle.x, Arcade.FLOOR_Y - 1.0),
			Vector2(puddle.y, 2.0)), Arcade.PUDDLE_COLOR)

	for i: int in Arcade.L1_CUPS.size():
		if not _taken[i]:
			blit("vaso", Arcade.L1_CUPS[i])
	if _cups >= Arcade.CUPS or _step != Step.PLAYING:
		blit("termo", Arcade.L1_THERMOS)

	for i: int in _drunks.size():
		var patrol: Rect2 = Arcade.L1_DRUNKS[i]
		blit("alumno_%d" % (i % 4 + 1), Vector2(_drunks[i], patrol.position.y),
			_drunk_dir[i] < 0)
	for pinata: Vector2 in Arcade.L1_PINATA:
		_draw_pinata(_pinata_at(pinata), pinata.x)

	if _step == Step.PLAYING:
		if not is_blinking():
			blit(_santi_frame(), _at, _facing < 0)
		return
	# Congelado: ya está el hombre de traje y Santi es la botarga.
	blit("traje_back", Arcade.L1_THERMOS + Vector2(10.0, 0.0))
	blit("botarga_idle", _at, _facing < 0)


## La piñata: su lazo desde el techo y una estrella de cuatro puntas, como la
## que ya viene pintada en el fondo.
func _draw_pinata(at: Vector2, pivot_x: float) -> void:
	draw_line(Vector2(pivot_x, 0.0), at, Arcade.PLANK_TOP, 1.0)
	var size: float = Arcade.PINATA_SIZE
	draw_rect(Rect2(at - Vector2(size * 0.5, 1.5), Vector2(size, 3.0)),
		Arcade.PINATA_COLOR)
	draw_rect(Rect2(at - Vector2(1.5, size * 0.5), Vector2(3.0, size)),
		Arcade.PINATA_COLOR)
	draw_rect(Rect2(at - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Arcade.PINATA_CORE)


## Quieto, caminando (dos cuadros) o en el aire.
func _santi_frame() -> String:
	if not _on_floor:
		return "santi_jump"
	if absf(_speed.x) < 6.0:
		return "santi_idle"
	return "santi_walk1" if fmod(elapsed(), 0.3) < 0.15 else "santi_walk2"

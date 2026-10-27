class_name SergioRescue
extends Control

## El rescate de Sergio, de principio a fin. Esta capa lleva los dos tramos que
## van a pantalla completa:
##
##   1. **El susto congelado**: el primer cuadro del jumpscare que iba a
##      matarte, quieto y en blanco y negro.
##   2. **El tótem**, al estilo del de Minecraft: crece de golpe con un rebote,
##      tiembla, gira sobre su eje y sale volando mientras suelta partículas
##      cuadradas verdes y amarillas.
##
## Lo de en medio —el haz de luz y Sergio bajando— lo dibuja la oficina
## (`scenes/office/sergio_arrival.gd`), porque va en su vista central. Esta capa
## se lo pide y espera.
##
## **Todo va pegado a una sola pista**, `sergio_rescate`: el congelado hasta los
## 6 s, el haz ahí, el tótem a los 14 s y, cuando el audio se acaba, la noche
## sigue. Antes eran tres sonidos sueltos que acabaron encimándose; ahora no hay
## nada que sincronizar a mano más que estos tres números, que están en
## `data/sergio.gd`.
##
## Lo único que suena **encima** de la pista es el tronido del tótem, en el
## mismo instante en que se activa y suelta sus partículas: va fuera de la
## secuencia del rescate justo para que se oigan los dos a la vez.

## Terminó todo: la noche puede seguir.
signal finished()
## Se acabó el congelado: que la oficina traiga a Sergio.
signal sergio_requested()
## El tótem acabó de girar: que la oficina lo despida, mientras suena la cola
## de la música.
signal totem_done()

const GREYSCALE_SHADER: String = "res://scenes/ui/greyscale.gdshader"
const JUMPSCARE_PATH: String = "res://assets/art/jumpscares/jumpscare_%s"
## Lo que tarda el susto congelado en desaparecer, para dejar ver la oficina
## cuando baja Sergio.
const UNFREEZE_TIME: float = 0.45

enum Phase { IDLE, FREEZE, WAITING, TOTEM, TAIL }

var is_playing: bool = false

var _phase: Phase = Phase.IDLE
var _elapsed: float = 0.0
## Lo que lleva el tótem desde que apareció.
var _totem_elapsed: float = 0.0
var _totem: Texture2D = null
var _particles: Array[Dictionary] = []
## Lo que dura la pista, que es lo que dura el rescate.
var _total: float = Sergio.RESCUE_FALLBACK_TIME
## Lo que lleva la escena desde que arrancó, para ir cuadrando los tiempos.
var _clock: float = 0.0

@onready var _frozen: TextureRect = TextureRect.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# El tótem y sus partículas son pixel art: nada de suavizado.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	set_process(false)
	_totem = Sergio.texture(Sergio.TOTEM)

	# El cuadro congelado del susto, en blanco y negro.
	_frozen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frozen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_frozen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frozen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(GREYSCALE_SHADER):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load(GREYSCALE_SHADER)
		material.set_shader_parameter("amount", 1.0)
		material.set_shader_parameter("darken", 0.35)
		_frozen.material = material
	add_child(_frozen)


## Arranca el rescate con el susto que se quedó a medias. `jumpscare_id` es el
## del profe que iba a matarte; se enseña su primer cuadro, el de la variante
## `_a`, que es el que se congela.
func play(jumpscare_id: String) -> void:
	if is_playing:
		return
	is_playing = true
	visible = true
	_phase = Phase.FREEZE
	_elapsed = 0.0
	_clock = 0.0
	_particles.clear()
	_frozen.texture = _scare_texture(jumpscare_id)
	_frozen.visible = _frozen.texture != null
	_frozen.modulate.a = 1.0
	set_process(true)
	# La pista del rescate es una y manda ella: la escena se cuelga de sus
	# tiempos. Como secuencia, calla cualquier resto de un rescate anterior.
	var length: float = AudioManager.length(Sounds.SERGIO_RESCUE)
	_total = length if length > 0.0 else Sergio.RESCUE_FALLBACK_TIME
	AudioManager.begin_sequence(Sounds.SEQ_RESCUE)
	AudioManager.play_in_sequence(Sounds.SEQ_RESCUE, Sounds.SERGIO_RESCUE)
	queue_redraw()


## El primer cuadro del susto: la variante `_a` si está, y si no la normal.
func _scare_texture(jumpscare_id: String) -> Texture2D:
	if jumpscare_id.is_empty():
		return null
	var first: Texture2D = GameAssets.load_texture(JUMPSCARE_PATH % ("%s_a" % jumpscare_id))
	return first if first != null else GameAssets.load_texture(JUMPSCARE_PATH % jumpscare_id)


## Entra el tótem. Lo pide el reloj de la pista, a los 14 s: para entonces
## Sergio ya bajó (el haz entra a los 6 y la bajada dura 1.8).
func start_totem() -> void:
	if not is_playing or _phase == Phase.TOTEM:
		return
	_phase = Phase.TOTEM
	_elapsed = 0.0
	_totem_elapsed = 0.0
	# El susto deja de verse: lo que importa ahora es el tótem.
	_frozen.visible = false
	_spawn_particles()
	# El tronido va con las partículas y **encima** de la pista: con `play()` a
	# secas, no en la secuencia del rescate, que lo dejaría esperando el final
	# de la música.
	AudioManager.play(Sounds.TOTEM_BURST)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	_clock += delta
	match _phase:
		Phase.FREEZE:
			if _clock >= Sergio.RESCUE_BEAM_AT:
				_phase = Phase.WAITING
				_elapsed = 0.0
				# El susto se va: lo que sigue pasa en la oficina y hay que
				# poder verla.
				create_tween().tween_property(_frozen, "modulate:a", 0.0,
					UNFREEZE_TIME)
				sergio_requested.emit()
		Phase.WAITING:
			if _clock >= Sergio.RESCUE_TOTEM_AT:
				start_totem()
		Phase.TOTEM:
			_totem_elapsed += delta
			_update_particles(delta)
			if _totem_elapsed >= _totem_total():
				# El tótem ya voló: Sergio se despide mientras suena la cola.
				_phase = Phase.TAIL
				totem_done.emit()
		Phase.TAIL:
			if _clock >= _total:
				_stop()
		Phase.IDLE:
			set_process(false)
	queue_redraw()


func _totem_total() -> float:
	return Sergio.TOTEM_GROW_TIME + Sergio.TOTEM_SHAKE_TIME + Sergio.TOTEM_SPIN_TIME


func _stop() -> void:
	is_playing = false
	visible = false
	_phase = Phase.IDLE
	set_process(false)
	finished.emit()


# --- El tótem -----------------------------------------------------------------

## Dónde va el tótem y cómo está deformado ahora mismo. Devuelve el centro, la
## escala en X (negativa a media vuelta) y la escala en Y.
func _totem_state() -> Dictionary:
	var grow: float = Sergio.TOTEM_GROW_TIME
	var shake: float = grow + Sergio.TOTEM_SHAKE_TIME
	var height: float = size.y * Sergio.TOTEM_HEIGHT
	var center: Vector2 = size * 0.5
	var scale_x: float = 1.0
	var scale_y: float = 1.0

	if _totem_elapsed < grow:
		# Crece de golpe y se pasa un poco, que es el rebote.
		var t: float = _totem_elapsed / grow
		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		scale_y = lerpf(Sergio.TOTEM_FROM / Sergio.TOTEM_HEIGHT, 1.0, eased) \
			+ sin(t * PI) * 0.12
		scale_x = scale_y
	elif _totem_elapsed < shake:
		# Tiembla en su sitio.
		var amount: float = Sergio.TOTEM_SHAKE_PIXELS * size.y / 1080.0
		center += Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
	else:
		# Gira sobre su eje mientras se encoge y sube.
		var t: float = clampf((_totem_elapsed - shake) / Sergio.TOTEM_SPIN_TIME, 0.0, 1.0)
		scale_x = cos(t * TAU * float(Sergio.TOTEM_SPINS))
		scale_y = lerpf(1.0, 0.25, t)
		center.y -= size.y * Sergio.TOTEM_RISE * t * t
	return {"center": center, "height": height * scale_y, "flip": scale_x}


func _draw() -> void:
	if _phase != Phase.TOTEM:
		return
	for particle: Dictionary in _particles:
		var life: float = float(particle["life"])
		if life <= 0.0:
			continue
		var box: float = Sergio.PARTICLE_SIZE * size.y / 1080.0
		var color: Color = particle["color"]
		draw_rect(Rect2(particle["at"] as Vector2 - Vector2(box, box) * 0.5,
			Vector2(box, box)),
			Color(color.r, color.g, color.b, clampf(life / Sergio.PARTICLE_LIFE, 0.0, 1.0)))
	if _totem == null:
		return
	var state: Dictionary = _totem_state()
	var height: float = float(state["height"])
	var flip: float = float(state["flip"])
	var width: float = height * float(_totem.get_width()) / float(_totem.get_height())
	var center: Vector2 = state["center"]
	# El giro es un volteo de la escala en X: el tótem se pone de canto y pasa
	# al otro lado, como el de Minecraft.
	var rect: Rect2 = Rect2(center - Vector2(width * flip, height) * 0.5,
		Vector2(width * flip, height))
	draw_texture_rect(_totem, rect, false)


# --- Las partículas -----------------------------------------------------------

func _spawn_particles() -> void:
	_particles.clear()
	for i: int in Sergio.PARTICLES:
		var angle: float = randf() * TAU
		var speed: float = Sergio.PARTICLE_SPEED * randf_range(0.4, 1.0) * size.y / 1080.0
		_particles.append({
			"at": size * 0.5,
			"speed": Vector2(cos(angle), sin(angle)) * speed,
			"life": Sergio.PARTICLE_LIFE * randf_range(0.6, 1.0),
			"color": Sergio.PARTICLE_COLORS[randi() % Sergio.PARTICLE_COLORS.size()],
		})


func _update_particles(delta: float) -> void:
	for particle: Dictionary in _particles:
		if float(particle["life"]) <= 0.0:
			continue
		particle["life"] = float(particle["life"]) - delta
		var speed: Vector2 = particle["speed"]
		speed.y += Sergio.PARTICLE_GRAVITY * delta * size.y / 1080.0
		particle["speed"] = speed
		particle["at"] = (particle["at"] as Vector2) + speed * delta

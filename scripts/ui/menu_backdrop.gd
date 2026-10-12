class_name MenuBackdrop
extends Control

## El fondo de los menús: la foto del pasillo con el guardia, que de vez en
## cuando da un "tic", como el menú de Sister Location. La imagen se desgarra
## por franjas, los colores se separan, aparece un cuadro con uno de los profes
## encima, se congela un instante y un golpe de estática la devuelve a la normal.
##
## Los cuadros del tic (`menu_tic_rochis`, `menu_tic_urena`, `menu_tic_mamador`)
## están alineados con `menu_fondo_0`: solo cambia el profe, así que el cambio
## se nota únicamente en él. Y muy de vez en cuando sale `menu_tic_ultra`, con
## los tres a la vez y los ojos negros.
##
## El desgarro, la separación de color y el congelado los hace
## `scenes/ui/menu_glitch.gdshader` sobre la propia imagen: no hay cuadros extra.
##
## Se mete con MenuBackdrop.build(pantalla).

const BACKGROUND_PATH: String = "res://assets/art/menu/menu_fondo_0"
const TIC_PATH: String = "res://assets/art/menu/menu_tic_%s"
## Si falta el arte del menú, se usa una cámara, que siempre existe.
const FALLBACK_PATH: String = "res://assets/art/cameras/cam13_vacia"
const GLITCH_SHADER: String = "res://scenes/ui/menu_glitch.gdshader"

## Los tres profes del tic normal y el cuadro de los tres juntos.
const TIC_IDS: Array[String] = ["rochis", "urena", "mamador"]
const ULTRA_ID: String = "ultra"
## Cada cuánto da un tic, y cada cuántos tics sale el ultra.
const MIN_GAP: float = 5.0
const MAX_GAP: float = 10.0
const ULTRA_ONE_IN: int = 8

## Los cuatro tiempos de un tic, en segundos: los dos cuadros de desgarro, el
## cuadro del profe con el desgarro bajando, el congelado y la estática. Suman
## unos 0.35 s; el ultra los alarga hasta medio segundo.
const PRE_TEAR_TIME: float = 0.07
const TIC_TEAR_TIME: float = 0.1
const FREEZE_TIME: float = 0.15
const STATIC_TIME: float = 0.05
const ULTRA_SCALE: float = 1.35

## Lo que se corren las franjas (de 10 a 40 px: el shader nunca baja del 25 %),
## la separación de color, en cuántas franjas se parte y lo alta que es la banda
## que baja sobre el cuadro del profe.
const PRE_TEAR_PIXELS: float = 40.0
const TIC_TEAR_PIXELS: float = 32.0
const RGB_PIXELS: float = 5.0
const BANDS: float = 18.0
const TEAR_BAND_HEIGHT: float = 0.22

## Lo oscuro que se pone encima, para que el texto se lea.
const DIM: Color = Color(0.0, 0.0, 0.02, 0.62)
## La estática de reposo y la del tic.
const STATIC_IDLE: float = 0.08
const STATIC_TIC: float = 0.5

## Un tic que se quiere ver en cuanto se abra el menú. Lo pone el panel de
## pruebas antes de cambiar de escena, porque el panel vive en la noche y el
## fondo en los menús.
static var pending_tic: String = ""
## Lo que espera antes de soltar ese tic, para que no salga encima del fundido.
const PENDING_DELAY: float = 0.6

enum Phase { IDLE, PRE_TEAR, TIC_TEAR, FREEZE, STATIC }

var _base: Texture2D = null
var _tics: Dictionary = {}          # id -> Texture2D
var _picture: TextureRect = null
var _material: ShaderMaterial = null
var _static_layer: StaticFrames = null

var _phase: Phase = Phase.IDLE
var _phase_left: float = 0.0
var _next_tic: float = 0.0
## El tic que se está viendo y el anterior, que no se repite.
var _current: String = ""
var _last: String = ""
## Lo que dura este tic respecto a lo normal (el ultra dura más).
var _scale: float = 1.0


## Mete el fondo como primer hijo de una pantalla y lo devuelve.
static func build(parent: Control) -> MenuBackdrop:
	var backdrop: MenuBackdrop = MenuBackdrop.new()
	backdrop.name = "Backdrop"
	parent.add_child(backdrop)
	parent.move_child(backdrop, 0)
	return backdrop


func _ready() -> void:
	# Con anclas y márgenes a la vez: puesto ya dentro del árbol, solo las
	# anclas dejarían el nodo de tamaño cero.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_frames()
	_build_layers()
	_next_tic = randf_range(MIN_GAP, MAX_GAP)
	# Un tic pedido desde el panel de pruebas sale enseguida.
	if not pending_tic.is_empty():
		_next_tic = PENDING_DELAY


## La foto de siempre y los cuatro cuadros del tic. Si no hay nada, se cae a
## una cámara, para que los menús no se queden en negro.
func _load_frames() -> void:
	_base = GameAssets.load_texture(BACKGROUND_PATH)
	if _base == null:
		_base = GameAssets.load_texture(FALLBACK_PATH)
	for tic_id: String in TIC_IDS + [ULTRA_ID]:
		var texture: Texture2D = GameAssets.load_texture(TIC_PATH % tic_id)
		if texture != null:
			_tics[tic_id] = texture


func _build_layers() -> void:
	if _base != null:
		_picture = TextureRect.new()
		_picture.name = "Picture"
		_picture.texture = _base
		_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(GLITCH_SHADER):
			_material = ShaderMaterial.new()
			_material.shader = load(GLITCH_SHADER)
			_picture.material = _material
		add_child(_picture)
		_set_tear(0.0, 0.0, 0.5, 2.0)

	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_static_layer = ScreenFx.add_static(self, STATIC_IDLE)
	ScreenFx.add_scanlines(self)


# --- El tic -------------------------------------------------------------------

func _process(delta: float) -> void:
	if _picture == null or _tics.is_empty():
		return
	if _phase != Phase.IDLE:
		_advance(delta)
		return
	_next_tic -= delta
	if _next_tic <= 0.0:
		play_tic(pending_tic)
		pending_tic = ""


## Suelta un tic. Sin id, lo sortea: casi siempre uno de los tres profes (nunca
## el mismo dos veces seguidas) y uno de cada ocho el cuadro de los tres.
func play_tic(tic_id: String = "") -> void:
	if _picture == null or _tics.is_empty():
		return
	var chosen: String = tic_id if not tic_id.is_empty() else _pick()
	if not _tics.has(chosen):
		return
	_current = chosen
	_scale = ULTRA_SCALE if chosen == ULTRA_ID else 1.0
	# El ultra no cuenta para "no repetir": después de él puede salir cualquiera.
	_last = "" if chosen == ULTRA_ID else chosen
	_enter(Phase.PRE_TEAR)


func _pick() -> String:
	if randi() % ULTRA_ONE_IN == 0 and _tics.has(ULTRA_ID):
		return ULTRA_ID
	var pool: Array[String] = []
	for tic_id: String in TIC_IDS:
		if tic_id != _last and _tics.has(tic_id):
			pool.append(tic_id)
	if pool.is_empty():
		return _last
	return pool[randi() % pool.size()]


## Cada tramo del tic pone su imagen y su desgarro, y arranca su cuenta.
func _enter(phase: Phase) -> void:
	_phase = phase
	match phase:
		Phase.PRE_TEAR:
			# Todavía la foto de siempre, pero ya rota de arriba abajo. El
			# golpe entra aquí, con el primer cuadro desgarrado: es el momento
			# en que la imagen se rompe.
			_phase_left = PRE_TEAR_TIME * _scale
			_picture.texture = _base
			_set_tear(PRE_TEAR_PIXELS, RGB_PIXELS, 0.5, 2.0)
			# El de los tres lleva su propio glitch, más largo.
			AudioManager.play(Sounds.MENU_GLITCH_LONG if _current == ULTRA_ID
				else Sounds.MENU_TIC)
		Phase.TIC_TEAR:
			# Entra el profe y el desgarro se vuelve una banda que baja.
			_phase_left = TIC_TEAR_TIME * _scale
			_picture.texture = _tics[_current] as Texture2D
			_set_tear(TIC_TEAR_PIXELS, RGB_PIXELS, 0.0, TEAR_BAND_HEIGHT)
		Phase.FREEZE:
			# Congelado: el profe quieto y sin desgarro, que es lo que asusta.
			_phase_left = FREEZE_TIME * _scale
			_set_tear(0.0, 0.0, 0.5, 2.0)
		Phase.STATIC:
			# La estática tapa el cambio de vuelta a la foto de siempre.
			_phase_left = STATIC_TIME * _scale
			_picture.texture = _base
			ScreenFx.set_static_strength(_static_layer, STATIC_TIC)
		Phase.IDLE:
			_phase_left = 0.0
			_set_tear(0.0, 0.0, 0.5, 2.0)
			ScreenFx.set_static_strength(_static_layer, STATIC_IDLE)
			_next_tic = randf_range(MIN_GAP, MAX_GAP)


func _advance(delta: float) -> void:
	_phase_left -= delta
	if _phase == Phase.PRE_TEAR:
		# Los dos cuadros de desgarro no se parecen entre sí.
		_reseed()
	elif _phase == Phase.TIC_TEAR:
		# La banda baja de arriba abajo mientras dura este tramo.
		var done: float = 1.0 - clampf(_phase_left / maxf(TIC_TEAR_TIME * _scale, 0.0001),
			0.0, 1.0)
		_set_tear(TIC_TEAR_PIXELS, RGB_PIXELS, done, TEAR_BAND_HEIGHT)
	if _phase_left > 0.0:
		return
	match _phase:
		Phase.PRE_TEAR:
			_enter(Phase.TIC_TEAR)
		Phase.TIC_TEAR:
			_enter(Phase.FREEZE)
		Phase.FREEZE:
			_enter(Phase.STATIC)
		Phase.STATIC:
			_enter(Phase.IDLE)


func _set_tear(pixels: float, rgb: float, at_y: float, height: float) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("tear_pixels", pixels)
	_material.set_shader_parameter("rgb_pixels", rgb)
	_material.set_shader_parameter("tear_y", at_y)
	_material.set_shader_parameter("tear_height", height)
	_material.set_shader_parameter("bands", BANDS)
	if pixels > 0.0:
		_reseed()


func _reseed() -> void:
	if _material != null:
		_material.set_shader_parameter("noise_seed", randf() * 100.0)


# --- Depuración ---------------------------------------------------------------

## Para el menú de pruebas: provoca un tic sin esperar.
func debug_tic(tic_id: String = "") -> void:
	if _phase == Phase.IDLE:
		play_tic(tic_id)


## En qué va el tic, para enseñarlo en el panel.
func phase_text() -> String:
	match _phase:
		Phase.PRE_TEAR:
			return "desgarro (%s)" % _current
		Phase.TIC_TEAR:
			return "entra %s" % _current
		Phase.FREEZE:
			return "congelado (%s)" % _current
		Phase.STATIC:
			return "estática"
	return "en reposo, el próximo en %.1f s" % _next_tic

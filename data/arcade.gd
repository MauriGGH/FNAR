class_name Arcade
extends RefCounted

## La maquinita: los tres minijuegos que cuentan lo que le pasó a Santi, al
## estilo de los de FNAF. Salen **entre noches**, después del 6 AM y antes del
## periódico, y el premio es el tótem de Sergio.
##
## Todo lo que es número de diseño está aquí. Las posiciones **no se adivinan**:
## están medidas sobre los propios fondos de `assets/art/minijuego/fondos/`
## (160x90 px), buscando los manteles blancos de las mesas, la línea del pasto
## y la puerta roja de la sala de juntas.

const ART: String = "res://assets/art/minijuego/%s"
const BACKGROUND: String = "fondos/%s"
const SPRITE: String = "sprites/%s"

## El lienzo del juego. Todo se dibuja aquí dentro y se escala a la pantalla
## con filtro nearest y en pasos enteros, para que no se deforme ni un píxel.
const SIZE: Vector2i = Vector2i(160, 90)

## Cuántos niveles hay y en qué orden se van dando.
const LEVELS: int = 3
## La probabilidad de que salga al acabar una noche.
const CHANCE: int = 30
## Lo que dan los niveles 1 y 2 antes de rendirse.
const TIME_LIMIT: float = 60.0

# --- Nivel 1: la posada -------------------------------------------------------
## Las tres mesas, medidas por sus manteles: x de inicio, x de fin y la altura
## de arriba, donde se para Santi.
const TABLES: Array[Rect2] = [
	Rect2(20.0, 58.0, 29.0, 14.0),
	Rect2(62.0, 48.0, 31.0, 24.0),
	Rect2(106.0, 56.0, 31.0, 16.0),
]
## Donde acaba el patio: el piso de madera.
const FLOOR_Y: float = 72.0
## Cuántos vasitos hay que juntar y dónde están (x, y de sus pies).
const CUPS: int = 8
const CUP_SPOTS: Array[Vector2] = [
	Vector2(26.0, 58.0), Vector2(40.0, 58.0), Vector2(52.0, 72.0),
	Vector2(70.0, 48.0), Vector2(86.0, 48.0), Vector2(99.0, 72.0),
	Vector2(112.0, 56.0), Vector2(130.0, 56.0),
]
## El termo, al final del patio.
const THERMOS_AT: Vector2 = Vector2(148.0, 72.0)
## Santi: lo rápido que corre, lo que salta y la gravedad.
const WALK_SPEED: float = 46.0
const JUMP_SPEED: float = 112.0
const GRAVITY: float = 260.0
## Lo que se congela la pantalla cuando aparece el hombre de traje.
const FREEZE_TIME: float = 1.0

# --- Nivel 2: la bienvenida ---------------------------------------------------
## La carpa de los globos y la línea del suelo.
const TENT: Rect2 = Rect2(92.0, 36.0, 62.0, 14.0)
const TENT_PICKUP: Vector2 = Vector2(120.0, 80.0)
const GROUND_Y: float = 80.0
## El manojo de globos de la carpa: cuelga del toldo, no está tirado en el
## pasto, así que va por encima del punto donde se recogen.
const TENT_BALLOONS: Array[Vector2] = [
	Vector2(112.0, 70.0), Vector2(122.0, 66.0),
]
## Y el que va en la mano: al costado de la botarga (del lado al que mira) y a
## la altura de su mano, no encima de la cabeza.
const CARRIED_BALLOON: Vector2 = Vector2(15.0, -14.0)
## Los cinco alumnos esperando, de izquierda a derecha.
const STUDENTS: int = 5
const STUDENT_SPOTS: Array[Vector2] = [
	Vector2(16.0, 80.0), Vector2(34.0, 80.0), Vector2(52.0, 80.0),
	Vector2(68.0, 80.0), Vector2(84.0, 80.0),
]
## Qué tan cerca se va poniendo el hombre de traje, en píxeles **detrás de la
## botarga**, con 0, 1, 2... globos entregados. Se mide contra ella y no contra
## el fondo porque ella se pasa el nivel yendo y viniendo: así la siguen de
## verdad y al quinto globo lo tiene pegado, donde sea que esté.
const SUIT_GAP: Array[float] = [72.0, 58.0, 46.0, 34.0, 22.0, 12.0]
## Lo que hay que acercarse para recoger o entregar.
const REACH: float = 12.0

# --- Nivel 3: la junta --------------------------------------------------------
## La puerta doble de la sala, medida sobre el fondo, y el suelo del pasillo.
const DOOR: Rect2 = Rect2(130.0, 22.0, 25.0, 36.0)
const HALL_Y: float = 62.0
## Dónde arrancan la botarga y el hombre de traje, y a qué distancia va él.
const START_X: float = 12.0
const SUIT_AHEAD: float = 34.0
## El parpadeo de las luces y el letrero de la pared.
const FLICKER_MIN: float = 0.08
const FLICKER_MAX: float = 0.9
const HELP_TEXT: String = "AYÚDANOS"
const HELP_AT: Vector2 = Vector2(46.0, 22.0)
const HELP_COLOR: Color = Color(0.75, 0.1, 0.12)
const HELP_ON: float = 0.7
const HELP_OFF: float = 1.1
## Lo que dura el final: la puerta cerrándose y la pantalla roja.
const DOOR_TIME: float = 1.2
const RED_TIME: float = 2.0
const RED: Color = Color(0.55, 0.04, 0.05)

# --- El final, después de cualquier nivel ------------------------------------
## El altar y los dos que lo acompañan, en el lienzo de 160x90.
const ALTAR_AT: Vector2 = Vector2(80.0, 62.0)
const SERGIO_AT: Vector2 = Vector2(56.0, 62.0)
const SANTI_AT: Vector2 = Vector2(104.0, 62.0)
const ENDING_TEXT: String = "TOMA. TE VA A HACER FALTA."
## Lo que tarda en escribirse, letra por letra, y lo que se queda al acabar.
const TYPE_SPEED: float = 14.0
const ENDING_HOLD: float = 2.6
## El haz de luz del altar.
const BEAM_WIDTH: float = 52.0
const BEAM_ALPHA: float = 0.26
## El charco de luz alrededor del altar. Los recortes de Sergio y de Santi son
## siluetas casi negras, así que si el fondo no se aclara no se ven: es contra
## esta luz que se recortan. Es una elipse suave centrada un poco arriba del
## suelo, para que les dé de cuerpo entero.
const GLOW_CENTER: Vector2 = Vector2(80.0, 54.0)
const GLOW_RADIUS: Vector2 = Vector2(82.0, 48.0)
const GLOW_ALPHA: float = 0.34
## Dónde se escribe la frase del final.
const ENDING_TEXT_Y: float = 76.0

# --- La pantalla de la maquinita ---------------------------------------------
## La estática del arranque y el apagón del final.
const BOOT_TIME: float = 0.5
const SHUTDOWN_TIME: float = 0.55
## El texto del HUD, en píxeles del lienzo. Lo dibuja `ArcadeFont`, que mide
## 3x5 por letra, así que el margen es la esquina de la primera.
const TEXT_MARGIN: Vector2 = Vector2(5.0, 5.0)
const TEXT_COLOR: Color = Color(0.95, 0.95, 0.9)
## El rótulo del nivel, que va fuera del lienzo y por eso en píxeles de pantalla.
const LABEL_SIZE: int = 30


static func background(level: int) -> Texture2D:
	var names: Array[String] = ["nivel1_posada", "nivel2_bienvenida", "nivel3_junta"]
	var index: int = clampi(level, 1, names.size()) - 1
	return GameAssets.load_texture(ART % (BACKGROUND % names[index]))


static func sprite(name: String) -> Texture2D:
	return GameAssets.load_texture(ART % (SPRITE % name))


## El nombre que sale en la pantalla de cada nivel.
static func title(level: int) -> String:
	var names: Array[String] = ["LA POSADA", "LA BIENVENIDA", "LA JUNTA"]
	return names[clampi(level, 1, names.size()) - 1]

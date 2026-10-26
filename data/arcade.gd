class_name Arcade
extends RefCounted

## La maquinita: los tres minijuegos que cuentan lo que le pasó a Santi, al
## estilo de los de FNAF. Salen **entre noches**, después del 6 AM y antes del
## periódico, y el premio es el tótem de Sergio.
##
## Todo lo que es número de diseño está aquí. Las posiciones de lo que sale en
## el fondo **no se adivinan**: están medidas sobre los propios fondos de
## `assets/art/minijuego/fondos/` (160x90 px), buscando los manteles blancos de
## las mesas, la línea del pasto y la puerta roja de la sala de juntas.
##
## **Los niveles son más anchos que la pantalla**: de cuatro a cinco pantallas,
## con la cámara siguiendo a Santi. El fondo se repite a lo largo del mundo —es
## una sola foto de 160x90— y las mesas de cada repetición sirven de plataforma,
## así que el mundo se construye con las mismas tres mesas que ya trae pintadas.
## Lo que el arte no tiene (el piso de arriba, las escaleras, los huecos, la
## piñata, los ventiladores, las macetas) lo dibuja el código con rectángulos,
## en los mismos colores del fondo.

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

# --- Reglas que comparten los tres --------------------------------------------
## Las vidas, que son corazones de píxeles arriba a la izquierda.
const LIVES: int = 3
## Lo que dura cada nivel antes de rendirse, y el aviso de que queda poco.
## **Los tres a 150 s.** Hubo un rato en que el 2 necesitó 210, pero eso era un
## síntoma: lo que no dejaba acabarlo no era el reloj sino los globos que
## reventaban en cada viaje. Arreglado eso, se pasa en 61 s.
const TIME_LIMITS: Array[float] = [150.0, 150.0, 150.0]
const TIME_WARNING: float = 20.0
## Al cobrar un golpe: lo que parpadea y lo que no te pueden volver a tocar.
const HURT_FLICKER_TIME: float = 1.0
const HURT_FLICKER_HZ: float = 12.0
## Lo ancho que es el mundo de cada nivel, en pantallas de 160 px.
## El 2 es el más corto a propósito: son **ocho viajes de ida y vuelta** al
## puesto, y con cinco pantallas no cabían en los 150 s ni jugando perfecto.
const WORLD_SCREENS: Array[float] = [5.0, 4.0, 5.0]
## Dónde se queda la cámara respecto a Santi: centrada, con un poco de ventaja
## hacia donde camina.
const CAMERA_AHEAD: float = 0.0

## Santi y la botarga: lo rápido que corren, lo que saltan y la gravedad.
## Con estos números el salto sube 24 px y alcanza unos 40 px de largo, así que
## ningún hueco pasa de 22 px ni ningún escalón de 22 px de alto.
const WALK_SPEED: float = 56.0
const JUMP_SPEED: float = 112.0
const GRAVITY: float = 260.0
## Lo que se congela la pantalla cuando aparece el hombre de traje.
const FREEZE_TIME: float = 1.0

# --- Nivel 1: la posada -------------------------------------------------------
## Las tres mesas de **una** repetición del fondo, medidas por sus manteles:
## x, la altura de arriba (donde se para Santi), el ancho y el grueso.
const TABLES: Array[Rect2] = [
	Rect2(20.0, 58.0, 29.0, 4.0),
	Rect2(62.0, 48.0, 31.0, 4.0),
	Rect2(106.0, 56.0, 31.0, 4.0),
]
## Donde acaba el patio: el piso de madera.
const FLOOR_Y: float = 72.0
## El piso de arriba y los colores con los que se pintan las tablas y los
## huecos, sacados del propio fondo.
const UPPER_Y: float = 34.0
const PLANK_COLOR: Color = Color(0.36, 0.24, 0.15)
const PLANK_TOP: Color = Color(0.52, 0.36, 0.22)
const HOLE_COLOR: Color = Color(0.05, 0.04, 0.06)

## Las tablas del piso de arriba y las escaleras que suben hasta él, en
## coordenadas del mundo: x, altura de arriba, ancho y grueso.
## Cada tabla **empieza donde acaba su escalera**: si quedara un hueco entre el
## último peldaño y el entarimado, subir sería un salto a ciegas.
const L1_UPPER: Array[Rect2] = [
	Rect2(96.0, 34.0, 52.0, 3.0),
	Rect2(214.0, 34.0, 94.0, 3.0),
	Rect2(386.0, 34.0, 66.0, 3.0),
	Rect2(538.0, 34.0, 86.0, 3.0),
	Rect2(690.0, 34.0, 66.0, 3.0),
]
## Los escalones: cada uno sube 12 px y **se encabalga con el siguiente**, así
## que un salto a toda velocidad cae siempre en alguno. Con peldaños estrechos
## se pasaba de largo y no había manera de subir.
const L1_STAIRS: Array[Rect2] = [
	Rect2(160.0, 60.0, 24.0, 3.0), Rect2(178.0, 48.0, 24.0, 3.0),
	Rect2(196.0, 36.0, 24.0, 3.0),
	Rect2(330.0, 60.0, 24.0, 3.0), Rect2(348.0, 48.0, 24.0, 3.0),
	Rect2(366.0, 36.0, 24.0, 3.0),
	Rect2(482.0, 60.0, 24.0, 3.0), Rect2(500.0, 48.0, 24.0, 3.0),
	Rect2(518.0, 36.0, 24.0, 3.0),
	Rect2(634.0, 60.0, 24.0, 3.0), Rect2(652.0, 48.0, 24.0, 3.0),
	Rect2(670.0, 36.0, 24.0, 3.0),
]
## Los huecos del piso de abajo: x de inicio y ancho. Ninguno pasa de 22 px.
## Van **debajo del entarimado**, no en su punta: así bajarse de una tabla no
## cae en el vacío, pero el piso de abajo sigue roto.
const L1_HOLES: Array[Vector2] = [
	Vector2(104.0, 18.0), Vector2(250.0, 18.0), Vector2(410.0, 18.0),
	Vector2(560.0, 18.0), Vector2(706.0, 18.0),
]
## Los charcos de ponche: al pisarlos se resbala un segundo.
const L1_PUDDLES: Array[Vector2] = [
	Vector2(60.0, 26.0), Vector2(216.0, 28.0), Vector2(440.0, 26.0),
	Vector2(596.0, 28.0), Vector2(664.0, 26.0),
]
const PUDDLE_COLOR: Color = Color(0.45, 0.12, 0.16)
const SLIP_TIME: float = 1.0
## Lo que cuesta frenar o cambiar de sentido resbalando: cuanto más bajo, más
## patina.
const SLIP_GRIP: float = 1.2
const NORMAL_GRIP: float = 14.0

## Los quince vasitos, en coordenadas del mundo (x, y de sus pies).
const CUPS: int = 15
const L1_CUPS: Array[Vector2] = [
	Vector2(34.0, 58.0), Vector2(78.0, 48.0), Vector2(120.0, 34.0),
	Vector2(170.0, 60.0), Vector2(206.0, 36.0), Vector2(262.0, 34.0),
	Vector2(296.0, 34.0), Vector2(358.0, 48.0), Vector2(376.0, 36.0),
	Vector2(428.0, 34.0), Vector2(400.0, 72.0), Vector2(514.0, 48.0),
	Vector2(592.0, 34.0), Vector2(664.0, 48.0), Vector2(726.0, 34.0),
]
## Lo cerca que hay que estar para recogerlos. Con 9 px había que clavar el
## píxel: el vasito mide 8x10 y Santi 16x29, así que pasarle por encima tiene
## que valer.
const CUP_REACH: float = 12.0
## El termo, al final del patio.
const L1_THERMOS: Vector2 = Vector2(770.0, 72.0)

## Los tres alumnos borrachos: de qué x a qué x patrullan, a qué altura y lo
## rápido que van.
## Cada tramo va **entre dos huecos**: así no se les ve caminar sobre el vacío.
## Cada tramo va **entre dos escaleras y sin huecos debajo**: patrullar justo
## al pie de una escalera era injusto, porque cada vez que bajas de un peldaño
## caes encima de uno.
const L1_DRUNKS: Array[Rect2] = [
	Rect2(268.0, 72.0, 60.0, 26.0),
	Rect2(428.0, 72.0, 52.0, 30.0),
	Rect2(578.0, 72.0, 54.0, 34.0),
]
## Lo cerca que tiene que pasar uno para que cuente como golpe. **El alto va
## ajustado a propósito**: con 22 px te pegaban estando en el primer peldaño,
## que sube 12, y subirse a la escalera no servía de nada.
const HIT_RANGE: Vector2 = Vector2(9.0, 10.0)

## La piñata que se columpia: dónde cuelga, cuánto se abre, lo que tarda en ir
## y venir y lo largo que es el lazo.
const L1_PINATA: Array[Vector2] = [
	Vector2(330.0, 2.4), Vector2(480.0, 2.0),
]
const PINATA_SWING: float = 34.0
## Cuelgan **a la altura de la cabeza del que va por el patio de abajo**: ahí
## está la gracia de "pasar por debajo en el momento equivocado". Más arriba no
## le daría a nadie.
const PINATA_ROPE: float = 56.0
const PINATA_SIZE: float = 7.0
const PINATA_COLOR: Color = Color(0.85, 0.7, 0.2)
const PINATA_CORE: Color = Color(0.8, 0.25, 0.3)

# --- Nivel 2: la bienvenida ---------------------------------------------------
## El puesto de los globos, a la izquierda del todo, y la línea del suelo.
const GROUND_Y: float = 80.0
const L2_STAND: float = 24.0
## El manojo del puesto: cuelga del toldo, no está tirado en el pasto.
const TENT_BALLOONS: Array[Vector2] = [
	Vector2(16.0, 70.0), Vector2(30.0, 66.0),
]
## El globo que va en la mano: al costado de la botarga, a la altura de su mano.
const CARRIED_BALLOON: Vector2 = Vector2(15.0, -14.0)
## Los ocho alumnos, repartidos por el mundo.
const STUDENTS: int = 8
## Repartidos, pero **juntos**: la cuenta de los ocho viajes son 75 s de
## caminata limpia, que con los globos reventados y los rodeos deja la partida
## en unos dos minutos.
const L2_STUDENTS: Array[float] = [
	96.0, 150.0, 204.0, 258.0, 312.0, 366.0, 420.0, 474.0,
]
## Lo que hay que acercarse para recoger o entregar.
const REACH: float = 12.0
## Los ventiladores del techo: x y a qué altura cuelgan sus aspas. Si saltas
## debajo revientan el globo (no quitan vida: hay que volver por otro).
## Van **entre alumno y alumno**, nunca encima de uno: si el aspa estuviera
## justo donde se entrega, la botarga se quedaría sin salida cada vez que el de
## traje la acorrala ahí.
## Y el **primer tramo saliendo del puesto va limpio**: con un aspa ahí, el de
## traje te acorralaba en la única salida y el globo reventaba siempre.
##
## **Son tres, no seis.** Con una cada 100 px, el de traje te obligaba a brincar
## debajo de alguna en casi todos los viajes y el globo reventaba una y otra
## vez: el nivel se volvía ir y venir sin avanzar. Así, los alumnos de cerca se
## entregan sin riesgo y las aspas son el peaje de los viajes largos.
const L2_FANS: Array[Vector2] = [
	Vector2(231.0, 30.0), Vector2(393.0, 30.0), Vector2(501.0, 30.0),
]
const FAN_RADIUS: float = 11.0
const FAN_SPIN: float = 9.0
const FAN_COLOR: Color = Color(0.22, 0.24, 0.3)
## A qué altura llega la botarga saltando: por debajo de eso el aspa no alcanza.
const FAN_REACH_Y: float = 44.0
## Desde qué entrega sale el hombre de traje y lo rápido que va: empieza más
## lento que la botarga y acaba más rápido.
const SUIT_FROM_DELIVERY: int = 4
## Nunca llega a correr más que la botarga (56): si corriera más, cada vuelta
## al puesto sería una vida y el nivel no se podría pasar.
const SUIT_SPEED_FIRST: float = 30.0
const SUIT_SPEED_LAST: float = 50.0
## Lo encima que tiene que estar para pillarla. Son 6 px contra los 22 que mide
## la botarga: tiene que estar **pisándola**, no rozándola, porque con los
## viajes cortos lo tiene al lado casi todo el rato.
const SUIT_CATCH: float = 6.0
## Lo que se queda quieto en el borde después de pillarla. Sin esto volvía
## derecho a por ella y, como al puesto hay que volver siempre, le quitaba las
## tres vidas en el mismo sitio: el parpadeo de un segundo no da para escapar
## si te tiene que pillar parada recogiendo un globo.
const SUIT_RECOVER: float = 2.5
## Y lo que sigue a salvo **justo después de aterrizar**. Sin esto, saltarle por
## encima no servía: la pillaba en el cuadro en que tocaba suelo al otro lado,
## que es exactamente cuando el salto ya había funcionado.
const LAND_GRACE: float = 0.3
## **En el aire no te toca.** Es la salida al problema de tenerlo de frente cada
## vez que vuelves al puesto: se le brinca por encima. Y la regla es esa, sin
## umbrales de altura: con cualquier margen en píxeles te pillaba en el despegue
## o en el aterrizaje, que es injugable porque no hay forma de adivinar el
## instante. Lo que mantiene la tensión es el otro lado: **debajo de un
## ventilador el globo revienta**, así que el salto hay que elegirlo.

# --- Nivel 3: la junta --------------------------------------------------------
## El suelo del pasillo y la puerta doble de la sala, al final del mundo.
const HALL_Y: float = 62.0
const START_X: float = 12.0
## Lo que va por delante el hombre de traje al empezar.
const SUIT_AHEAD: float = 34.0
const L3_DOOR: float = 772.0
## Parte A, seguir al traje: lo que camina él, lo que se para a mirar y el aviso
## de los ojos rojos antes de voltear.
const SUIT_WALK: float = 13.0
const SUIT_WATCH_TIME: Vector2 = Vector2(1.6, 2.4)
const SUIT_WALK_TIME: Vector2 = Vector2(2.4, 4.2)
const EYES_WARNING: float = 0.6
const EYES_COLOR: Color = Color(0.9, 0.12, 0.12)
## Te pilla si, volteando, te mueves a menos de esto.
const SEEN_RANGE: float = 40.0
## Si te quedas más de una pantalla atrás durante más de esto, lo pierdes.
const LOST_DISTANCE: float = 160.0
const LOST_PATIENCE: float = 3.0
const LOST_TEXT: String = "LO PERDISTE"
## Dónde hay dónde esconderse: macetas, columnas y marcos de puerta. Quedarse
## quieto detrás de una de estas es lo que te salva.
const L3_COVER: Array[Vector2] = [
	Vector2(92.0, 14.0), Vector2(186.0, 10.0), Vector2(268.0, 16.0),
	Vector2(352.0, 10.0), Vector2(438.0, 14.0), Vector2(524.0, 16.0),
	Vector2(602.0, 10.0), Vector2(690.0, 14.0),
]
const COVER_COLOR: Color = Color(0.26, 0.2, 0.22)
const COVER_TOP: Color = Color(0.34, 0.27, 0.28)
const COVER_HEIGHT: float = 22.0

## Parte B, la oscuridad: lo que se ve alrededor de Santi, la veladora del fondo
## y los huecos que solo se ven de cerca.
const DARK_RADIUS: float = 26.0
const DARK_SOFT: float = 10.0
const CANDLE_AT: Vector2 = Vector2(0.72, 0.42)
const L3_DARK_FROM: float = 520.0
const L3_DARK_HOLES: Array[Vector2] = [
	Vector2(566.0, 18.0), Vector2(620.0, 20.0), Vector2(680.0, 18.0),
	Vector2(730.0, 20.0),
]
## La botarga tirada en medio de la oscuridad, con su letrero.
const L3_SUIT_BODY: float = 648.0
const HELP_TEXT: String = "AYÚDANOS"
const HELP_COLOR: Color = Color(0.75, 0.1, 0.12)
const HELP_ON: float = 0.7
const HELP_OFF: float = 1.1

## Parte C, el escape: la puerta cerrándose, la pantalla roja, lo que dura la
## carrera y lo rápido que viene detrás.
const DOOR_TIME: float = 1.2
const RED_TIME: float = 1.0
const RED: Color = Color(0.55, 0.04, 0.05)
const ESCAPE_TIME: float = 20.0
const ESCAPE_SUIT_SPEED: float = 52.0
## La ventaja con la que arranca la persecución.
const ESCAPE_HEAD_START: float = 46.0
## Las sillas tiradas que hay que saltar, en coordenadas del mundo.
const L3_CHAIRS: Array[Vector2] = [
	Vector2(700.0, 12.0), Vector2(628.0, 14.0), Vector2(548.0, 12.0),
	Vector2(470.0, 14.0), Vector2(394.0, 12.0), Vector2(312.0, 14.0),
	Vector2(236.0, 12.0), Vector2(158.0, 14.0),
]
const CHAIR_HEIGHT: float = 10.0
const CHAIR_COLOR: Color = Color(0.3, 0.22, 0.18)
## Lo que sube el tono de la música en la parte C.
const ESCAPE_PITCH: float = 1.35

## El parpadeo de las luces del pasillo.
const FLICKER_MIN: float = 0.08
const FLICKER_MAX: float = 0.9

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
## El "GAME OVER" de cuando se acaban las vidas o el tiempo.
const OVER_TEXT: String = "GAME OVER"
const OVER_TIME: float = 1.8
const OVER_COLOR: Color = Color(0.85, 0.12, 0.12)

## El texto del HUD, en píxeles del lienzo. Lo dibuja `ArcadeFont`, que mide
## 3x5 por letra, así que el margen es la esquina de la primera.
const TEXT_MARGIN: Vector2 = Vector2(5.0, 5.0)
const TEXT_COLOR: Color = Color(0.95, 0.95, 0.9)
const WARNING_COLOR: Color = Color(0.9, 0.3, 0.2)
## Los corazones: dónde empieza la fila, lo que mide cada uno y su color.
const HEART_AT: Vector2 = Vector2(4.0, 4.0)
const HEART_STEP: float = 9.0
const HEART_COLOR: Color = Color(0.86, 0.18, 0.24)
const HEART_EMPTY: Color = Color(0.3, 0.14, 0.16)
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


## Lo ancho que es el mundo de un nivel, en píxeles del lienzo.
## Lo que dura un nivel antes de rendirse.
static func time_limit(level: int) -> float:
	return TIME_LIMITS[clampi(level, 1, LEVELS) - 1]


static func world_width(level: int) -> float:
	var screens: float = WORLD_SCREENS[clampi(level, 1, LEVELS) - 1]
	return float(SIZE.x) * screens


## Las mesas del nivel 1 en coordenadas del mundo: las tres de la foto,
## repetidas con cada copia del fondo.
static func tables(level: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var copies: int = ceili(world_width(level) / float(SIZE.x))
	for copy: int in copies:
		for table: Rect2 in TABLES:
			out.append(Rect2(table.position.x + float(copy * SIZE.x),
				table.position.y, table.size.x, table.size.y))
	return out

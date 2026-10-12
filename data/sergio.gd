class_name Sergio
extends RefCounted

## Sergio y el tótem. Todo lo que es número de diseño vive aquí: cuándo
## rescata, cuánto dura cada tramo de la animación y dónde va cada cosa.
##
## **Las medidas no se adivinan**: salen de los propios PNG de
## `assets/art/extras/sergio/`. La figura de Sergio ocupa 170x291 px tanto en
## `centro_sergio.png` (dentro de la capa de 1375x768) como en
## `sergio_silueta.png` (176x297, con 3 px de margen alrededor), así que la
## silueta baja a la misma escala y acaba justo encima de él.

const ART_PATH: String = "res://assets/art/extras/sergio/%s"
const LAYER: String = "centro_sergio"
const SILHOUETTE: String = "sergio_silueta"
const TOTEM: String = "totem_virgen"
const TOTEM_ICON: String = "totem_virgen_icono"

# --- Dónde está Sergio --------------------------------------------------------
## Su figura dentro de la capa de la vista central, normalizada.
const FIGURE: Rect2 = Rect2(0.3927, 0.3203, 0.1236, 0.3789)
## El margen transparente que trae la silueta alrededor de su figura, en
## fracción de su propia imagen. Sirve para que al colocarla la figura caiga
## donde toca y no la esquina del archivo.
const SILHOUETTE_MARGIN: Vector2 = Vector2(3.0 / 176.0, 3.0 / 297.0)
const SILHOUETTE_FIGURE: Vector2 = Vector2(170.0 / 176.0, 291.0 / 297.0)

# --- El rescate ---------------------------------------------------------------
## Desde qué noche puede rescatar sin tótem, y con qué probabilidad.
const RANDOM_FROM_NIGHT: int = 4
const RANDOM_CHANCE: int = 25
## Lo que se recupera de energía al usar el tótem.
const POWER_BACK: float = 10.0

## Los cuatro tramos: el susto congelado, la bajada de la silueta, el fundido a
## Sergio y lo que se queda él antes de irse.
const FREEZE_TIME: float = 3.0
const DESCENT_TIME: float = 1.5
const BLEND_TIME: float = 0.3
const STAY_TIME: float = 1.0
const FADE_OUT_TIME: float = 0.6

## El vaivén de la bajada: cuánto se mece de lado y cuántas veces.
const SWAY_PIXELS: float = 14.0
const SWAY_CYCLES: float = 1.5

## El haz de luz: lo ancho que es respecto a la figura y lo que tarda en abrir.
const BEAM_WIDTH: float = 2.1
const BEAM_FADE: float = 0.35
const BEAM_COLOR: Color = Color(1.0, 1.0, 0.96)
const BEAM_ALPHA: float = 0.5

# --- El tótem, al estilo de Minecraft ----------------------------------------
## A qué parte del alto de la pantalla llega, y los tiempos de cada paso.
const TOTEM_HEIGHT: float = 0.45
const TOTEM_FROM: float = 0.12
const TOTEM_GROW_TIME: float = 0.35
const TOTEM_SHAKE_TIME: float = 1.2
const TOTEM_SPIN_TIME: float = 0.9
const TOTEM_SHAKE_PIXELS: float = 5.0
## Cuántas vueltas da (la escala X va de 1 a −1 y de vuelta, dos veces).
const TOTEM_SPINS: int = 2
## Lo que sube al salir volando, en fracción del alto.
const TOTEM_RISE: float = 1.25

## Las partículas: cuántas, de qué colores y cómo se mueven.
const PARTICLES: int = 70
const PARTICLE_COLORS: Array[Color] = [
	Color(0.45, 0.85, 0.3), Color(0.68, 0.93, 0.35),
	Color(0.98, 0.88, 0.3), Color(0.95, 0.72, 0.2),
]
const PARTICLE_SIZE: float = 7.0
const PARTICLE_SPEED: float = 260.0
const PARTICLE_GRAVITY: float = 340.0
const PARTICLE_LIFE: float = 1.3

# --- El minijuego de la maquinita ---------------------------------------------
## Cada cuántas veces que se abre la PC aparece el ícono, y lo que se queda.
const ARCADE_ONE_IN: int = 15
const ARCADE_ICON_TIME: float = 1.0
## Lo que dura el minijuego y cuántas velitas hay que atrapar.
const GAME_TIME: float = 30.0
const GAME_TARGET: int = 10


static func texture(name: String) -> Texture2D:
	return GameAssets.load_texture(ART_PATH % name)


## El hueco donde cae la figura de Sergio, en píxeles de una capa de este
## tamaño. Es el mismo sitio en la silueta que baja y en la capa final.
static func figure_rect(layer_size: Vector2) -> Rect2:
	return Rect2(FIGURE.position * layer_size, FIGURE.size * layer_size)


## Dónde y de qué tamaño hay que dibujar `sergio_silueta.png` completa para que
## su figura caiga justo sobre la de la capa.
static func silhouette_rect(layer_size: Vector2) -> Rect2:
	var figure: Rect2 = figure_rect(layer_size)
	var full: Vector2 = Vector2(figure.size.x / SILHOUETTE_FIGURE.x,
		figure.size.y / SILHOUETTE_FIGURE.y)
	return Rect2(figure.position - SILHOUETTE_MARGIN * full, full)

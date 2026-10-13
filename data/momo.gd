class_name Momo
extends RefCounted

## El evento de Momo: el susto que no mata. Todo lo que es número de diseño
## vive aquí, para poder ajustarlo sin tocar la mecánica.
##
## Sale **al girar a la vista izquierda**, desde la noche 2 y como mucho una vez
## por noche. El juego se queda **completamente parado** mientras dura —reloj,
## profes, energía y controles— y al acabar sigue exactamente donde estaba: no
## cuesta energía, no mata y no mueve a nadie. Lo único que hace es asustar.

const ART_PATH: String = "res://assets/art/extras/momo/%s"
## La foto de la vista izquierda tomada por Momo. Es de 1375x768, igual que las
## de la oficina y con la misma composición, así que entra en el mismo sitio y
## se mueve con el mismo parallax.
const VIEW_IMAGE: String = "momo_izquierda"
## Y el screamer del final, de 842x1237.
const SCREAMER_IMAGE: String = "momo_screamer"

# --- Cuándo sale --------------------------------------------------------------
const FROM_NIGHT: int = 2
## Lo que hay de que salga cada vez que la cabeza llega a la vista izquierda.
const CHANCE: int = 6

# --- La entrada ---------------------------------------------------------------
## El parpadeo de luz: entre dos y tres cortes, de este largo cada uno. La foto
## se cambia en el último corte, con la pantalla en negro.
const FLICKER_CUTS: Vector2i = Vector2i(2, 3)
const FLICKER_CUT_TIME: float = 0.08

# --- Mientras suena la canción ------------------------------------------------
## El zoom lentísimo hacia Momo: de 1.0 a 1.06, centrado en su cara. El punto
## está en fracción de la vista, medido sobre `momo_izquierda.png`.
const ZOOM_FROM: float = 1.0
const ZOOM_TO: float = 1.06
const ZOOM_AT: Vector2 = Vector2(0.62, 0.45)

# --- El screamer --------------------------------------------------------------
## En qué segundo de la canción entra, y de qué alto a qué alto crece (en
## fracción del alto de la pantalla) y en cuánto tiempo.
const SCREAMER_AT: float = 12.10
const SCREAMER_FROM: float = 0.6
const SCREAMER_TO: float = 1.2
const SCREAMER_GROW_TIME: float = 0.3
## El temblor y el parpadeo mientras está en pantalla.
const SCREAMER_SHAKE_PIXELS: float = 34.0
const SCREAMER_SHAKE_HZ: float = 43.0
const SCREAMER_BLINK_HZ: float = 14.0
const SCREAMER_BLINK_DEPTH: float = 0.35
## Los píxeles del temblor se cuentan sobre una pantalla de este alto.
const REFERENCE_HEIGHT: float = 1080.0

# --- La salida ----------------------------------------------------------------
## El corte a negro antes de devolver la vista normal.
const BLACK_TIME: float = 0.3
## Lo que se le supone a la canción si el archivo no estuviera.
const FALLBACK_TIME: float = 15.3


static func texture(name: String) -> Texture2D:
	return GameAssets.load_texture(ART_PATH % name)

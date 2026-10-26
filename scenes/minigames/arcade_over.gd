class_name ArcadeOver
extends Node2D

## El "GAME OVER" de la maquinita: negro con el texto en la misma fuente de 3x5
## píxeles que todo lo de dentro del lienzo, en rojo y a tres veces su tamaño.
## Se queda un momento, se avisa y la pantalla se apaga como una tele.
##
## Sale cuando se acaban las vidas o el tiempo. **El nivel no avanza**: la
## próxima vez que salga la maquinita toca el mismo.

## Ya se leyó: que se apague.
signal ready_to_close()

const TEXT_SCALE: int = 3

var _left: float = Arcade.OVER_TIME
var _done: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	if _done:
		return
	_left -= delta
	if _left <= 0.0:
		_done = true
		ready_to_close.emit()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(Arcade.SIZE)), Color(0.0, 0.0, 0.0))
	var width: float = ArcadeFont.width(Arcade.OVER_TEXT, TEXT_SCALE)
	var at: Vector2 = Vector2(float(Arcade.SIZE.x) * 0.5 - width * 0.5,
		float(Arcade.SIZE.y) * 0.5 - float(ArcadeFont.GLYPH_HEIGHT * TEXT_SCALE) * 0.5)
	ArcadeFont.draw_text(self, at, Arcade.OVER_TEXT, Arcade.OVER_COLOR, TEXT_SCALE)

extends Control

## Barras de consumo estilo FNAF 1: una barra encendida por cada cosa que esté
## gastando energía. El color cambia conforme sube el consumo.

const MAX_LEVEL: int = 4
const BAR_SIZE: Vector2 = Vector2(22.0, 20.0)
const BAR_GAP: float = 5.0
const EMPTY_COLOR: Color = Color(0.13, 0.13, 0.15, 0.85)
const BORDER_COLOR: Color = Color(0.6, 0.62, 0.65, 0.8)
const LEVEL_COLORS: Array[Color] = [
	Color(0.25, 0.78, 0.33),  # 1 barra
	Color(0.62, 0.82, 0.22),  # 2 barras
	Color(0.93, 0.73, 0.16),  # 3 barras
	Color(0.87, 0.21, 0.16),  # 4 barras
]

var level: int = 1


func set_level(new_level: int) -> void:
	var clamped: int = clampi(new_level, 0, MAX_LEVEL)
	if clamped == level:
		return
	level = clamped
	queue_redraw()


func _draw() -> void:
	var fill: Color = LEVEL_COLORS[maxi(level - 1, 0)]
	for i: int in MAX_LEVEL:
		var rect: Rect2 = Rect2(Vector2(i * (BAR_SIZE.x + BAR_GAP), 0.0), BAR_SIZE)
		draw_rect(rect, fill if i < level else EMPTY_COLOR)
		draw_rect(rect, BORDER_COLOR, false, 1.0)

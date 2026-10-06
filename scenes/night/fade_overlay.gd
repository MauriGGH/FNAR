extends ColorRect

## Fundido a negro para las transiciones de un lugar a otro. A la mitad del
## fundido se hace el cambio, así que nunca se ve el salto.

signal midpoint_reached()

const HALF_TIME: float = 0.5


func _ready() -> void:
	visible = false
	color = Color(0.0, 0.0, 0.0, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Oscurece, avisa a la mitad para que se haga el cambio, y vuelve a aclarar.
func play() -> void:
	visible = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "color:a", 1.0, HALF_TIME)
	tween.tween_callback(midpoint_reached.emit)
	tween.tween_property(self, "color:a", 0.0, HALF_TIME)
	tween.tween_callback(func() -> void: visible = false)

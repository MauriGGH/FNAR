extends Control

## Foquito rojo que parpadea sobre el teléfono mientras está sonando.

const BLINK_TIME: float = 0.45
const LIGHT_COLOR: Color = Color(0.85, 0.22, 0.2)

var is_ringing: bool = false


func set_ringing(ringing: bool) -> void:
	is_ringing = ringing
	visible = ringing
	queue_redraw()


func _process(_delta: float) -> void:
	if is_ringing:
		queue_redraw()


func _draw() -> void:
	if not is_ringing:
		return
	var lit: bool = fmod(Time.get_ticks_msec() / 1000.0, BLINK_TIME * 2.0) < BLINK_TIME
	var radius: float = maxf(minf(size.x, size.y) * 0.22, 7.0)
	DrawKit.led(self, size * 0.5, radius, LIGHT_COLOR, 1.0 if lit else 0.12)

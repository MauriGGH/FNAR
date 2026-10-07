shader_type canvas_item;

// Líneas de escaneo suaves y un parpadeo leve, como un monitor viejo. Va encima
// de todo, así que solo oscurece: no aclara nada.

uniform float line_height : hint_range(1.0, 12.0) = 3.0;
uniform float line_darkness : hint_range(0.0, 1.0) = 0.16;
// Lo que respira el brillo y a qué velocidad.
uniform float flicker_amount : hint_range(0.0, 0.3) = 0.04;
uniform float flicker_speed : hint_range(0.0, 20.0) = 7.0;

void fragment() {
	float line = step(0.5, fract(SCREEN_UV.y / (line_height / 1080.0) * 0.5));
	float flicker = sin(TIME * flicker_speed) * 0.5 + 0.5;
	float darkness = line * line_darkness + flicker * flicker_amount;
	COLOR = vec4(0.0, 0.0, 0.0, darkness);
}

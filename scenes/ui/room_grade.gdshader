shader_type canvas_item;

// El mismo acabado que las cámaras y la oficina, para que las vistas de cerca
// se sientan del mismo juego: grano de película, viñeta y poca luz.
//
// Una sola capa hace las dos cosas: la opacidad suma el oscurecimiento y el
// grano, y el color se pesa con el grano. El resultado es que el grano pega
// más en las zonas oscuras, que es justo como se ve en película.

uniform float grain_strength : hint_range(0.0, 0.3) = 0.055;
uniform vec2 grain_cells = vec2(520.0, 300.0);
uniform float grain_fps = 16.0;

uniform float vignette_start : hint_range(0.0, 1.0) = 0.32;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.7;
/// Cuánta luz se le quita a todo, para que no se vea de día.
uniform float darken : hint_range(0.0, 1.0) = 0.14;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * grain_cells);
	float frame = floor(TIME * grain_fps);
	float grain = hash(cell + vec2(frame * 1.7, frame * 3.1)) * grain_strength;

	float edge = distance(UV, vec2(0.5)) * 1.4142;
	float dark = darken + smoothstep(vignette_start, 1.0, edge) * vignette_strength;
	dark = clamp(dark, 0.0, 1.0);

	float alpha = clamp(dark + grain, 0.0, 1.0);
	// El grano aporta luz; el resto de la opacidad es negro.
	vec3 color = vec3(grain / max(alpha, 0.001));
	COLOR = vec4(color, alpha);
}

shader_type canvas_item;

// Estática animada de la cámara. El script sube "strength" medio segundo
// al cambiar de cámara y lo deja caer otra vez al valor de reposo.

uniform float strength : hint_range(0.0, 1.0) = 0.07;
// Cuántas "celdas" de ruido a lo ancho y a lo alto: menos celdas, grano más gordo.
uniform vec2 noise_cells = vec2(384.0, 216.0);
// Fotogramas de ruido por segundo. Bajo a propósito, para que se vea analógico.
uniform float noise_fps = 20.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * noise_cells);
	float frame = floor(TIME * noise_fps);
	float grain = hash(cell + vec2(frame * 1.7, frame * 3.1));
	COLOR = vec4(vec3(grain), grain * strength);
}

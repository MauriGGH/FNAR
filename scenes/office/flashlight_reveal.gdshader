shader_type canvas_item;

// El cono de la linterna en la vista central. Se usa para tres cosas con los
// mismos dos mandos:
//
//   - La foto iluminada del pasillo: fuera del cono no se ve nada (base_alpha 0),
//     dentro se ve entera, y debajo queda la foto a oscuras.
//   - Los profes que solo existen con luz (Ureña, Juan.exe, Armando): igual.
//   - Los que se ven siempre (Mamador, Barcosa, el Mago): fuera se pintan
//     apagados (base_brightness 0.35) y dentro a todo brillo.
//
// El cono es un círculo con el borde suave. Se corrige por la proporción de la
// vista para que salga redondo y no ovalado.

// El centro del haz y su radio, en coordenadas normalizadas de la vista.
uniform vec2 beam_center = vec2(0.5, 0.5);
uniform float beam_radius : hint_range(0.0, 1.0) = 0.22;
// Lo ancho del degradado del borde.
uniform float beam_softness : hint_range(0.001, 0.5) = 0.12;
// 0 con la linterna apagada, 1 encendida. Se mueve suave al prender y apagar.
uniform float beam_strength : hint_range(0.0, 1.0) = 0.0;
// Proporción de la vista (ancho/alto), para que el círculo no se deforme.
uniform float aspect = 1.78;

// Cómo se ve lo de fuera del cono.
uniform float base_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float base_brightness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 offset = UV - beam_center;
	offset.x *= aspect;
	float distance = length(offset);
	float cone = smoothstep(beam_radius, beam_radius - beam_softness, distance);
	float inside = cone * beam_strength;

	vec4 source = texture(TEXTURE, UV);
	float alpha = mix(base_alpha, 1.0, inside);
	float brightness = mix(base_brightness, 1.0, inside);
	COLOR = vec4(source.rgb * brightness, source.a * alpha);
}

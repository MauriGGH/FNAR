shader_type canvas_item;

// El arte de un extra que todavía no se desbloquea: la misma imagen, muy
// oscurecida y desenfocada, para que se adivine la silueta y no el contenido.
// El desenfoque es un barrido de nueve muestras en cruz, suficiente a esta
// escala y mucho más barato que un gaussiano de verdad.

uniform float blur_radius : hint_range(0.0, 0.05) = 0.012;
uniform float darken : hint_range(0.0, 1.0) = 0.78;
// Lo que se le baja al color, para que quede casi en gris.
uniform float desaturation : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	vec4 total = vec4(0.0);
	float weight_sum = 0.0;
	for (int i = -2; i <= 2; i++) {
		for (int j = -2; j <= 2; j++) {
			vec2 offset = vec2(float(i), float(j)) * blur_radius * 0.5;
			float weight = 1.0 / (1.0 + length(vec2(float(i), float(j))));
			total += texture(TEXTURE, UV + offset) * weight;
			weight_sum += weight;
		}
	}
	vec4 blurred = total / weight_sum;
	float grey = dot(blurred.rgb, vec3(0.299, 0.587, 0.114));
	vec3 flat_color = mix(blurred.rgb, vec3(grey), desaturation);
	COLOR = vec4(flat_color * (1.0 - darken), blurred.a);
}

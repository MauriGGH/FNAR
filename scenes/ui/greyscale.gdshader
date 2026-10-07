shader_type canvas_item;

// Blanco y negro para la imagen de cámara del game over: la grabación se ve sin
// color, como una cinta de vigilancia.

uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float darken : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float grey = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 mixed = mix(source.rgb, vec3(grey), amount);
	COLOR = vec4(mixed * (1.0 - darken), source.a);
}

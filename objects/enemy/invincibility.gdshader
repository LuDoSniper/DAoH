shader_type spatial;

uniform sampler2D base_texture : source_color;
uniform float blink_speed : hint_range(0.0, 20.0) = 10.0;
uniform float blink_intensity : hint_range(0.0, 1.0) = 0.8;
uniform bool invincible = false;

void fragment() {
	vec4 base_color = texture(base_texture, UV);

	float blink = sin(TIME * blink_speed) * 0.5 + 0.5; // oscillation entre 0 et 1

	if (invincible) {
		// blink * blink_intensity varie en douceur : 0 → blink_intensity → 0
		vec3 flash_color = mix(base_color.rgb, vec3(1.0), blink * blink_intensity);
		ALBEDO = flash_color;
	} else {
		ALBEDO = base_color.rgb;
	}
}

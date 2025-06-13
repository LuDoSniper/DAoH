shader_type spatial;
render_mode unshaded, depth_draw_always, cull_disabled;

uniform vec3 center; // Position monde du centre de la zone
uniform float radius = 5.0;
uniform float border_thickness = 0.5;
uniform vec4 inner_color : source_color = vec4(0.0, 1.0, 0.0, 0.2);
uniform vec4 border_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float time = 0.0;

void fragment() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    float dist = distance(world_pos.xz, center.xz);
    if (dist > radius) {
        discard;
    }

    float border = smoothstep(radius - border_thickness, radius, dist);

    vec3 base = mix(inner_color.rgb, border_color.rgb, border);
    float emission_strength = 0.8 + 0.2 * sin(time * 4.0);

    ALBEDO = base;
    ALPHA = inner_color.a + border * (border_color.a - inner_color.a);
    EMISSION = base * emission_strength;
}

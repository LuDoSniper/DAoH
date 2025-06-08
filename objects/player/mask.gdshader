shader_type canvas_item;

uniform sampler2D mask;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec4 mask_color = texture(mask, UV);

    // Multiplie l'alpha du rendu par celui du masque
    color.a *= mask_color.a;

    if (color.a < 0.01) {
        discard;
    }

    COLOR = color;
}

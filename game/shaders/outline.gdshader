shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 sprite_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 10.0) = 1.0;

void fragment() {
	vec4 center_color = texture(TEXTURE, UV);

	// Only check for outline if center pixel is transparent
	if (center_color.a < 0.1) {
		vec2 texture_size = vec2(textureSize(TEXTURE, 0));
		vec2 pixel_size = 1.0 / texture_size;
		float outline_alpha = 0.0;

		for (float x = -outline_thickness; x <= outline_thickness; x += 1.0) {
			for (float y = -outline_thickness; y <= outline_thickness; y += 1.0) {
				if (x == 0.0 && y == 0.0) {
					continue;
				}

				vec2 offset = vec2(x, y) * pixel_size;
				vec4 sample_color = texture(TEXTURE, UV + offset);
				outline_alpha = max(outline_alpha, sample_color.a);
			}
		}

		if (outline_alpha > 0.1) {
			COLOR = outline_color;
		} else {
			COLOR = center_color;
		}
	} else {
		COLOR = center_color * sprite_tint;
	}
}
shader_type canvas_item;

// Textures for front and back of the coin
uniform sampler2D front_texture : source_color;
uniform sampler2D back_texture : source_color;

// Edge properties
uniform vec4 edge_color : source_color = vec4(0.8, 0.7, 0.3, 1.0);
uniform float max_outline_width : hint_range(0.0, 0.5) = 0.15;

// Rotation properties
uniform float rotation_speed : hint_range(-10.0, 10.0) = 2.0;
uniform float rotation_offset : hint_range(0.0, 6.28318) = 0.0;

void fragment() {
	float angle = mod(TIME * rotation_speed + rotation_offset, TAU);

	float cos_angle = cos(angle);
	float sin_angle = sin(angle);
	float abs_cos = abs(cos_angle);
	float abs_sin = abs(sin_angle);

	float outline_thickness = abs_sin * max_outline_width;

	bool outline_on_left = (cos_angle * sin_angle >= 0.0);

	vec4 final_color = vec4(0.0);

	if (abs_cos < 0.05) {
		// Compress UV
		vec2 uv = UV;
		uv.x = (uv.x - 0.5) / max(abs_cos, 0.001) + 0.5;

		// Sample appropriate texture
		vec4 tex_color;
		if (cos_angle > 0.0) {
			tex_color = texture(front_texture, uv);
		} else {
			vec2 flipped_uv = vec2(1.0 - uv.x, uv.y);
			tex_color = texture(back_texture, flipped_uv);
		}

		if (tex_color.a > 0.1) {
			final_color = edge_color;
			float dist_from_center = abs(UV.x - 0.5) / (max_outline_width * 0.5);
			final_color.rgb *= 1.0 - dist_from_center * 0.5;
		} else {
			discard;
		}
	} else {
		// Compress UV horizontally based on rotation
		vec2 uv = UV;
		uv.x = (uv.x - 0.5) / abs_cos + 0.5;

		// Sample the appropriate texture
		vec4 tex_color;
		if (cos_angle > 0.0) {
			// Front side
			tex_color = texture(front_texture, uv);
		} else {
			// Back side
			vec2 flipped_uv = vec2(1.0 - uv.x, uv.y);
			tex_color = texture(back_texture, flipped_uv);
		}

		// If current pixel is opaque, just render it
		if (tex_color.a > 0.1) {
			final_color = tex_color;

			// Add shading based on angle
			float shading = 0.3 + abs_cos * 0.7;
			final_color.rgb *= shading;
		} else {
			// Current pixel is transparent - draw outline
			// Sample in the opposite direction of where outline should appear
			float sample_direction = outline_on_left ? 1.0 : -1.0;

			bool found_edge = false;
			float max_samples = 10.0;
			float step_size = outline_thickness / max_samples;

			// Search for opaque pixels in the appropriate direction
			for (float i = 1.0; i <= max_samples; i += 1.0) {
				float sample_distance = i * step_size;

				vec2 sample_uv = UV;
				sample_uv.x += sample_direction * sample_distance;

				// Compress the sample UV
				vec2 compressed_sample_uv = sample_uv;
				compressed_sample_uv.x = (compressed_sample_uv.x - 0.5) / abs_cos + 0.5;

				// Sample the texture
				vec4 sample_color;
				if (cos_angle > 0.0) {
					sample_color = texture(front_texture, compressed_sample_uv);
				} else {
					vec2 flipped_sample_uv = vec2(1.0 - compressed_sample_uv.x, compressed_sample_uv.y);
					sample_color = texture(back_texture, flipped_sample_uv);
				}

				// Outline zone
				if (sample_color.a > 0.1) {
					found_edge = true;
					// Calculate outline gradient based on distance
					float distance_ratio = sample_distance / outline_thickness;
					final_color = edge_color;
					final_color.rgb *= 0.7 + (1.0 - distance_ratio) * 0.3;
					break;
				}
			}

			if (!found_edge) {
				discard; // Transparent pixel, not part of outline
			}
		}
	}

	COLOR = final_color;
}

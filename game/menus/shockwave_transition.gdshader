shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center_uv = vec2(0.5, 0.5);
uniform float edge_width : hint_range(0.01, 0.2) = 0.08;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.15;
uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0;
uniform float rotation_speed : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	vec2 uv = UV;

	// Calculate distance from center point
	vec2 delta = uv - center_uv;
	float dist = length(delta);

	// Calculate angle for rotational distortion patterns
	float angle = atan(delta.y, delta.x);

	// Expand the shockwave based on progress
	float shockwave_radius = progress * 1.5;

	// Calculate how far we are from the edge of the shockwave
	float edge_dist = dist - shockwave_radius;

	// Create distortion at the edge
	if (edge_dist > -edge_width && edge_dist < edge_width) {
		float edge_factor = edge_dist / edge_width;
		float radial_wave = sin(dist * 50.0 - progress * 20.0) * 0.5 + 0.5;
		float angular_wave = sin(angle * wave_frequency + progress * rotation_speed * 6.28318);
		float turbulence = sin(dist * 30.0 + angular_wave * 2.0) *
		                   cos(angle * wave_frequency * 0.5);
		float distortion = (angular_wave + radial_wave * 0.5 + turbulence * 0.3);
		float distortion_falloff = 1.0 - abs(edge_factor);
		distortion_falloff = pow(distortion_falloff, 2.0); // Sharper falloff
		vec2 distortion_offset = vec2(
			cos(angle + distortion * 2.0),
			sin(angle + distortion * 2.0)
		) * distortion_strength * distortion_falloff;

		uv += distortion_offset;
	}

	// Sample the texture with potentially distorted UVs
	vec4 color = texture(TEXTURE, uv);
	float dissolve = smoothstep(shockwave_radius - edge_width * 0.5,
	                            shockwave_radius + edge_width * 0.5,
	                            dist);

	// Add bright edge glow effect at the shockwave boundary
	float glow = 0.0;
	if (abs(edge_dist) < edge_width) {
		float glow_factor = 1.0 - abs(edge_dist) / edge_width;
		glow = pow(glow_factor, 3.0) * 0.6; // Bright glow at the edge
	}

	// Apply dissolve and glow
	color.rgb += vec3(glow * 1.5, glow * 1.2, glow);
	color.a *= dissolve;

	COLOR = color;
}

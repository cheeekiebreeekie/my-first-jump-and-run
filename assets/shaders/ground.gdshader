shader_type canvas_item;

// Width of the edge tapering area (0.1 = 10% of total width)
uniform float taper_width : hint_range(0.0, 0.5) = 0.1;
// Angle scale for the slope (1.0 = 45 degrees)
uniform float taper_slope : hint_range(0.1, 5.0) = 1.0;

void fragment() {
	vec4 target_color = vec4(50.0/255.0, 100.0/255.0, 25.0/255.0, 1.0);
	vec4 tex_color = COLOR;
	
	// Calculate horizontal distance from left and right boundaries (0.0 to 1.0)
	float dist_left = UV.x;
	float dist_right = 1.0 - UV.x;
	
	// Shift the effective top Y coordinate downwards near the edges (45-degree slant)
	float left_offset = max(0.0, (taper_width - dist_left) * taper_slope);
	float right_offset = max(0.0, (taper_width - dist_right) * taper_slope);
	
	// Offset UV.y so the green band curves/slants downward at 45 degrees near edges
	float adjusted_y = UV.y + left_offset + right_offset;

	// Your gradient calculation using the adjusted Y position
	float blend = pow(smoothstep(0.0, 1.0/3.0, adjusted_y), 0.75);
	tex_color.rgb = mix(target_color.rgb, tex_color.rgb, blend);

	COLOR = tex_color;
}
shader_type canvas_item;

// Target internal resolution
uniform vec2 target_resolution = vec2(480.0, 270.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

void fragment() {
	// Snap UV coordinates to a strict 320x180 grid
	vec2 grid_uv = floor(SCREEN_UV * target_resolution) / target_resolution;
	
	// Offset sample by half a pixel size to sample centers of pixel grid
	vec2 pixel_center = grid_uv + (vec2(0.5) / target_resolution);
	
	COLOR = texture(SCREEN_TEXTURE, pixel_center);
}
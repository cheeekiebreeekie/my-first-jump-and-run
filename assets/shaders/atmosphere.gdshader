shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
		vec4 tex_color = texture(TEXTURE, UV);
		tex_color.a *= pow(smoothstep(0.0, 0.5, UV.y), 0.75);
		COLOR = tex_color;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

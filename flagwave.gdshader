shader_type canvas_item;

uniform vec2 speed = vec2(0.5, 0.0);

void fragment() {
    vec2 moving_uv = UV + speed * TIME;
    COLOR = texture(TEXTURE, moving_uv);
}
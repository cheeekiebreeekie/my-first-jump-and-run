shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Grid dimensions (adjust to change block size)
uniform vec2 grid_size = vec2(32, 18);

// Calculates the inward spiral index for grid coordinate (gx, gy)
float get_spiral_index(int gx, int gy, int w, int h) {
    int left = 0;
    int right = w - 1;
    int top = 0;
    int bottom = h - 1;
    int index = 0;

    while (left <= right && top <= bottom) {
        // Top edge: Left to Right
        if (gy == top && gx >= left && gx <= right) {
            return float(index + (gx - left));
        }
        index += (right - left + 1);
        top++;

        // Right edge: Top to Bottom
        if (gx == right && gy >= top && gy <= bottom) {
            return float(index + (gy - top));
        }
        index += (bottom - top + 1);
        right--;

        // Bottom edge: Right to Left
        if (gy == bottom && gx >= left && gx <= right) {
            return float(index + (right - gx));
        }
        index += (right - left + 1);
        bottom--;

        // Left edge: Bottom to Top
        if (gx == left && gy >= top && gy <= bottom) {
            return float(index + (bottom - gy));
        }
        index += (bottom - top + 1);
        left++;
    }
    return float(index);
}

void fragment() {
    int w = int(grid_size.x);
    int h = int(grid_size.y);
    
    // Map UV coordinates (0.0 to 1.0) to grid coordinates
    int gx = clamp(int(UV.x * float(w)), 0, w - 1);
    int gy = clamp(int(UV.y * float(h)), 0, h - 1);
    
    float cell_index = get_spiral_index(gx, gy, w, h);
    float total_cells = float(w * h);
    
    float threshold = progress * total_cells;
    float mask = step(cell_index + 0.5, threshold);
    
    COLOR = vec4(vec3(0.0), mask);
}
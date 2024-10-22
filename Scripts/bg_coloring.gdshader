shader_type canvas_item;

uniform vec4 coloring;

void fragment() {
	COLOR.r = round(COLOR.r * 5.0) / 5.0;
	COLOR.g = round(COLOR.g * 5.0) / 5.0;
	COLOR.b = round(COLOR.b * 5.0) / 5.0;
	COLOR.rgb = COLOR.rgb * vec3(0.25, 0.25, 0.25) + vec3(0.75, 0.75, 0.75);
	COLOR = COLOR * coloring;
}

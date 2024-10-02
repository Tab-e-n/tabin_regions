shader_type canvas_item;
render_mode unshaded;

uniform bool changing_color = false;
uniform float n = 0;
uniform vec4 previous_color : source_color = vec4(1, 1, 1, 1);

void fragment() {
	if(changing_color)
	{
		vec2 uv = UV;
		if((uv.y * 1.5 - uv.x * 0.5 + 0.5) * 0.5 > n)
		{
			COLOR = texture(TEXTURE, UV) * previous_color;
		}
//		if((uv.x * 1.5 + uv.y * 0.5) * 0.5 > n)
//		{
//			COLOR = previous_color;
//		}
	}
}

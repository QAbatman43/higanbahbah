shader_type canvas_item;

uniform vec4 solid_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(solid_color.rgb, tex.a * solid_color.a);
}

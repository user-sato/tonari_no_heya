shader_type canvas_item;

// 32 levels per channel retains the original lighting and palette while gently
// breaking up banding. The threshold repeats in source viewport pixels.
void fragment() {
	ivec2 pixel = ivec2(floor(UV * vec2(textureSize(TEXTURE, 0))));
	int bayer[16] = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5};
	int index = (pixel.y % 4) * 4 + (pixel.x % 4);
	float threshold = (float(bayer[index]) + 0.5) / 16.0;
	vec4 source = texture(TEXTURE, UV);
	// A fixed monochrome grain, much weaker than one quantization step.
	float grain = fract(sin(dot(vec2(pixel), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	vec3 quantized = floor(source.rgb * 31.0 + threshold) / 31.0;
	COLOR = vec4(clamp(quantized + grain / 127.5, 0.0, 1.0), source.a);
}

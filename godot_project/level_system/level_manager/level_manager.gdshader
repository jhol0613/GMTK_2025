shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

//Brightness, contrast, saturation
uniform vec3 bcs = vec3(1.0, 1.0, 1.0);
//Amount of vignette texture to apply
uniform float vignette = 1.0;
//Range from -1 to 1. If 1, just displays full vignette. -1 displays no vignette.
//0 applies linear gradient from 0 to 1 going down the screen
uniform float wipe = -1.0;

uniform sampler2D vignette_texture : repeat_disable, filter_linear;

void fragment() {
    vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec4 mask = texture(vignette_texture, SCREEN_UV);

    c.rgb = mix(vec3(0.0), c.rgb, bcs.r);
    c.rgb = mix(vec3(0.5), c.rgb, bcs.g);
    c.rgb = mix(vec3(dot(vec3(1.0), c.rgb) * 0.33333), c.rgb, bcs.b);

	// interpolate between 0 and wipe. Anything above is clamped to 1
	float wipe_modifier = clamp(mix(0.0, 1.0, SCREEN_UV.g + wipe), 0.0, 1.0);

	//COLOR = vec4(0.0, 1.0, 0.0, clamp(mix(0.0, 1.0, SCREEN_UV.g + wipe), 0.0, 1.0));

	c.rgb = mix(c.rgb, mask.rgb, mask.a * vignette * wipe_modifier);

    COLOR.rgb = c;

}
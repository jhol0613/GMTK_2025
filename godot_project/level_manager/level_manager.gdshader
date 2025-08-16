shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

//Brightness, contrast, saturation
uniform vec3 bcs = vec3(1.0, 1.0, 1.0);
//Amount of vignette texture to apply
uniform float vignette = 0.0;

uniform sampler2D vignette_texture : repeat_disable, filter_linear;

void fragment() {
    vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec4 mask = texture(vignette_texture, SCREEN_UV);

    c.rgb = mix(vec3(0.0), c.rgb, bcs.r);
    c.rgb = mix(vec3(0.5), c.rgb, bcs.g);
    c.rgb = mix(vec3(dot(vec3(1.0), c.rgb) * 0.33333), c.rgb, bcs.b);
	
	c.rgb = mix(c.rgb, mask.rgb, mask.a*vignette);

    COLOR.rgb = c;
}
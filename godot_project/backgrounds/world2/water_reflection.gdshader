shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 tint_color : source_color;

uniform sampler2D fast_noise : repeat_enable;

uniform vec2 wave_speed = vec2(0.03, 0.07);

uniform vec2 wave_strength = vec2(2, 2);

uniform float scale_y;
uniform float y_zoom;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//get ripple noise
	vec2 uv = UV * wave_speed * TIME;
	
	//get the noise from fast noise
	vec2 noise = texture(fast_noise, uv).rg;
	
	//get size of object shader is on
	float uv_height = (SCREEN_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.y);
	
	//calculate where reflection is coming from
	vec2 reflected_uv = vec2(SCREEN_UV.x, SCREEN_UV.y - (uv_height * UV.y * scale_y * y_zoom));
	
	//get reflection pixel
	vec4 reflection = texture(screen_texture, reflected_uv);
	
	//calculate waves for ripples
	vec4 waves = texture(screen_texture, reflected_uv + noise * y_zoom * (wave_strength / 100.0));
	
	COLOR = mix(waves, tint_color, 0.5);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

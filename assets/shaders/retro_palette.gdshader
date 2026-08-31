shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert_wrap, specular_disabled;

// --- Uniforms ---
group_uniforms PaletteSettings;
uniform sampler2D palette_texture : filter_nearest, source_color;
uniform int palette_index = 0;
uniform int total_palettes = 16;
uniform int colors_per_row = 16;

group_uniforms RetroFX;
uniform bool enable_ps1_jitter = false;
uniform float jitter_resolution = 160.0;
uniform bool enable_color_quantization = true;
uniform float color_depth : hint_range(4.0, 32.0, 1.0) = 16.0;

group_uniforms Texture;
uniform sampler2D albedo_index_map : filter_nearest, hint_default_white;
uniform vec4 tint_color : source_color = vec4(1.0);

varying vec3 v_vertex_pos;

void vertex() {
	v_vertex_pos = VERTEX;

	if (enable_ps1_jitter) {
		vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
		vec3 ndc = clip_pos.xyz / clip_pos.w;
		ndc.xy = floor(ndc.xy * jitter_resolution) / jitter_resolution;
		clip_pos.xyz = ndc * clip_pos.w;
		POSITION = clip_pos;
	}
}

void fragment() {
	vec2 base_uv = UV;
	
	// パレットテクスチャからサンプリング
	float u = (floor(base_uv.x * float(colors_per_row - 1)) + 0.5) / float(colors_per_row);
	float v = (float(palette_index % total_palettes) + 0.5) / float(total_palettes);
	
	vec4 palette_sample = texture(palette_texture, vec2(u, v));
	
	// パレットサンプルとtint_colorの合成
	vec3 base_rgb = palette_sample.rgb;
	if (length(base_rgb) < 0.05) {
		base_rgb = tint_color.rgb; // パレットが未設定時のフォールバック
	}
	
	vec3 final_color = base_rgb * tint_color.rgb;
	if (enable_color_quantization) {
		final_color = floor(final_color * color_depth) / color_depth;
	}
	
	ALBEDO = final_color;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
}

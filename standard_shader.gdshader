// NOTE: Shader automatically converted from Godot Engine 4.7.1.stable's StandardMaterial3D.
#define DIFFUSE_BURLEY
#define SPECULAR_SCHLICK_GGX

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;

uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D roughness_texture : hint_roughness_r, filter_nearest, repeat_enable;

uniform sampler2D normal_texture : hint_normal, filter_nearest, repeat_enable;
uniform float normal_intensity : hint_range(-16.0, 16.0) = 1.0;

uniform bool invert_green = false;
uniform bool specular_hack = true;

uniform sampler2D alpha_texture : filter_nearest, hint_default_white;

/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */

float D_GGX(float cos_theta_m, float i_alpha) {
	float a = cos_theta_m * i_alpha;
	float k = i_alpha / (1.0 - cos_theta_m * cos_theta_m + a * a);
	return k * k * (1.0 / PI);
}

float V_GGX(float NdotL, float NdotV, float i_alpha) {
	return 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, i_alpha);
}

float SchlickFresnel(float u) {
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}

vec3 F0(float i_metallic, float i_specular, vec3 i_albedo) {
	float dielectric = 0.16 * i_specular * i_specular;
	return mix(vec3(dielectric), i_albedo, vec3(i_metallic));
}

void light_compute(vec3 i_N, vec3 i_L, vec3 i_V, vec3 i_light_color, float i_attenuation, float i_specular, float i_roughness, float i_metallic, float i_specular_amount, vec3 i_albedo, inout vec3 o_diffuse_light, inout vec3 o_specular_light) {
	if(specular_hack) {
		i_V = vec3(0.0, 0.0, 1.0);
	}
	
	vec3 f0 = F0(i_metallic, i_specular, i_albedo);
	float NdotL = min(dot(i_N, i_L), 1.0);
	float cNdotL = max(NdotL, 0.0);
	float NdotV = dot(i_N, i_V);
	float cNdotV = max(NdotV, 1e-4);

	#if defined(DIFFUSE_BURLEY) || defined(SPECULAR_SCHLICK_GGX)
		vec3 H = normalize(i_V + i_L);
		float cLdotH = clamp(dot(i_L, H), 0.0, 1.0);
	#endif

	#if defined(SPECULAR_SCHLICK_GGX)
		float cNdotH = clamp(dot(i_N, H), 0.0, 1.0);
	#endif

	if (i_metallic < 1.0) {
		float diffuse_brdf_NL = 0.0;

		#if defined(DIFFUSE_BURLEY)
			float FD90_minus_1 = 2.0 * cLdotH * cLdotH * i_roughness - 0.5;
			float FdV = 1.0 + FD90_minus_1 * SchlickFresnel(cNdotV);
			float FdL = 1.0 + FD90_minus_1 * SchlickFresnel(cNdotL);
			diffuse_brdf_NL = (1.0 / PI) * FdV * FdL * cNdotL;
		#elif defined(DIFFUSE_LAMBERT)
			diffuse_brdf_NL = cNdotL * (1.0 / PI);
		#elif defined(DIFFUSE_LAMBERT_WRAP)
			diffuse_brdf_NL = max(0.0, (NdotL + i_roughness) / ((1.0 + i_roughness) * (1.0 + i_roughness))) * (1.0 / PI);
		#elif defined(DIFFUSE_TOON)
			diffuse_brdf_NL = smoothstep(-i_roughness, max(i_roughness, 0.01), NdotL) * (1.0 / PI);
		#endif

		o_diffuse_light += i_light_color * diffuse_brdf_NL;
	}

	if (i_roughness > 0.0) {
		vec3 specular_brdf_NL = vec3(0.0);

		#if defined(SPECULAR_SCHLICK_GGX)
			float alpha_ggx = i_roughness * i_roughness;
			float D = D_GGX(cNdotH, alpha_ggx);
			float G = V_GGX(cNdotL, cNdotV, alpha_ggx);
			float cLdotH5 = SchlickFresnel(cLdotH);
			float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
			vec3 F = f0 + (f90 - f0) * cLdotH5;
			specular_brdf_NL = cNdotL * D * F * G;
		#elif defined(SPECULAR_TOON)
			vec3 R = normalize(-reflect(i_L, i_N));
			float RdotV = dot(R, i_V);
			float mid = 1.0 - i_roughness;
			mid *= mid;
			float intensity = smoothstep(mid - i_roughness * 0.5, mid + i_roughness * 0.5, RdotV) * mid;
			specular_brdf_NL = i_albedo * intensity;
		#elif defined(SPECULAR_DISABLED)
			// none
		#endif

		o_specular_light += specular_brdf_NL * i_light_color * i_attenuation * i_specular_amount;
	}
}

#define STANDARD_LIGHTING(output_diffuse, output_specular) light_compute(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, 0.5, ROUGHNESS, METALLIC, SPECULAR_AMOUNT, ALBEDO, output_diffuse, output_specular)

void fragment() {
	vec2 base_uv = UV;
	
	vec4 albedo_tex = texture(albedo_texture, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(roughness_texture, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	
	// Normal Map: Enabled
	vec4 normal_map =  texture(normal_texture, base_uv);
	if(invert_green) { normal_map.g = (1.0-normal_map.g); }
	NORMAL_MAP = normal_map.rgb;
	NORMAL_MAP_DEPTH = normal_intensity;
	
	ALPHA = albedo_tex.a * texture(alpha_texture, base_uv).r;
}

void light() {
	STANDARD_LIGHTING(DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
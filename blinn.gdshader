//TODO
// for some reason blinn is brighter than pbr with no specular

shader_type spatial;
render_mode depth_prepass_alpha;

uniform sampler2D albedo_texture : filter_nearest,repeat_enable, source_color, hint_default_transparent;
uniform sampler2D normal_texture : filter_nearest,repeat_enable, hint_normal;
uniform float normal_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float specular : hint_range(0.0, 4.0) = 0.2;
uniform float shininess : hint_range(0.0, 30.0) = 10.0;
uniform vec3 specular_color : source_color = vec3(1);

uniform sampler2D alpha_texture : filter_nearest, hint_default_white;

uniform bool invert_green = false;
uniform bool specular_hack = true;

uniform float roughness : hint_range(0.0, 1.0) = 0.5; // just here for compatibility

void fragment() {
	vec3 normal = mix(vec3(0.5, 0.5, 1.0), texture(normal_texture, UV).rgb, vec3(normal_intensity, normal_intensity, normal_intensity));
	
	//NORMAL_MAP = texture(normal_texture, UV).rgb;
	if(invert_green) { normal.g = (1.0-normal.g); }
	NORMAL_MAP = normal;
	
	ALPHA = texture(albedo_texture, UV).a * texture(alpha_texture, UV).r;
}

void light() {
	vec3 L = normalize(LIGHT);
	vec3 N = normalize(NORMAL);

	float NdotL = dot(N, L);
	vec4 albedo_tex = texture(albedo_texture, UV);
	
	vec3 final_diffuse = albedo_tex.rgb * NdotL;
	
	vec3 V = normalize(VIEW);
	if(specular_hack) {
		V = vec3(0.0, 0.0, 1.0);
	}
	vec3 H = normalize(L + V);

	float specular_power = max(pow(dot(H, NORMAL), shininess), 0.0) * (SPECULAR_AMOUNT / 4.0);
	vec3 final_specular = ( (vec3(specular_power)*specular_color)*(LIGHT_COLOR/vec3(3.0)) ) * max(1.-pow(1.-NdotL, 20), 0.0);

	SPECULAR_LIGHT = final_specular + SPECULAR_LIGHT * LIGHT_COLOR;
	DIFFUSE_LIGHT += LIGHT_COLOR * final_diffuse;
}
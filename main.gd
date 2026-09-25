extends Control

@onready var blinn_shader : Shader = preload("res://blinn.gdshader")
@onready var pbr_shader : Shader = preload("res://standard_shader.gdshader")

enum Type{ALBEDO, NORMAL, ROUGHNESS, ALPHA, CFG, OUT}
var file_type : Type = Type.ALBEDO

var albedo_suffixes : Array[String] = ["albedo", "a", "alb", "color", "diff"] # saw "diff" on a texture form polyhaven
var normal_suffixes : Array[String] = ["normal", "n", "norm"]
var roughness_suffixes : Array[String] = ["roughness", "r", "rough"]
var alpha_suffixes : Array[String] = ["alpha", "a", "opacity", "o"]

# the textures
var albedo_texture : ImageTexture:
	set(value):
		albedo_texture = value
		%SubViewport.material.set_shader_parameter("albedo_texture", value)
	get():
		return %SubViewport.material.get_shader_parameter("albedo_texture")
var normal_texture : ImageTexture:
	set(value):
		normal_texture = value
		%SubViewport.material.set_shader_parameter("normal_texture", value)
	get():
		return %SubViewport.material.get_shader_parameter("normal_texture")
var roughness_texture : ImageTexture:
	set(value):
		roughness_texture = value
		%SubViewport.material.set_shader_parameter("roughness_texture", value)
	get():
		return %SubViewport.material.get_shader_parameter("roughness_texture")
var alpha_texture : ImageTexture:
	set(value):
		alpha_texture = value
		%SubViewport.material.set_shader_parameter("alpha_texture", value)
	get():
		return %SubViewport.material.get_shader_parameter("alpha_texture")

var tmp_albedo : ImageTexture
var tmp_normal : ImageTexture
var tmp_roughness : ImageTexture
var tmp_alpha : ImageTexture

enum Shading{BLINN, PBR}

var file_dialog_img_filter : String = "*.png,*.jpg,*.jpeg; Image Files;image/png,image/jpeg"
var file_dialog_cfg_filter : String = "*.cfg"

var config_file : ConfigFile

# shader parameters as variables for easy access hee hoo
var shader : Shader:
	set(value):
		%SubViewport.material.set_shader(value)
	get():
		return %SubViewport.material.get_shader()
var normal_intensity : float:
	set(value):
		%SubViewport.material.set_shader_parameter("normal_intensity", value)
	get():
		return %SubViewport.material.get_shader_parameter("normal_intensity")
var shininess : float:
	set(value):
		%SubViewport.material.set_shader_parameter("shininess", value)
	get():
		return %SubViewport.material.get_shader_parameter("shininess")
var roughness : float:
	set(value):
		%SubViewport.material.set_shader_parameter("roughness", value)
	get():
		return %SubViewport.material.get_shader_parameter("roughness")
var specular_color : Color:
	set(value):
		%SubViewport.material.set_shader_parameter("specular_color", value)
	get():
		return %SubViewport.material.get_shader_parameter("specular_color")
var invert_green : bool:
	set(value):
		%SubViewport.material.set_shader_parameter("invert_green", value)
	get():
		return %SubViewport.material.get_shader_parameter("invert_green")
var specular_hack : bool:
	set(value):
		%SubViewport.material.set_shader_parameter("specular_hack", value)
	get():
		return %SubViewport.material.get_shader_parameter("specular_hack")

# light parameters for easy access too
var light_rotation_y : float:
	set(value):
		%PreviewLight.rotation_degrees.y = value
		%DirectionalLight3D.rotation_degrees.y = value
	get():
		return %DirectionalLight3D.rotation_degrees.y
var light_rotation_x : float:
	set(value):
		%PreviewLight.rotation_degrees.x = -value
		%DirectionalLight3D.rotation_degrees.x = -value
	get():
		return %DirectionalLight3D.rotation_degrees.x
var light_specular : float:
	set(value):
		%PreviewLight.light_specular = value
		%DirectionalLight3D.light_specular = value
	get():
		return %DirectionalLight3D.light_specular
var light_color : Color:
	set(value):
		%PreviewLight.light_color = value
		%DirectionalLight3D.light_color = value
	get():
		return %DirectionalLight3D.light_color

func _ready() -> void:
	config_file = ConfigFile.new()
	
	shader = blinn_shader
	
	normal_intensity = %NormalSlider.value
	shininess = %ShininessSlider.value
	specular_color =  %SpecColorPickerButton.color
	
	light_rotation_y = %LightHSlider.value
	light_rotation_x = %LightVSlider.value
	
	get_window().files_dropped.connect(_on_files_dropped)

# sliders and other parameters
func _on_zoom_slider_value_changed(value: float) -> void:
	%DisplayTexture.offset_transform_scale.x = value
	%DisplayTexture.offset_transform_scale.y = value
	%ZoomLevel.text = str(value)

func _on_ambient_color_picker_button_color_changed(color: Color) -> void:
	%WorldEnvironment.environment.ambient_light_color = color
	%PreviewWorldEnvironment.environment.ambient_light_color = color

func _on_light_h_slider_value_changed(value: float) -> void:
	light_rotation_y = value
func _on_light_v_slider_value_changed(value: float) -> void:
	light_rotation_x = value
func _on_light_color_picker_color_changed(color: Color) -> void:
	light_color = color
func _on_spec_slider_value_changed(value: float) -> void:
	light_specular = value
func _on_rough_slider_value_changed(value: float) -> void:
	roughness = value
func _on_normal_slider_value_changed(value: float) -> void:
	normal_intensity = value
func _on_shininess_slider_value_changed(value: float) -> void:
	shininess = value
func _on_color_picker_button_color_changed(color: Color) -> void:
	specular_color = color
func _on_invert_green_check_box_toggled(toggled_on: bool) -> void:
	invert_green = toggled_on
func _on_spec_hack_check_box_toggled(toggled_on: bool) -> void:
	specular_hack = toggled_on

func _on_blinn_pbr_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%PBRLabel.modulate = Color.WHITE
		%BlinnLabel.modulate = Color.DIM_GRAY
		%PBRSettings.show()
		%BlinnSettings.hide()
		roughness = %RoughSlider.value
		shader = pbr_shader
	else:
		%PBRLabel.modulate = Color.DIM_GRAY
		%PBRSettings.hide()
		%BlinnSettings.show()
		%BlinnLabel.modulate = Color.WHITE
		%SubViewport.material.set_shader(blinn_shader)
		shader = blinn_shader

# buttons
func _on_albedo_button_pressed() -> void:
	_set_file_dialog_image_open()
	file_type = Type.ALBEDO
func _on_normal_button_pressed() -> void:
	_set_file_dialog_image_open()
	file_type = Type.NORMAL
func _on_rough_button_pressed() -> void:
	_set_file_dialog_image_open()
	file_type = Type.ROUGHNESS
func _on_alpha_button_pressed() -> void:
	_set_file_dialog_image_open()
	file_type = Type.ALPHA
func _on_clear_rough_button_pressed() -> void:
	roughness_texture = null

# loading and saving files
func _set_file_dialog_image_open() -> void:
	%FileDialog.clear_filters()
	%FileDialog.add_filter(file_dialog_img_filter)
	%FileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	%FileDialog.popup_centered()
func _on_export_button_pressed() -> void:
	%FileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	%FileDialog.clear_filters()
	%FileDialog.add_filter(file_dialog_img_filter)
	%FileDialog.set_current_file("out.png")
	%FileDialog.popup_centered()
	file_type = Type.OUT
func _on_save_button_pressed() -> void:
	%FileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	%FileDialog.clear_filters()
	%FileDialog.add_filter(file_dialog_cfg_filter)
	%FileDialog.set_current_file("config.cfg")
	%FileDialog.popup_centered()
	file_type = Type.CFG
func _on_load_button_pressed() -> void:
	%FileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	%FileDialog.clear_filters()
	%FileDialog.add_filter(file_dialog_cfg_filter)
	%FileDialog.popup_centered()
	file_type = Type.CFG

func _on_file_dialog_file_selected(path: String) -> void:
	if %FileDialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		if file_type == Type.OUT:
			var viewport_texture : ViewportTexture = %SubViewport.get_texture()
			var out_image : Image = viewport_texture.get_image()
	
			out_image.save_png(path)
			print("exported " + path)
		elif file_type == Type.CFG:
			_save_values()
			var err = config_file.save(path)
			if err != OK:
				push_error("Couldn't save config file. Error "+str(err))
		return
	
	if file_type == Type.CFG:
		var err = config_file.load(path)
		if err != OK:
			push_error("Not a valid config file. Error "+str(err))
			return
		else:
			_load_values()
			return
	
	var tmp_img : Image = Image.load_from_file(path)
	if tmp_img == null:
		push_error("Not a recognized image!")
	
	match(file_type):
		Type.ALBEDO:
			albedo_texture = ImageTexture.create_from_image(tmp_img)
			_check_for_other_maps(path)
			%SubViewport.setup()
		Type.NORMAL:
			normal_texture = ImageTexture.create_from_image(tmp_img)
			_check_for_other_maps(path)
		Type.ROUGHNESS:
			roughness_texture = ImageTexture.create_from_image(tmp_img)
			_check_for_other_maps(path)
		Type.ALPHA:
			alpha_texture = ImageTexture.create_from_image(tmp_img)
			_check_for_other_maps(path)

func _on_popup_yes_pressed() -> void:
	albedo_texture = tmp_albedo
	normal_texture = tmp_normal
	roughness_texture = tmp_roughness
	alpha_texture = tmp_alpha
	%PopupPanel.hide()

func _on_popup_no_pressed() -> void:
	%PopupPanel.hide()

func _on_files_dropped(files : PackedStringArray) -> void:
	for file in files:
		var path_split : PackedStringArray = file.get_basename().rsplit("_", true, 1)
		if path_split[1] in albedo_suffixes:
			albedo_texture = ImageTexture.create_from_image(Image.load_from_file(file))
		elif path_split[1] in normal_suffixes:
			normal_texture = ImageTexture.create_from_image(Image.load_from_file(file))
		elif path_split[1] in roughness_suffixes:
			roughness_texture = ImageTexture.create_from_image(Image.load_from_file(file))
		elif path_split[1] in alpha_suffixes:
			alpha_texture = ImageTexture.create_from_image(Image.load_from_file(file))
	
	if albedo_texture != null:
		%SubViewport.setup()

func _check_for_other_maps(path : String) -> void:
	tmp_albedo = find_suffix(path, albedo_suffixes)
	tmp_normal = find_suffix(path, normal_suffixes)
	tmp_roughness = find_suffix(path, roughness_suffixes)
	tmp_alpha = find_suffix(path, alpha_suffixes)
	if (tmp_normal != null) or (tmp_roughness != null) or (tmp_alpha != null):
		%PopupPanel.popup_centered(Vector2i(300,117))

func find_suffix(path : String, suffix_list : Array[String]) -> ImageTexture:
	var path_split : PackedStringArray = path.get_basename().rsplit("_", true, 1)
	var base_path : String = path_split[0]
	var possible_path : String
	for suffix in suffix_list:
		possible_path = base_path + "_" + suffix + "." + path.get_extension()
		if FileAccess.file_exists(possible_path):
			return ImageTexture.create_from_image(Image.load_from_file(possible_path))
	return null

func _load_values() -> void:
	var shader_type : String = config_file.get_value("Shader", "shader", "")
	match(shader_type):
		"Blinn":
			shader = blinn_shader
			%BlinnPBRButton.button_pressed = false
		"PBR":
			shader = pbr_shader
			%BlinnPBRButton.button_pressed = true
	
	if config_file.get_value("Lighting", "light_rotation_x") != null:
		%LightVSlider.value = -clamp(config_file.get_value("Lighting", "light_rotation_x"), -180.0, 180.0)
	if config_file.get_value("Lighting", "light_rotation_y") != null:
		%LightHSlider.value = clamp(config_file.get_value("Lighting", "light_rotation_y"), -180.0, 180.0)
	if config_file.get_value("Lighting", "light_specular") != null:
		%SpecSlider.value = clamp(config_file.get_value("Lighting", "light_specular"), 0.0, 16.0)
	if config_file.get_value("Lighting", "light_color") != null:
		%LightColorPicker.color = config_file.get_value("Lighting", "light_color")
	
	if config_file.get_value("Shader", "normal_intensity") != null:
		%NormalSlider.value = clamp(config_file.get_value("Shader", "normal_intensity"), 0.0, 1.0)
	if config_file.get_value("Shader", "shininess") != null:
		%ShininessSlider.value = clamp(config_file.get_value("Shader", "shininess"), 0.0, 30.0)
	if config_file.get_value("Shader", "roughness") != null:
		%RoughSlider.value = clamp(config_file.get_value("Shader", "roughness"), 0.0, 1.0)
	if config_file.get_value("Shader", "specular_color") != null:
		%SpecColorPickerButton.color = config_file.get_value("Shader", "specular_color")
		specular_color = %SpecColorPickerButton.color
	if config_file.get_value("Shader", "invert_green") != null:
		%InvertGreenCheckBox.button_pressed = config_file.get_value("Shader", "invert_green")
		invert_green = %InvertGreenCheckBox.button_pressed
	if config_file.get_value("Shader", "specular_hack") != null:
		%SpecHackCheckBox.button_pressed = config_file.get_value("Shader", "specular_hack")
		specular_hack = %SpecHackCheckBox.button_pressed
	
func _save_values() -> void:
	config_file.set_value("Lighting", "light_rotation_x", light_rotation_x)
	config_file.set_value("Lighting", "light_rotation_y", light_rotation_y)
	config_file.set_value("Lighting", "light_specular", light_specular)
	config_file.set_value("Lighting", "light_color", light_color)
	
	var shader_type : String = ""
	if shader == blinn_shader:
		shader_type = "Blinn"
	elif shader == pbr_shader:
		shader_type = "PBR"
	config_file.set_value("Shader", "shader", shader_type)
	config_file.set_value("Shader", "normal_intensity", normal_intensity)
	config_file.set_value("Shader", "shininess", shininess)
	config_file.set_value("Shader", "roughness", roughness)
	config_file.set_value("Shader", "specular_color", specular_color)
	config_file.set_value("Shader", "invert_green", invert_green)
	config_file.set_value("Shader", "specular_hack", specular_hack)

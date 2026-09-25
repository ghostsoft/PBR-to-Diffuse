@tool
extends SubViewport


@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Setup") var _butt_setup : Callable = setup
@export_tool_button("Bake") var _butt_bake : Callable = _bake
@warning_ignore_restore("unused_private_class_variable")

@onready var mesh_instance : MeshInstance3D = $MeshInstance3D
@onready var mesh : QuadMesh = mesh_instance.mesh
@onready var camera : Camera3D = $Camera3D
#@onready var material : StandardMaterial3D = mesh_instance.get_active_material(0)
@export var material : ShaderMaterial = preload("res://material.tres")

func setup() -> void:
	if material == null:
		push_error("No material assigned.")
		return
	
	var albedo_texture = material.get_shader_parameter("albedo_texture")
	if albedo_texture ==  null:
		push_error("No albedo texture assigned.")
		return
	
	var texture_size : Vector2 = albedo_texture.get_size()
	
	self.size = texture_size
	if texture_size.x > texture_size.y:
		# wide
		camera.size = texture_size.x / texture_size.y
		mesh.size = Vector2(texture_size.x / texture_size.y, 1.0)
	elif texture_size.y > texture_size.x:
		# tall
		camera.size = texture_size.y / texture_size.x
		mesh.size = Vector2(1.0, texture_size.y / texture_size.x)
	else:
		# square
		camera.size = 1.0
		mesh.size = Vector2(1.0, 1.0)
	
	mesh_instance.set_surface_override_material(0, material)
	
	await get_tree().process_frame

func _bake() -> void:
	var texture : ViewportTexture = self.get_texture()
	var out_image : Image = texture.get_image()
	
	out_image.save_png("res://out/out.png")
	
	print_debug("yay haha")

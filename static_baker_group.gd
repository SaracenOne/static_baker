extends Spatial
tool

const mesh_combiner_const = preload("res://addons/mesh_combiner/mesh_combiner.gd")
export(Array) var original_instances = []

func restore_backup(p_editor_interface):
	destroy_children()
	for instance in original_instances:
		var packed_scene = load(instance.path)
		var instanced_scene = packed_scene.instance(true)
		instanced_scene.set_filename(ProjectSettings.localize_path(instance.path))
		add_child(instanced_scene)
		instanced_scene.set_transform(instance.transform)
		if p_editor_interface:
			instanced_scene.set_owner(p_editor_interface.get_edited_scene_root())
	original_instances = []
	property_list_changed_notify()

func backup_children():
	for child in get_children():
		if child.get_filename() != "":
			original_instances.append({"path":child.get_filename(), "transform":child.get_transform()})
	property_list_changed_notify()
			
func destroy_children():
	for child in get_children():
		child.queue_free()
		child.get_parent().remove_child(child)

static func find_valid_instances(p_node, p_array):
	for child in p_node.get_children():
		if child is MeshInstance and child.get_mesh() != null:
			p_array.append(child)
		elif child is StaticBody:
			p_array.append(child)
		
		p_array = find_valid_instances(child, p_array)
		
	return p_array
	
func toggle_group(p_editor_interface):
	if original_instances.size() == 0:
		combine_mesh_instances(p_editor_interface)
	else:
		restore_backup(p_editor_interface)

func combine_mesh_instances(p_editor_interface):
	var valid_instances = find_valid_instances(self, [])
	
	var mesh_combiner = mesh_combiner_const.new()
	var collision_shapes = []
	
	var combined_mesh = null
	if valid_instances.size() > 0:
		for valid_instance in valid_instances:
			if valid_instance is MeshInstance:
				mesh_combiner.append_mesh(valid_instance.get_mesh(), Vector2(0.0, 0.0), Vector2(1.0, 1.0), get_global_transform().affine_inverse() * valid_instance.get_global_transform())
			elif valid_instance is StaticBody:
				for child in valid_instance.get_children():
					if child is CollisionShape:
						collision_shapes.append({"instance":child, "transform":child.get_global_transform()})
						child.get_parent().remove_child(child)
					valid_instance.get_parent().remove_child(valid_instance)
		combined_mesh = mesh_combiner.generate_mesh()
	
	backup_children()
	destroy_children()
	
	if combined_mesh != null:
		var new_mesh_instance = MeshInstance.new()
		new_mesh_instance.set_mesh(combined_mesh)
		new_mesh_instance.set_name("CombinedMesh")
		add_child(new_mesh_instance)
		if p_editor_interface:
			new_mesh_instance.set_owner(p_editor_interface.get_edited_scene_root())
	if collision_shapes.size() > 0:
		var static_body = StaticBody.new()
		static_body.set_name("Collision")
		for collision_shape in collision_shapes:
			var instance = collision_shape.instance
			static_body.add_child(instance)
			instance.set_global_transform(collision_shape.transform)
			
		add_child(static_body)
		
		# Setup ownership
		if p_editor_interface:
			static_body.set_owner(p_editor_interface.get_edited_scene_root())
			for collision_shape in collision_shapes:
				var instance = collision_shape.instance
				instance.set_owner(p_editor_interface.get_edited_scene_root())
			
func _ready():
	if Engine.is_editor_hint() == false:
		if original_instances.size() == 0:
			combine_mesh_instances()
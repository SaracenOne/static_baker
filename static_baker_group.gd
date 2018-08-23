extends Spatial
tool

const material_replacer_const = preload("material_replacer.gd")
const mesh_combiner_const = preload("res://addons/mesh_combiner/mesh_combiner.gd")

export(Array) var original_instances = []
var material_replacer_count = 0# setget set_material_replacer_count
var material_replacers = []

export(bool) var use_vertex_compression = false

func set_material_replacer_count(p_count):
	var initial_count = material_replacer_count
	material_replacer_count = p_count
	
	if material_replacer_count != initial_count:
		material_replacers.resize(material_replacer_count)
	
	property_list_changed_notify()

func set_material_replacer(p_idx, p_material_replacer):
	if (p_idx >= material_replacers.size() || p_idx < 0):
		return
		
	if p_material_replacer and p_material_replacer is material_replacer_const:
		material_replacers[p_idx] = p_material_replacer
	else:
		material_replacers[p_idx] = null
	property_list_changed_notify()
	
	execute_material_replacers()

func _get_property_list():
	var property_list = []
	
	property_list.push_back({"name":"material_replacers/count", "type":TYPE_INT, "hint":PROPERTY_HINT_NONE})
	for i in range(0, material_replacer_count):
		property_list.push_back({"name":"material_replacers/" + str(i) + "/material_replacer", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE,"hint_string":"MaterialReplacer"})
		
	return property_list
	
func _set(p_property, p_value):
	if (p_property.begins_with("material_replacers/")):
		var split_property = p_property.split("/", -1)
		if split_property.size() > 1:
			if split_property[1] == "count":
				set_material_replacer_count(p_value)
			else:
				var idx = split_property[1].to_int()
				if (idx < material_replacers.size() || idx >= 0):
					if split_property.size() == 3 and split_property[2] == "material_replacer":
						set_material_replacer(idx, p_value)
	
func _get(p_property):
	if (p_property.begins_with("material_replacers/")):
		var split_property = p_property.split("/", -1)
		if split_property.size() > 1:
			if split_property[1] == "count":
				return material_replacer_count
			else:
				var idx = split_property[1].to_int()
				if (idx < material_replacers.size() || idx >= 0):
					if split_property.size() == 3 and split_property[2] == "material_replacer":
						return material_replacers[idx]

func replace_materials(p_material_replacers, p_instances):
	var mesh_instances = p_instances.mesh_instances
	
	for mesh_instance in mesh_instances:
		if mesh_instance is MeshInstance:
			
			var mesh = mesh_instance.mesh
			
			if mesh is ArrayMesh:
				var surface_count = mesh.get_surface_count()
				for i in range(0, surface_count):
					mesh_instance.set_surface_material(i, null)
					var mesh_material = mesh.surface_get_material(i)
					
					for material_replacer in p_material_replacers:
						if material_replacer != null and material_replacer is material_replacer_const:
							for material_swap in material_replacer.material_swaps:
								if mesh_material == material_swap.original_material:
									mesh_instance.set_surface_material(i, material_swap.replacement_material)
									break
			elif mesh is PrimitiveMesh:
				var mesh_material = mesh.material
				for material_replacer in p_material_replacers:
					if material_replacer != null and material_replacer is material_replacer_const:
						for material_swap in material_replacer.material_swaps:
							if mesh_material == material_swap.original_material:
								mesh_instance.set_surface_material(0, material_swap.replacement_material)
								break

func execute_material_replacers():
	replace_materials(material_replacers, process_child_instances(self, {"mesh_instances":[], "static_bodies":[]}, null, get_script(), false, false))

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
	execute_material_replacers()
	property_list_changed_notify()

func backup_children():
	for child in get_children():
		if child.get_filename() != "" and Engine.is_editor_hint():
			original_instances.append({"path":child.get_filename(), "transform":child.get_transform()})
	property_list_changed_notify()
			
func destroy_children():
	for child in get_children():
		child.queue_free()
		child.get_parent().remove_child(child)

static func process_child_instances(p_node, p_dictionary, p_editor_interface, p_this_script, p_include_static_bodies, p_bake_children):
	for child in p_node.get_children():
		if child is MeshInstance and child.get_mesh() != null:
			p_dictionary.mesh_instances.append(child)
		elif child is StaticBody:
			if p_include_static_bodies:
				p_dictionary.static_bodies.append(child)
		else:
			if p_bake_children:
				# Ensure any other static baker groups children are baked
				if child.get_script() == p_this_script:
					if child.original_instances.size() == 0:
						child.combine_instances(p_editor_interface)
				
			p_dictionary = process_child_instances(child, p_dictionary, p_editor_interface, p_this_script, p_include_static_bodies, p_bake_children)
		
	return p_dictionary
	
func toggle_group(p_editor_interface):
	if original_instances.size() == 0:
		combine_instances(p_editor_interface)
	else:
		restore_backup(p_editor_interface)

func combine_instances(p_editor_interface):
	print("Static baker group " + str(get_name() + " combining:"))
	var valid_instances = process_child_instances(self, {"mesh_instances":[], "static_bodies":[]}, p_editor_interface, get_script(), true, true)
	
	var mesh_combiner = mesh_combiner_const.new()
	var saved_mesh_instances = []
	var saved_static_bodies = []
	
	var mesh_instances = valid_instances.mesh_instances
	var static_bodies = valid_instances.static_bodies
	
	# Save all the valid mesh instances
	for mesh_instance in mesh_instances:
		if mesh_instance is MeshInstance:
			saved_mesh_instances.append({"mesh":mesh_instance.get_mesh(), "transform":get_global_transform().affine_inverse() * mesh_instance.get_global_transform()})
			
	# Now combine them in the mesh combiner
	for saved_mesh_instance in saved_mesh_instances:
		print("Combining " + str(saved_mesh_instance.mesh.get_name() + "..."))
		mesh_combiner.append_mesh(saved_mesh_instance.mesh, Vector2(0.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 0.0), Vector2(1.0, 1.0), saved_mesh_instance.transform, PoolIntArray(), 0.000001)
		print("Done!")
			
	# Save and unparent static bodies
	for static_body in static_bodies:
		if static_body is StaticBody:
			saved_static_bodies.append({"instance":static_body, "transform":static_body.get_global_transform()})
			static_body.get_parent().remove_child(static_body)

	var combined_mesh = null
	if use_vertex_compression:
		combined_mesh = mesh_combiner.generate_mesh(Mesh.ARRAY_COMPRESS_DEFAULT)
	else:
		combined_mesh = mesh_combiner.generate_mesh(0)
	
	print("All instances combined!")
	
	backup_children()
	destroy_children()
	
	if combined_mesh != null:
		var new_mesh_instance = MeshInstance.new()
		new_mesh_instance.set_mesh(combined_mesh)
		new_mesh_instance.set_name("CombinedMesh")
		add_child(new_mesh_instance)
		if p_editor_interface:
			new_mesh_instance.set_owner(p_editor_interface.get_edited_scene_root())
			
	# Static bodies
	
	for saved_static_body in saved_static_bodies:
		var instance = saved_static_body.instance
		add_child(saved_static_body.instance)
		instance.set_global_transform(saved_static_body.transform)
		
		# Setup ownership
		if p_editor_interface:
			instance.set_owner(p_editor_interface.get_edited_scene_root())
			for child in instance.get_children():
				child.set_owner(p_editor_interface.get_edited_scene_root())
				
	execute_material_replacers()
			
func _ready():
	if ProjectSettings.has_setting("static_baker/autobake_all") == false:
		ProjectSettings.set_setting("static_baker/autobake_all", false)
	
	if typeof(original_instances) != TYPE_ARRAY:
		original_instances = []
	
	if Engine.is_editor_hint() == false:
		if original_instances.size() == 0:
			if ProjectSettings.get_setting("static_baker/autobake_all") == true:
				combine_instances(null)
	
	execute_material_replacers()
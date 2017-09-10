tool
extends EditorPlugin

const static_baker_group_const = preload("static_baker_group.gd")

var editor_interface = null
var button = null
var selected_node = null

func update_button_label():
	if(selected_node.get_script() == static_baker_group_const):
		if button:
			if selected_node.original_instances.size() > 0:
				button.set_text("Unpack Meshes")
			else:
				button.set_text("Pack Meshes")

func _process_static_baker_group():
	if(selected_node):
		if(selected_node.get_script() == static_baker_group_const):
			selected_node.toggle_group(editor_interface)
			update_button_label()

func handles(p_object):
	return p_object.get_script() == static_baker_group_const
	
func make_visible(p_visible):
	if button:
		if (p_visible):
			update_button_label()
			button.show()
		else:
			button.hide()

func edit(p_object):
	if(p_object == null || selected_node == p_object):
		return
		
	selected_node = p_object

func _init():
	print("Setting up Static Baker plugin")
	
func _enter_tree():
	editor_interface = get_editor_interface()
	
	button = Button.new()
	button.set_button_icon(editor_interface.get_base_control().get_icon("BakedLight", "EditorIcons"))
	button.set_tooltip("Convert collection of static meshes into a single mesh.")
	button.connect("pressed", self, "_process_static_baker_group")
	
	button.hide()
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, button)

	add_custom_type("StaticBakerGroup", "Position3D", static_baker_group_const, editor_interface.get_base_control().get_icon("BakedLightInstance", "EditorIcons"))

func _exit_tree():
	editor_interface = null
	button.free()
	remove_custom_type("StaticBakerGroup")

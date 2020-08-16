tool
extends EditorPlugin

const static_baker_group_const = preload("static_baker_group.gd")
const material_replacer_const = preload("material_replacer.gd")

var editor_interface: EditorInterface = null
var button: Button = null
var selected_node: Node = null


func update_button_label() -> void:
	if selected_node.get_script() == static_baker_group_const:
		if button:
			if selected_node.original_instances.size() > 0:
				button.set_text("Unpack Meshes")
			else:
				button.set_text("Pack Meshes")


func _process_static_baker_group() -> void:
	if selected_node:
		if selected_node.get_script() == static_baker_group_const:
			selected_node.toggle_group(editor_interface)
			update_button_label()


func handles(p_object) -> bool:
	if p_object is Node:
		var is_top_level = p_object.get_owner() == null
		var is_external = p_object.get_filename() != ""
		return p_object.get_script() == static_baker_group_const and (is_top_level or ! is_external)

	return false


func make_visible(p_visible: bool) -> void:
	if button:
		if p_visible:
			update_button_label()
			button.show()
		else:
			button.hide()


func edit(p_object) -> void:
	if p_object == null || selected_node == p_object:
		return

	selected_node = p_object


func _init() -> void:
	print("Initialising StaticBaker plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying StaticBaker plugin")


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	button = Button.new()
	button.set_button_icon(
		editor_interface.get_base_control().get_icon("BakedLightmap", "EditorIcons")
	)
	button.set_tooltip("Convert collection of static meshes into a single mesh.")
	button.connect("pressed", self, "_process_static_baker_group")

	button.hide()
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, button)


func _exit_tree() -> void:
	editor_interface = null
	button.free()

tool
extends Resource

class MaterialSwap:
	var original_material = null
	var replacement_material = null

var material_swaps = []

func _get_property_list():
	var property_list = []

	property_list.push_back({"name":"material_swap/count", "type": TYPE_INT})
	for i in range(0, material_swaps.size()):
		property_list.push_back({"name":"material_swap/" + str(i) + "/original_material", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE,"hint_string":"Material"})
		property_list.push_back({"name":"material_swap/" + str(i) + "/replacement_material", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE,"hint_string":"Material"})

	return property_list

func _get(p_property):
	var split_property = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property[0] == "material_swap" and split_property.size() > 1:
			if(split_property[1] == "count" and split_property.size() == 2):
				return material_swaps.size()
			elif(split_property[1].is_valid_integer() and split_property.size() == 3):
				var index = split_property[1].to_int()
				if index < material_swaps.size():
					if split_property[2] == "original_material":
						return material_swaps[index].original_material
					elif split_property[2] == "replacement_material":
						return material_swaps[index].replacement_material
	
	if(p_property == "material_swap/count"):
		return material_swaps.size()

func _set(p_property, p_value):
	var split_property = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property[0] == "material_swap" and split_property.size() > 1:
			if(split_property[1] == "count" and split_property.size() == 2):
				if typeof(p_value) == TYPE_INT:
					var initial_size = material_swaps.size()
					material_swaps.resize(p_value)
					# Fill the material swaps
					if p_value != initial_size:
						if p_value > initial_size:
							for i in range(initial_size, p_value):
								material_swaps[i] = MaterialSwap.new()
						property_list_changed_notify()
			elif(split_property[1].is_valid_integer() and split_property.size() == 3):
				if p_value is Material:
					var index = split_property[1].to_int()
					if index < material_swaps.size():
						if split_property[2] == "original_material":
							material_swaps[index].original_material = p_value
						elif split_property[2] == "replacement_material":
							material_swaps[index].replacement_material = p_value
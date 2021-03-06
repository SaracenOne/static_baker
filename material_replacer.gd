tool
extends Resource
class_name MaterialReplacer


class MaterialSwap:
	var original_material: Material = null
	var replacement_material: Material = null


var material_swaps: Array = []


func _get_property_list() -> Array:
	var property_list: Array = []

	property_list.push_back({"name": "material_swap/count", "type": TYPE_INT})
	for i in range(0, material_swaps.size()):
		property_list.push_back(
			{
				"name": "material_swap/%s/original_material" % str(i),
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "Material"
			}
		)
		property_list.push_back(
			{
				"name": "material_swap/%s/replacement_material" % str(i),
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "Material"
			}
		)

	return property_list


func _get(p_property: String):
	var split_property: Array = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property[0] == "material_swap" and split_property.size() > 1:
			if split_property[1] == "count" and split_property.size() == 2:
				return material_swaps.size()
			elif split_property[1].is_valid_integer() and split_property.size() == 3:
				var index: int = split_property[1].to_int()
				if index < material_swaps.size():
					if split_property[2] == "original_material":
						return material_swaps[index].original_material
					elif split_property[2] == "replacement_material":
						return material_swaps[index].replacement_material

	if p_property == "material_swap/count":
		return material_swaps.size()


func _set(p_property: String, p_value) -> bool:
	var split_property: Array = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property[0] == "material_swap" and split_property.size() > 1:
			if split_property[1] == "count" and split_property.size() == 2:
				if typeof(p_value) == TYPE_INT:
					var initial_size: int = material_swaps.size()
					material_swaps.resize(p_value)
					# Fill the material swaps
					if p_value != initial_size:
						if p_value > initial_size:
							for i in range(initial_size, p_value):
								material_swaps[i] = MaterialSwap.new()
						property_list_changed_notify()
					return true
			elif split_property[1].is_valid_integer() and split_property.size() == 3:
				if (p_value != null and p_value is Material) or p_value == null:
					var index: int = split_property[1].to_int()
					if index < material_swaps.size():
						if split_property[2] == "original_material":
							material_swaps[index].original_material = p_value
							return true
						elif split_property[2] == "replacement_material":
							material_swaps[index].replacement_material = p_value
							return true

	return false

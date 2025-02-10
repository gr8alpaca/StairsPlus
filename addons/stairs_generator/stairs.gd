@tool
extends Node3D

@export var size: Vector3 = Vector3.ONE


#func _get_property_list() -> Array[Dictionary]:
	#var props: Array[Dictionary]
	#for i: int in 3:
		#props.push_back({
			#name = ["width", "height", "length",][i],
			#type = TYPE_FLOAT,
			#hint = PROPERTY_HINT_RANGE,
			#hint_string = "0.0,5.0,0.05,or_greater,suffix:m",
		#})
	#return props
#
#func _set(property: StringName, value: Variant) -> bool:
	#match property:
		#&"width": 	size.x = value
		#&"height": 	size.y = value
		#&"length": 	size.z = value
	#return false
#
#func _get(property: StringName) -> Variant:
	#match property:
		#&"width": 	return size.x
		#&"height": 	return size.y
		#&"length": 	return size.z
	#return null

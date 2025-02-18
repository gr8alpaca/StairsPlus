@tool
extends EditorScript
#const BRICK_MATERIAL = preload("res://brick_material.tres")
#const Stairs = preload("res://addons/stairs_generator/stairs.gd")
const FORMAT:= 34_359_738_377 
const FORMAT2:= 34_359_742_473
func _run() -> void:
	print("Running...")
	var scene:= get_scene()
	
	#const ARRAY_MESH: ArrayMesh = preload("res://array_mesh.tres")
	#for i in ARRAY_MESH.get_surface_count():
		#print("\n --- PRIM TYPE: %s | FORMAT: %s \n" % [ARRAY_MESH.surface_get_primitive_type(i), ARRAY_MESH.surface_get_format(i)])
		#print_flags(ARRAY_MESH.surface_get_format(i), &"Mesh", &"ArrayFormat")
		#for e in ARRAY_MESH.surface_get_arrays(i):
			#printt(e)
	

func print_flags(flag_value: int, _class: StringName, _enum: StringName, no_inheretance: bool = false) -> void:
	const MAX_ENUM_STRING_LENGTH: int = 25
	for name: String in ClassDB.class_get_enum_constants(_class, _enum, no_inheretance):
		print(name.rpad(MAX_ENUM_STRING_LENGTH) + " => ", ClassDB.class_get_integer_constant(_class, name) & flag_value)

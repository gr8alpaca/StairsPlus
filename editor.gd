@tool
extends EditorScript


func _run() -> void:
	print("Running...")
	
	var box: BoxMesh = BoxMesh.new()
	var arr:= box.get_mesh_arrays()
	for i: int in arr.size():
		if not arr[i]: continue
		printt("#%d: " % i, arr[i])
	
	#printt(box.get_mesh_arrays())



func box_get_points(size: Vector3) -> PackedVector3Array:
	var half_size: Vector3 = size/2.0
	var points: PackedVector3Array
	for x: float in [half_size.x, -half_size.x]:
		for y: float in [half_size.y, -half_size.y]:
			for z: float in [half_size.z, -half_size.z]:
				points.push_back(Vector3(x, y, z))
	return points

func box_get_lines(size: Vector3) -> PackedVector3Array:
	var half: Vector3 = size/2.0
	
	var lines: PackedVector3Array
	var points: PackedVector3Array = box_get_points(size)
	for start in points:
		for axis: int in 3:
			var end: Vector3 = start
			end[axis] *= -1.0
			lines.push_back(start)
			lines.push_back(end)
			
		
	#for i: int in 8:
		#for j: int in 8:
			#if i == j: continue
			#points[i]
	#
	#for a : Vector3 in points:
		#for b: Vector3 in points:
			#if int(a[0] == b[0]) + int(a[1] == b[1]) + int(a[2] == b[2]) == 2: 
				#lines.push_back(a)
				#lines.push_back(b)
	
	
	
	return lines

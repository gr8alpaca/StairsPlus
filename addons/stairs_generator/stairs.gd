@tool
extends Node3D

signal resized

@export
var size: Vector3 = Vector3.ONE: set = set_size

@export_range(1, 32, 1, "or_greater") 
var step_count: int = 12: set = set_step_count

@export_group("Visibility")

@export 
var material: Material = StandardMaterial3D.new(): set = set_material

@export
var triplanar_mode: bool = true: set = set_triplanar_mode

func set_triplanar_mode(val: bool) -> void:
	triplanar_mode = val
	update_mesh()

@export 
var uv_scale: Vector2 = Vector2.ONE : set = set_uv_scale

@export_flags_3d_render 
var layer_mask: int = 0xFFFFFF: set = set_render_layers


@export_group("Physics")

@export
var body_mode: PhysicsServer3D.BodyMode = PhysicsServer3D.BodyMode.BODY_MODE_STATIC: set = set_body_mode

@export_flags_3d_physics
var collision_layers: int = 1: set = set_collision_layers

@export_flags_3d_physics 
var collision_mask: int = 1: set = set_collision_mask

@export 
var debug_color: Color = ProjectSettings.get_setting("debug/shapes/collision/shape_color", Color(0.0, 0.6, 0.7, 0.42)) : set = set_debug_color

@export 
var debug_fill: bool = true: set = set_debug_fill

var instance: RID
var mesh: RID

var body: RID
var shape: RID

var debug_instance: RID
var debug_mesh: RID
var debug_material: Material


func _init() -> void:
	# Init Visual Instance and Mesh RIDs
	instance = RenderingServer.instance_create()
	mesh = RenderingServer.mesh_create()
	RenderingServer.instance_set_base(instance, mesh)
	RenderingServer.instance_attach_object_instance_id(instance, get_instance_id())
	
	# Init Physics RIDs
	body = PhysicsServer3D.body_create()
	shape = PhysicsServer3D.convex_polygon_shape_create()
	PhysicsServer3D.body_attach_object_instance_id(body, get_instance_id())
	PhysicsServer3D.body_add_shape(body, shape, )
	PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_collision_layer(body, 1)
	PhysicsServer3D.body_set_collision_mask(body, 1)
	PhysicsServer3D.shape_set_data(shape, get_collision_shape_vertices())
	
	set_notify_transform(true)
	
	if not Engine.is_editor_hint() and not (OS.is_debug_build() and Engine.get_main_loop().debug_collisions_hint):
		return
	
	# Init Physics Shape Debug
	debug_instance = RenderingServer.instance_create()
	debug_mesh = RenderingServer.mesh_create()
	RenderingServer.instance_set_base(debug_instance, debug_mesh)
	RenderingServer.instance_attach_object_instance_id(debug_instance, get_instance_id())
	
	debug_material = StandardMaterial3D.new()
	debug_material.render_priority = -127
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.disable_fog = true
	debug_material.vertex_color_use_as_albedo = true
	debug_material.vertex_color_is_srgb = true


func apply_material(mesh_rid: RID = mesh, material_to_apply: Material = material) -> void:
	if not mesh_rid or not mesh_rid.is_valid() or not material_to_apply: return
	for i: int in RenderingServer.mesh_get_surface_count(mesh_rid):
		RenderingServer.mesh_surface_set_material(mesh_rid, i, material_to_apply.get_rid())

func apply_debug_material() -> void:
	var material_rid: RID = debug_material.get_rid() if debug_material else RID()
	for i : int in RenderingServer.mesh_get_surface_count(debug_mesh):
		RenderingServer.mesh_surface_set_material(debug_mesh, i, material_rid)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_WORLD:
			var world: World3D = get_world_3d()
			PhysicsServer3D.body_set_space(body, world.space)
			RenderingServer.instance_set_scenario(instance, world.scenario)
			if debug_instance and debug_instance.is_valid():
				RenderingServer.instance_set_scenario(debug_instance, world.scenario)
		
		NOTIFICATION_EXIT_WORLD:
			PhysicsServer3D.body_set_space(body, RID())
			RenderingServer.instance_set_scenario(instance, RID())
			if debug_instance and debug_instance.is_valid():
				RenderingServer.instance_set_scenario(debug_instance, RID())
		
		NOTIFICATION_VISIBILITY_CHANGED:
			RenderingServer.instance_set_visible(instance, is_visible_in_tree())
			if debug_instance and debug_instance.is_valid():
				RenderingServer.instance_set_visible(debug_instance, is_visible_in_tree())
		
		NOTIFICATION_PREDELETE:
			if debug_instance and debug_instance.is_valid():
				RenderingServer.free_rid(debug_instance)
			if debug_mesh and debug_mesh.is_valid():
				RenderingServer.free_rid(debug_mesh)
			
			RenderingServer.mesh_clear(mesh)
			RenderingServer.free_rid(mesh)
			RenderingServer.free_rid(instance)
			PhysicsServer3D.free_rid(body)
		
		NOTIFICATION_TRANSFORM_CHANGED when is_inside_tree():
			var trans: Transform3D = global_transform #.translated_local(Vector3(0.0, 0.5, 0.0) * size)
			for shape_index: int in PhysicsServer3D.body_get_shape_count(body):
				PhysicsServer3D.body_set_shape_transform(body, shape_index, trans)
				
			RenderingServer.instance_set_transform(instance, trans)
			
			if debug_instance and debug_instance.is_valid():
				RenderingServer.instance_set_transform(debug_instance, trans)
		
		#NOTIFICATION_TRANSFORM_CHANGED:
			#for shape_index: int in PhysicsServer3D.body_get_shape_count(body):
				#PhysicsServer3D.body_set_shape_transform(body, shape_index, global_transform)

func update_collision_shape() -> void:
	PhysicsServer3D.shape_set_data(shape, get_collision_shape_vertices())
	if is_inside_tree():
		for shape_index: int in PhysicsServer3D.body_get_shape_count(body):
			PhysicsServer3D.body_set_shape_transform(body, shape_index, global_transform)


#region Drawing

func update_debug_mesh() -> void:
	if not debug_mesh or not debug_mesh.is_valid(): return
	
	RenderingServer.mesh_clear(debug_mesh)
	
	# Draw Lines
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = get_collision_shape_vertices()
	
	arr[Mesh.ARRAY_COLOR] = PackedColorArray()
	arr[Mesh.ARRAY_COLOR].resize(arr[Mesh.ARRAY_VERTEX].size())
	arr[Mesh.ARRAY_COLOR].fill(debug_color)
	
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 0, 2, 0, 3, 1, 2, 1, 4, 2, 5, 3, 4, 3, 5, 4, 5])
	
	RenderingServer.mesh_add_surface_from_arrays(debug_mesh, RenderingServer.PRIMITIVE_LINES, arr)
	
	# Draw Fill
	if debug_fill:
		const FILL_OPACITY_RATIO: float = 0.024 / 0.42
		arr[Mesh.ARRAY_COLOR].fill(Color(debug_color, debug_color.a * FILL_OPACITY_RATIO))
		arr[Mesh.ARRAY_INDEX] = PackedInt32Array([1, 0, 2, 1, 2, 4, 2, 0, 3, 2, 3, 5, 3, 0, 1, 3, 1, 4, 3, 4, 5, 4, 2, 5])
		RenderingServer.mesh_add_surface_from_arrays(debug_mesh, RenderingServer.PRIMITIVE_TRIANGLES, arr)
	
	# Material
	apply_material(debug_mesh, debug_material)


func update_mesh() -> void:
	RenderingServer.mesh_clear(mesh)
	
	if size.x == 0 or size.y == 0 or size.z == 0: return
	var size: Vector3 = self.size/2.0
	var step_size:= get_step_size()
	var half_step:= step_size/2.0
	
	var offset: Vector3 = Vector3(0.0, -size.y, size.z) * float(step_count-1) / float(step_count)
	var step_offset: Vector3 = Vector3(0.0, step_size.y, -step_size.z)
	
	var material_rid: RID = material.get_rid() if material else RID()
	var arrays: Array
	var st := SurfaceTool.new()
	
	for i: int in step_count:
		var x1: float = 0.0
		var x2: float = uv_scale.x * (size.x if triplanar_mode else 1.0)
		
		var y1: float = inverse_lerp(0, step_count, i) * uv_scale.y * ((size.y + size.z) / 2.0 if triplanar_mode else 1.0)
		var y3: float = inverse_lerp(0, step_count, i + 1) * uv_scale.y * ((size.y + size.z) / 2.0 if triplanar_mode else 1.0)
		var y2: float = lerpf(y1, y3, size.y / (size.y + size.z) if triplanar_mode else 0.5)
		
		var triplanar_scale:Vector2 = Vector2(size.x, size.y) if triplanar_mode else Vector2.ONE
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_tangent(Plane.PLANE_XY)
		st.set_normal(Vector3.BACK)
		
		st.set_uv(Vector2(x1, y1))
		st.add_vertex(offset + Vector3(-half_step.x, -half_step.y, half_step.z))
		
		st.set_uv(Vector2(x1, y2))
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y, half_step.z))
		
		st.set_uv(Vector2(x2, y2))
		st.add_vertex(offset + Vector3(half_step.x, half_step.y, half_step.z))
		
		st.set_uv(Vector2(x2, y1))
		st.add_vertex(offset + Vector3(half_step.x, -half_step.y, half_step.z))
		st.add_index(0)
		st.add_index(1)
		st.add_index(2)
		st.add_index(2)
		st.add_index(3)
		st.add_index(0)
		
		
		st.set_tangent(-Plane.PLANE_XZ)
		st.set_normal(Vector3.UP)
		
		st.set_uv(Vector2(x1, y2))
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y, half_step.z))
		
		st.set_uv(Vector2(x1, y3))
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y, -half_step.z))
		
		st.set_uv(Vector2(x2, y3))
		st.add_vertex(offset + Vector3(half_step.x, half_step.y, -half_step.z))
		
		st.set_uv(Vector2(x2, y2))
		st.add_vertex(offset + Vector3(half_step.x, half_step.y, half_step.z))
		st.add_index(4)
		st.add_index(5)
		st.add_index(6)
		st.add_index(6)
		st.add_index(7)
		st.add_index(4)
		
		var uv_start:= Vector2(inverse_lerp(0, step_count*2, i), 1.0 - inverse_lerp(0, step_count, i + 1)) * uv_scale
		var uv_end:= Vector2(inverse_lerp(0, step_count*2, i + 1), 1.0) * uv_scale
		var side_scale: float =  i * step_size.y
		
		
		st.set_normal(Vector3.LEFT)
		st.set_tangent(Plane.PLANE_YZ)
		st.set_uv(Vector2(uv_start.x, uv_end.y)) 
		st.add_vertex(offset + Vector3(-half_step.x, -half_step.y - side_scale, -half_step.z))
		st.set_uv(uv_start)
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y, -half_step.z))
		st.set_uv(Vector2(uv_end.x, uv_start.y))
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y , half_step.z))
		st.set_uv(uv_end)
		st.add_vertex(offset + Vector3(-half_step.x, -half_step.y - side_scale, half_step.z))
		st.add_index(8)
		st.add_index(9)
		st.add_index(10)
		st.add_index(10)
		st.add_index(11)
		st.add_index(8)
		
		
		st.set_normal(Vector3.RIGHT)
		st.set_tangent(-Plane.PLANE_YZ)
		st.set_uv(uv_end)
		st.add_vertex (offset + Vector3(half_step.x, -half_step.y - side_scale, half_step.z))
		st.set_uv(Vector2(uv_end.x, uv_start.y))
		st.add_vertex(offset + Vector3(half_step.x, half_step.y , half_step.z))
		st.set_uv(uv_start)
		st.add_vertex(offset + Vector3(half_step.x, half_step.y, -half_step.z))
		st.set_uv(Vector2(uv_start.x, uv_end.y))
		st.add_vertex (offset + Vector3(half_step.x, -half_step.y - side_scale, -half_step.z))
		st.add_index(12)
		st.add_index(13)
		st.add_index(14)
		st.add_index(14)
		st.add_index(15)
		st.add_index(12)
		
		RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, st.commit_to_arrays() )
		st.clear()
		
		
		
		offset += step_offset
		
		
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.FORWARD)
	st.set_tangent(Plane.PLANE_XY)
	st.set_uv(Vector2.DOWN * uv_scale)
	st.add_vertex(size * Vector3(1.0, -1.0, -1.0))
	st.set_uv(Vector2.ZERO * uv_scale)
	st.add_vertex(size * Vector3(1.0, 1.0, -1.0))
	st.set_uv(Vector2.RIGHT * uv_scale)
	st.add_vertex(size * Vector3(-1.0, 1.0, -1.0))
	st.set_uv(Vector2.ONE * uv_scale)
	st.add_vertex(size * Vector3(-1.0, -1.0, -1.0))
	
	st.add_index(0)
	st.add_index(1)
	st.add_index(2)
	st.add_index(2)
	st.add_index(3)
	st.add_index(0)
	
	st.set_normal(Vector3.DOWN)
	st.set_tangent(-Plane.PLANE_XZ)
	st.set_uv(Vector2.DOWN * uv_scale)
	st.add_vertex(size * Vector3(-1.0, -1.0, -1.0))
	st.set_uv(Vector2.ZERO * uv_scale)
	st.add_vertex(size * Vector3(-1.0, -1.0, 1.0))
	st.set_uv(Vector2.RIGHT * uv_scale)
	st.add_vertex(size * Vector3(1.0, -1.0, 1.0))
	st.set_uv(Vector2.ONE * uv_scale)
	st.add_vertex(size * Vector3(1.0, -1.0, -1.0))
	
	st.add_index(4)
	st.add_index(5)
	st.add_index(6)
	st.add_index(6)
	st.add_index(7)
	st.add_index(4)
	
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	apply_material()

#endregion Drawing

#region Helpers

func get_step_height() -> float:
	return size.y / float(step_count)

func get_step_length() -> float:
	return size.z / float(step_count)

func get_step_size() -> Vector3:
	return size / Vector3(1.0, step_count, step_count)

func get_collision_shape_vertices() -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(size.x/2.0, size.y/2.0, -size.z/2.0), 	Vector3(size.x/2.0, -size.y/2.0, -size.z/2.0),
		Vector3(size.x/2.0, -size.y/2.0, size.z/2.0), 	Vector3(-size.x/2.0, size.y/2.0, -size.z/2.0),
		Vector3(-size.x/2.0, -size.y/2.0, -size.z/2.0),	Vector3(-size.x/2.0, -size.y/2.0, size.z/2.0),
	])

#endregion Helpers

#region Setters

func set_body_mode(val: PhysicsServer3D.BodyMode) -> void:
	body_mode = val
	PhysicsServer3D.body_set_mode(body, val)

func set_collision_layers(val: int) -> void:
	collision_layers = maxi(0, val)
	PhysicsServer3D.body_set_collision_layer(body, val)

func set_collision_mask(val: int) -> void:
	collision_mask = maxi(0, val)
	PhysicsServer3D.body_set_collision_mask(body, val)

func set_render_layers(val: int) -> void:
	layer_mask = maxi(0, val)
	RenderingServer.instance_set_layer_mask(instance, layer_mask)

func set_step_count(val: int) -> void:
	step_count = maxi(1, val)
	update_mesh()

func set_size(val: Vector3) -> void:
	size = val.maxf(0.0)
	PhysicsServer3D.shape_set_data(shape, get_collision_shape_vertices())
	#if is_inside_tree():
		#PhysicsServer3D.body_set_shape_transform(body, 0, global_transform)
	
	update_mesh()
	update_debug_mesh()
	resized.emit()

func set_material(val: Material) -> void:
	material = val
	apply_material()

func set_uv_scale(val: Vector2) -> void:
	uv_scale = val
	update_mesh()

func set_debug_color(val: Color) -> void:
	debug_color = val
	update_debug_mesh()

func set_debug_fill(val: bool) -> void:
	debug_fill = val
	update_debug_mesh()

#endregion


func _validate_property(property: Dictionary) -> void:
	match property.name:
		&"body_mode":		property.hint_string = property.hint_string.replacen("Body Mode ", "")

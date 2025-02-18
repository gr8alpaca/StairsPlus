@tool
extends Node3D

signal resized

@export_tool_button("Debug", "EditorPlugin")
var foo_callabled: Callable = foo

@export
var size: Vector3 = Vector3.ONE: set = set_size

@export_range(1, 32, 1, "or_greater") 
var step_count: int = 12: set = set_step_count

@export var material: Material = StandardMaterial3D.new(): set = set_material
@export var uv_scale: Vector2 = Vector2.ONE : set = set_uv_scale

@export_group("Physics")
@export_enum("Static", "Kinematic", "Rigid", "Rigid Linear")
var physics_mode: int = 0: set = set_physics_mode

@export_flags_3d_physics 
var collision_layers: int = 1: set = set_collision_layers

@export_flags_3d_physics 
var collision_mask: int = 1: set = set_collision_mask

@export_group("Visibility")
@export_flags_3d_render 
var render_layers: int = 0xFFFFFF: set = set_render_layers

@export var debug_color: Color = ProjectSettings.get_setting("debug/shapes/collision/shape_color", Color(0.0, 0.6, 0.7, 0.42)): set = set_debug_color
@export var debug_fill: bool = true: set = set_debug_fill


enum {FLAG_RENDER_MESH, FLAG_RENDER_COLLISION_LINES, FLAG_RENDER_COLLISION_FILL, }
@export_storage var render_flags: int = 0xFFFFFF

var instance: RID
var mesh: RID

var body: RID
var shape: RID

var debug_material: Material


func foo() -> void:
	redraw()

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
	
	set_notify_transform(true)
	
	if not Engine.is_editor_hint() and not (OS.is_debug_build() and Engine.get_main_loop().debug_collisions_hint):
		return
	
	# Init Physics Shape Debug Material
	debug_material = StandardMaterial3D.new()
	debug_material.render_priority = -127
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.disable_fog = true
	debug_material.vertex_color_use_as_albedo = true
	debug_material.vertex_color_is_srgb = true


func update_shape() -> void:
	if not is_inside_tree(): return
	PhysicsServer3D.shape_set_data(shape, get_collision_shape_vertices())
	PhysicsServer3D.body_set_shape_transform(body, 0, global_transform)


func update_mesh() -> void:
	draw_stair(size)

func redraw() -> void:
	if not is_inside_tree(): return
	RenderingServer.mesh_clear(mesh)
	
	#apply_material()
	draw_debug_shape()


func apply_material() -> void:
	var rid: RID = material.get_rid() if material else RID()
	for i: int in RenderingServer.mesh_get_surface_count(mesh):
		RenderingServer.mesh_surface_set_material(mesh, i, rid)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_WORLD:
			var world: World3D = get_world_3d()
			PhysicsServer3D.body_set_space(body, world.space)
			RenderingServer.instance_set_scenario(instance, world.scenario)
			redraw()
		
		NOTIFICATION_EXIT_WORLD:
			PhysicsServer3D.body_set_space(body, RID())
			RenderingServer.instance_set_scenario(instance, RID())
		
		
		NOTIFICATION_VISIBILITY_CHANGED:
			RenderingServer.instance_set_visible(instance, visible)
		
		NOTIFICATION_PREDELETE:
			RenderingServer.mesh_clear(mesh)
			RenderingServer.free_rid(mesh)
			RenderingServer.free_rid(instance)
			PhysicsServer3D.free_rid(body)
		
		NOTIFICATION_TRANSFORM_CHANGED when is_inside_tree():
			RenderingServer.instance_set_transform(instance, global_transform)
			for shape_index: int in PhysicsServer3D.body_get_shape_count(body):
				PhysicsServer3D.body_set_shape_transform(body, shape_index, global_transform)


#region Drawing

func draw_debug_shape() -> void:
	
	var vertexes: PackedVector3Array = get_collision_shape_vertices()
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vertexes
	
	arr[Mesh.ARRAY_COLOR] = PackedColorArray()
	arr[Mesh.ARRAY_COLOR].resize(arr[Mesh.ARRAY_VERTEX].size())
	arr[Mesh.ARRAY_COLOR].fill(debug_color)
	
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 0, 2, 0, 3, 1, 2, 1, 4, 2, 5, 3, 4, 3, 5, 4, 5])
	
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_LINES, arr)
	RenderingServer.mesh_surface_set_material(mesh, RenderingServer.mesh_get_surface_count(mesh)-1, get_debug_material())
	
	# Draw Fill
	const FILL_OPACITY_RATIO: float = 0.024 / 0.42
	
	arr[Mesh.ARRAY_COLOR].fill(Color(debug_color, debug_color.a * FILL_OPACITY_RATIO))
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([1, 0, 2, 1, 2, 4, 2, 0, 3, 2, 3, 5, 3, 0, 1, 3, 1, 4, 3, 4, 5, 4, 2, 5])
	
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, arr)
	RenderingServer.mesh_surface_set_material(mesh, RenderingServer.mesh_get_surface_count(mesh)-1, get_debug_material())


func draw_stair(size: Vector3) -> void:
	if size.x == 0 or size.y == 0 or size.z == 0: return
	size /= 2.0
	var step_size:= get_step_size()
	var half_step:= step_size/2.0
	
	var offset: Vector3 = Vector3(0.0, -size.y, size.z) * float(step_count-1) / float(step_count)
	var step_offset: Vector3 = Vector3(0.0, step_size.y, -step_size.z)
	
	var surface_count: int = RenderingServer.mesh_get_surface_count(mesh) 
	var material_rid: RID = material.get_rid() if material else RID()
	var arrays: Array
	var st := SurfaceTool.new()
	
	for i: int in step_count:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_tangent(Plane.PLANE_XY)
		st.set_uv(uv_scale * Vector2.DOWN)
		st.set_normal(Vector3.BACK)
		st.add_vertex(offset + Vector3(-half_step.x, -half_step.y, half_step.z))
		
		st.set_uv(uv_scale * Vector2.ZERO)
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y, half_step.z))
		
		st.set_uv(uv_scale * Vector2.RIGHT)
		st.add_vertex(offset + Vector3(half_step.x, half_step.y, half_step.z))
		
		st.set_uv(uv_scale * Vector2.ONE)
		st.add_vertex(offset + Vector3(half_step.x, -half_step.y, half_step.z))
		st.add_index(0)
		st.add_index(1)
		st.add_index(2)
		st.add_index(2)
		st.add_index(3)
		st.add_index(0)
		
		st.set_tangent(-Plane.PLANE_XZ)
		st.set_normal(Vector3.UP)
		st.set_uv(uv_scale * Vector2.DOWN)
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y, half_step.z))
		st.set_uv(uv_scale * Vector2.ZERO)
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y, -half_step.z))
		st.set_uv(uv_scale * Vector2.RIGHT)
		st.add_vertex(offset + Vector3(half_step.x, half_step.y, -half_step.z))
		st.set_uv(uv_scale * Vector2.ONE)
		st.add_vertex(offset + Vector3(half_step.x, half_step.y, half_step.z))
		st.add_index(4)
		st.add_index(5)
		st.add_index(6)
		st.add_index(6)
		st.add_index(7)
		st.add_index(4)
		
		var side_scale: float =  i * step_size.y
		var uv_scale:= Vector2(step_size.z/step_size.x  , 1 + i) * uv_scale
		# BUG Strange Shadow Banding issue on this side, other size is fine
		
		st.set_normal(Vector3.RIGHT)
		st.set_tangent(-Plane.PLANE_YZ)
		st.set_uv(uv_scale * Vector2.DOWN)
		st.add_vertex(offset + Vector3(-half_step.x, -half_step.y - side_scale, -half_step.z))
		st.set_uv(uv_scale * Vector2.ZERO)
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y, -half_step.z))
		st.set_uv(uv_scale * Vector2.RIGHT)
		st.add_vertex(offset + Vector3(-half_step.x, half_step.y , half_step.z))
		st.set_uv(uv_scale * Vector2.ONE)
		st.add_vertex(offset + Vector3(-half_step.x, -half_step.y - side_scale, half_step.z))
		st.add_index(8)
		st.add_index(9)
		st.add_index(10)
		st.add_index(10)
		st.add_index(11)
		st.add_index(8)
		
		st.set_normal(Vector3.RIGHT)
		st.set_tangent(-Plane.PLANE_YZ)
		st.set_uv(uv_scale * Vector2.ONE)
		st.add_vertex (offset + Vector3(half_step.x, -half_step.y - side_scale, half_step.z))
		st.set_uv(uv_scale * Vector2.RIGHT)
		st.add_vertex(offset + Vector3(half_step.x, half_step.y , half_step.z))
		st.set_uv(uv_scale * Vector2.ZERO)
		st.add_vertex(offset + Vector3(half_step.x, half_step.y, -half_step.z))
		st.set_uv(uv_scale * Vector2.DOWN)
		st.add_vertex (offset + Vector3(half_step.x, -half_step.y - side_scale, -half_step.z))
		st.add_index(12)
		st.add_index(13)
		st.add_index(14)
		st.add_index(14)
		st.add_index(15)
		st.add_index(12)
		
		RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, st.commit_to_arrays() )
		st.clear()
		
		RenderingServer.mesh_surface_set_material(mesh, surface_count, material_rid)
		surface_count += 1
		
		offset += step_offset
		
		
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.FORWARD)
	st.set_tangent(Plane.PLANE_XY)
	st.set_uv(uv_scale * Vector2(0, step_count))
	st.add_vertex(size * Vector3(1.0, -1.0, -1.0))
	st.set_uv(uv_scale * Vector2.ZERO)
	st.add_vertex(size * Vector3(1.0, 1.0, -1.0))
	st.set_uv(uv_scale * Vector2.RIGHT)
	st.add_vertex(size * Vector3(-1.0, 1.0, -1.0))
	st.set_uv(uv_scale * Vector2(1, step_count))
	st.add_vertex(size * Vector3(-1.0, -1.0, -1.0))
	
	st.add_index(0)
	st.add_index(1)
	st.add_index(2)
	st.add_index(2)
	st.add_index(3)
	st.add_index(0)
	
	st.set_normal(Vector3.UP)
	st.set_tangent(-Plane.PLANE_XZ)
	st.set_uv(uv_scale * Vector2(0, step_count))
	st.add_vertex(size * Vector3(-1.0, -1.0, -1.0))
	st.set_uv(uv_scale * Vector2.ZERO)
	st.add_vertex(size * Vector3(-1.0, -1.0, 1.0))
	st.set_uv(uv_scale * Vector2.RIGHT)
	st.add_vertex(size * Vector3(1.0, -1.0, 1.0))
	st.set_uv(uv_scale * Vector2(1, step_count))
	st.add_vertex(size * Vector3(1.0, -1.0, -1.0))
	
	st.add_index(4)
	st.add_index(5)
	st.add_index(6)
	st.add_index(6)
	st.add_index(7)
	st.add_index(4)
	
	
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	RenderingServer.mesh_surface_set_material(mesh, surface_count, material_rid)

#endregion Drawing

#region Getters

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

func get_debug_material() -> RID:
	return debug_material.get_rid() if debug_material else RID()


#endregion Getters


#region Setters

func set_physics_mode(val: int) -> void:
	physics_mode = val
	PhysicsServer3D.body_set_mode(body, physics_mode as PhysicsServer3D.BodyMode)

func set_collision_layers(val: int) -> void:
	collision_layers = val 
	PhysicsServer3D.body_set_collision_layer(body, collision_layers)

func set_collision_mask(val: int) -> void:
	collision_mask = val 
	PhysicsServer3D.body_set_collision_mask(body, collision_mask)

func set_render_layers(val: int) -> void:
	render_layers = val 
	RenderingServer.instance_set_layer_mask(instance, render_layers)

func set_step_count(val: int) -> void:
	step_count = maxi(1, val)
	redraw()

func set_size(val: Vector3) -> void:
	size = val.maxf(0.0)
	redraw()
	resized.emit()

func set_material(val: Material) -> void:
	material = val
	apply_material()

func set_uv_scale(val: Vector2) -> void:
	uv_scale = val
	redraw()

func set_debug_color(val: Color) -> void:
	debug_color = val
	redraw()

func set_debug_fill(val: bool) -> void:
	debug_fill = val
	redraw()

#endregion

#func _get_property_list() -> Array[Dictionary]:
	#var props: Array[Dictionary]
	#props.push_back({
		#name = "flags",
		#type = TYPE_INT,
	#})
	#return props

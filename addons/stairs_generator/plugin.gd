@tool
extends EditorPlugin

var gizmo_plugin: EditorNode3DGizmoPlugin

func _enter_tree() -> void:
	Engine.set_meta(_get_plugin_name(), self)
	gizmo_plugin = preload("gizmo_plugin.gd").new()
	add_node_3d_gizmo_plugin(gizmo_plugin)
	add_custom_type("Stairs", "Node3D", preload("stairs.gd"), _get_plugin_icon())


func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	Engine.set_meta(_get_plugin_name(), null)

func _get_plugin_name() -> String:
	return "stairs_generator"

func _get_plugin_icon() -> Texture2D:
	return null

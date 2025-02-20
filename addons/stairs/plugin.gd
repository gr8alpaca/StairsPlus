@tool
extends EditorPlugin

var gizmo_plugin: EditorNode3DGizmoPlugin

func _enter_tree() -> void:
	gizmo_plugin = preload("gizmo_plugin.gd").new()
	add_node_3d_gizmo_plugin(gizmo_plugin)
	add_custom_type("Stairs", "Node3D", preload("stairs.gd"), preload("stairs.svg"))

func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	remove_custom_type("Stairs")

func _get_plugin_name() -> String:
	return "Stairs+"

func _get_plugin_icon() -> Texture2D:
	return preload("icon.svg")

func _handles(object: Object) -> bool:
	return false

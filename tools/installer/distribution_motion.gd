extends "../../GodotProject/tests/visual_motion.gd"

class ExternalMouseFilter extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseMotion or event is InputEventMouseButton:
			get_viewport().set_input_as_handled()

func _initialize() -> void:
	if "--qa" in OS.get_cmdline_user_args():
		# Keep fixed-step animation sampling separate from OS pointer warps and catch-up ticks.
		Engine.max_physics_steps_per_frame = 1
		root.add_child(ExternalMouseFilter.new())
	super._initialize()

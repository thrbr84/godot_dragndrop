extends Node2D

func _ready():
	for n in get_tree().get_nodes_in_group("btn"):
		n.connect("pressed", self, "_on_touch_pressed", [n.name])
		
		n.get_parent().modulate = Color.white
		if n.name == get_parent().name:
			n.get_parent().modulate = Color(.9, .9, .2, 1)

func _on_touch_pressed(action):
	get_tree().change_scene(str("res://scenes/", action ,".tscn"))

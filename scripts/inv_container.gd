extends Node
class_name InventoryContainer

var slots: Array[InventoryButton]

func _init(array_slots: Array[InventoryButton]) -> void:
	slots = array_slots

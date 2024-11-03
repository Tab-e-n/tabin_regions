extends Node
class_name AIBase


var controler : AIControler
var current_alignment : int


func start_turn(align : int):
	current_alignment = align

func think_normal():
	controler.CALL_turn_end = true

func think_mobilize():
	controler.CALL_turn_end = true

func think_bonus():
	controler.CALL_turn_end = true

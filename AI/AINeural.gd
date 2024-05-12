extends Node


var controler : AIControler
var controler_id : int
var current_alignment : int


func start_turn(align : int):
	current_alignment = align


func think_normal():
	pass

func think_mobilize():
	pass

func think_bonus():
	pass

extends Node


var controler : AIControler
var controler_id : int
var current_alignment : int


func think_normal():
	controler.CALL_turn_end = true

func think_mobilize():
	controler.CALL_turn_end = true

func think_bonus():
	controler.CALL_turn_end = true

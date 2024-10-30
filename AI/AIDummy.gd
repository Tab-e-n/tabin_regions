extends Node


var controler : AIControler
var controler_id : int
var current_alignment : int


func think_normal():
	controler.CALL_nothing = true

func think_mobilize():
	controler.CALL_nothing = true

func think_bonus():
	controler.CALL_nothing = true

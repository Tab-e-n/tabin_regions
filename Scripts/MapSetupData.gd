extends Node

var current_map_name : String = ""
var player_amount : int = 1
var default_ai_controler : int = AIControler.CONTROLER_DEFAULT

var aliances_amount : int = 0

var used_aligments : int = 0

var preset_alignments : Array[int] = []


func print_map_data():
	print(current_map_name)
	print("Players: ", player_amount)
	print("Default AI: ", default_ai_controler)
	print("Aliances: ", aliances_amount)
	print("Used Aligns: ", used_aligments)
	print("Preset Aligns: ", preset_alignments)


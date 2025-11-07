extends Area2D

var touched: bool = false

func _on_area_entered(area):
	if area.get_parent() is Player && touched == false:
		touched = true
		GameManager.do_victory()

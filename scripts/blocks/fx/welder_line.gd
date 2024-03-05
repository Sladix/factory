class_name WelderLine extends Line2D


func from_welder_group(group: Array):
	points = []
	for welder in group:
		if !welder.is_queued_for_deletion():
			add_point(welder.target_point())

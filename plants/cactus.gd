extends DefenderPlant
var water_output:int = 10

func on_plant_ready():
	health = 200
	water_usage = 20
	plant_stages = 1
	water_range = 5

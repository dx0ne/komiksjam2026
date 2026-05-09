extends Node

var master_list: Array[String] = ["aliens", "elivis", "bigfoot", "reptilians", "secret", "Area 51"]
#var master_list: Array[String] = ["AAAAA", "BBBBB", "CCCCC", "DDDDD", "EEEEE", "FFFF"]

var active_queue: Array[String] = []

var current_toilet_words:Array[String] = [];

func get_next_batch(count: int = 4) -> Array[String]:
	if active_queue.size() < count:
		_refill_queue()
	
	var batch: Array[String] = []
	for i in range(count):
		batch.append(active_queue.pop_front())
	
	return batch

func _refill_queue():
	active_queue = master_list.duplicate()
	active_queue.shuffle()

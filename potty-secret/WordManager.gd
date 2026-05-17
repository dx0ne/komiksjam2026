extends Node

var active_queue: Array[String] = []

var current_toilet_words:Array[String] = [];

var good_ending: bool = false
var shift_correct_illegal: int = 0


func pick_random_words(count: int) -> Array[String]:
	var pool: Array[String] = master_list.duplicate()
	pool.shuffle()
	var batch: Array[String] = []
	for i in range(mini(count, pool.size())):
		batch.append(pool[i])
	return batch


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

var templates: Array[String] = [
	"Resident {name} was overheard discussing {illegal_a} at a diner on Route 9. Two unidentified men joined the table before the discussion ended. Witnesses report the same conversation later turned to {illegal_b}.",
	"Subject {name} distributed printed material concerning {illegal_a}. Several copies were recovered from a public bulletin board. Field notes reference an unauthorized gathering about {illegal_b} the following evening.",
	"{name} attended a private meeting focused on {illegal_a}. Attendance was tracked through a side-door log. Recorded minutes include repeated praise for {illegal_b}.",
	"Search of the residence registered to {name} uncovered photographs alleged to depict {illegal_a}. The photographs were stored inside a hollowed dictionary. A separate folder held correspondence regarding {illegal_b}.",
	"Surveillance log shows {name} held a long phone call concerning {illegal_a} on Monday evening. The same line was used Tuesday for a discussion of {illegal_b}. A third call on Thursday referenced {illegal_c}. No business activity was logged in between.",
	"Postal interception of mail addressed to {name} recovered envelopes referencing {illegal_a}. A separate package included sketches related to {illegal_b}. A handwritten letter inside a magazine described {illegal_c}. None of the senders provided return addresses.",
	"Informant reports {name} hosted a basement gathering where attendees discussed {illegal_a}. Pamphlets concerning {illegal_b} were stacked near the entrance. A reel-to-reel film about {illegal_c} was screened after midnight. The basement window was covered with newsprint throughout.",
	"Wiretap transcript shows {name} placed a call regarding {illegal_a} on the first of the month. A follow-up call on the eighth concerned {illegal_b}. A third call before the twentieth referenced {illegal_c}. All three were placed from the same pay phone.",
	"Customs flagged a parcel sent to {name} containing photographs of {illegal_a}. A sealed envelope inside held audio recordings about {illegal_b}. Printed material referencing {illegal_c} was wrapped in plain butcher paper. The declared contents were listed as kitchen supplies.",
	"Bureau investigators believe {name} maintains active interest in {illegal_a}. Field notes record secondary involvement in {illegal_b}. Recent inquiries also concern {illegal_c}. No employer of record has been identified for the past nine months.",
	"School board complaint alleges {name} raised {illegal_a} during a parent meeting. Comparisons to {illegal_b} were drawn during the public comment period. Suggested reading material referenced {illegal_c}. Three parents filed signed statements the following week.",
	"Library records show {name} requested texts on {illegal_a}. The same card was used to check out periodicals concerning {illegal_b}. A reservation for microfilm referencing {illegal_c} was placed by phone. No materials have been returned.",
	"{name} was photographed at a roadside motel meeting three unidentified parties. The first party spoke at length about {illegal_a}. A second guest raised {illegal_b} during the meal. The third departed after a brief exchange concerning {illegal_c}.",
	"Workplace memo flags {name} for repeatedly raising {illegal_a} during shift breaks. Bulletins about {illegal_b} were found posted near the time clock. Typewritten notes on {illegal_c} were recovered from the supply closet. Two coworkers requested transfer to a different shift.",
	"Report mentions {illegal_a} literature distribution by subject {name}. Pamphlets were recovered from coin laundries and a public library reading room. A separate fold of papers concerning {illegal_b} was discovered in the same delivery bag.",
	"Bureau profile lists {name} among known sympathizers of {illegal_a}. Attendance records confirm participation in a regional conference on {illegal_b} last spring. Personal correspondence references an underground reading group focused on {illegal_c}. Tax filings for the group remain incomplete.",
	"Field office report identifies {name} as an organizer within the wider movement around {illegal_a}. The same report notes friendly correspondence with leaders associated with {illegal_b}. No formal employment has been recorded for the subject since 1962.",
	"Public records show {name} delivered an unticketed lecture on {illegal_a} at the community center. The advertised flyer also promised a Q&A regarding {illegal_b}. Attendance figures were not reported to local authorities.",
	"Informant identifies {name} as a vocal believer in {illegal_a}. The same source recalls a private statement of support for {illegal_b}. Subject has been observed distributing reading material on {illegal_c} outside the post office. None of the materials carry an author imprint.",
]

var master_list: Array[String] = [
	"aliens", "Elvis", "bigfoot", "reptilians", "Big Secret", "Area 51",
	"Roswell", "MKUltra", "Mothman", "chemtrails", "Illuminati",
	"UFOs", "the Grays", "flying saucers", "abductions",
	"Nessie", "chupacabra", "the Yeti",
	"Project Blue Book", "Dulce Base", "the Bermuda Triangle",
	"the Moon Landing", "Hollow Earth",
	"JFK", "the deep state", "Bilderberg", "New World Order", "Tupac",
]

var names: Array[String] = [
	"Frank Holloway",
	"Margaret Whitaker",
	"Earl Pemberton",
	"Linda Calloway",
	"Hank Doyle",
	"Bob Lazarus",
	"Stan Freedman",
	"J. Allen Hyneker",
	"Linda Howemoulton",
	"Erich von Donut",
	"Whit Strieberg",
	"J. Edna Hoover",
	"Buford Crumpacker",
	"Mildred Sneed",
	"Eustace Boggs",
	"Delbert Tubbs",
	"Norma Jean Pickens",
	"Cletus Crampton",
	"Elvis P. Reasley",
	"Marilyn O'Monroe",
	"Vincent J. F. Kennetty",
]

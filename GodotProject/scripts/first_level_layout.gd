extends RefCounted
## Shared first-chapter anchors. Distances are metres; assets keep their scale.
const REVISION := 5
const START := Vector3(10,.08,286)
const SCOUT := Vector3(12,.08,282)
const LOGGER := Vector3(14,.08,266)
const GATES := [Vector3(34,1.4,198),Vector3(34,1.4,122),Vector3(70,1.4,22)]
const AREAS := [
	Rect2(4,248,16,52), Rect2(18,252,20,8), Rect2(24,198,36,60),
	Rect2(30,180,8,20), Rect2(30,178,30,8), Rect2(52,164,8,20),
	Rect2(24,122,38,48), Rect2(30,104,8,20), Rect2(30,102,46,8),
	Rect2(68,74,8,34), Rect2(30,72,46,8), Rect2(30,18,10,60),
	Rect2(40,24,28,24), Rect2(30,18,42,8), Rect2(70,8,14,22)]
const ROUTE := [Vector3(10,0,286),Vector3(14,0,266),Vector3(14,0,256),
	Vector3(34,0,256),Vector3(34,0,238),Vector3(34,0,220),Vector3(34,0,198),
	Vector3(34,0,182),Vector3(56,0,182),Vector3(56,0,166),Vector3(34,0,162),
	Vector3(34,0,144),Vector3(34,0,122),Vector3(34,0,106),Vector3(72,0,106),
	Vector3(72,0,76),Vector3(34,0,76),Vector3(34,0,38),Vector3(38.5,0,38.5),
	Vector3(46,0,38),Vector3(53.5,0,38),Vector3(62.2,0,32),Vector3(48.8,0,30),
	Vector3(38.5,0,38.5),Vector3(34,0,38),Vector3(34,0,22),Vector3(70,0,22),Vector3(79,0,14)]

static func contains(at: Vector3) -> bool:
	if at.y < -.1 or at.y > 6: return false
	for area: Rect2 in AREAS:
		if area.grow(.05).has_point(Vector2(at.x,at.z)): return true
	return false

static func old_point(at: Vector3) -> Vector3:
	# Used only for migrating coordinates from the compact revision 4 map.
	if at.x < 22 and at.z >= 42: return at + Vector3(0,0,200)
	if at.x >= 68 and at.z > 30: return Vector3(34,at.y,60)
	if at.z >= 58: return at + Vector3(0,0,140)
	if at.z >= 42 and at.x < 68: return at + Vector3(0,0,80)
	return at

static func _safe_old_point(at: Vector3) -> Vector3:
	var result:=old_point(at)
	if contains(result): return result
	var nearest:=Vector2(result.x,result.z)
	var best:=INF
	for area: Rect2 in AREAS:
		var inner:=area.grow(-.65)
		var point:=Vector2(clampf(result.x,inner.position.x,inner.end.x),clampf(result.z,inner.position.y,inner.end.y))
		var distance:=point.distance_squared_to(Vector2(result.x,result.z))
		if distance<best: nearest=point; best=distance
	return Vector3(nearest.x,result.y,nearest.y)

static func migrate(data: Dictionary) -> void:
	if int(data.get("map_revision",0)) >= REVISION or data.get("village",{}).get("entered",false): return
	for record: Dictionary in [data.player,data.story]:
		var key := "position" if record == data.player else "lu_position"
		var p: Array = record[key]
		var at := _safe_old_point(Vector3(p[0],p[1],p[2]))
		record[key] = [at.x,at.y,at.z]
	for id in data.get("encounter",{}).get("active",{}):
		var record: Dictionary = data.encounter.active[id]
		for key in ["position","patrol","last_seen"]:
			var p: Array = record[key]
			if key == "last_seen" and p == [0,0,0]: continue
			var at := _safe_old_point(Vector3(p[0],p[1],p[2]))
			if id == "door_ambusher" or (id == "office_guard" and int(data.encounter.get("revision",1))<2): at = Vector3(34,.08,118.5)
			record[key] = [at.x,at.y,at.z]
	data.map_revision = REVISION

extends Node3D
## Explicit gameplay shell queue. Cinematic effects never enter this controller.
const Explosion = preload("res://scripts/explosion_effect.gd")
const MAX_ACTIVE := 6
var main: Node3D
var events: Array[Dictionary] = []
var impact_count := 0
var next_id := 0

func queue_strike(at: Vector3, radius: float = 5.0, damage: float = 35.0, harmful: bool = false) -> int:
	if main.mode != "playing" or events.size() >= MAX_ACTIVE or not at.is_finite() or not is_finite(radius) or not is_finite(damage): return -1
	var effect := Explosion.new()
	add_child(effect)
	effect.global_position = at
	next_id += 1
	events.append({"id":next_id,"effect":effect,"age":-Explosion.LEAD_SECONDS,"radius":clampf(radius,0.1,12.0),"damage":clampf(damage,0,100),"harmful":harmful,"impacted":false})
	effect.sample(-Explosion.LEAD_SECONDS)
	return next_id

func _process(delta: float) -> void:
	if main.mode in ["paused","journal","dialogue"]:
		for event in events: event.effect.sound.stream_paused = true
		return
	if main.mode != "playing":
		clear()
		return
	advance(delta)

func advance(delta: float) -> void:
	for index in range(events.size()-1,-1,-1):
		var event := events[index]
		event.age += delta
		event.effect.sound.stream_paused = false
		if event.age >= 0 and not event.impacted:
			event.impacted = true
			impact_count += 1
			event.effect.play_impact()
			if event.harmful: apply_damage(event.effect.global_position, event.radius, event.damage)
		event.effect.sample(event.age)
		if event.age >= Explosion.DURATION:
			event.effect.cancel()
			event.effect.free()
			events.remove_at(index)

func apply_damage(at: Vector3, radius: float, maximum: float) -> void:
	if main.mode != "playing": return
	for actor in [main.player] + main.guards:
		if not is_instance_valid(actor) or (actor != main.player and actor.state == "dead"): continue
		var target: Vector3 = actor.global_position + Vector3.UP*0.85
		var distance := at.distance_to(target)
		if distance >= radius: continue
		var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.25,target,1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		actor.take_damage(maximum*(1.0-distance/radius))

func clear() -> void:
	for event in events:
		if is_instance_valid(event.effect):
			event.effect.cancel()
			event.effect.free()
	events.clear()

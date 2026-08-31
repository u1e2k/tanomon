class_name LiveRanchBackground
extends Node3D

## タイトル画面用の3Dライブ牧場背景
## モンスターが牧場を歩き回り、カメラがゆっくり旋回・追従します

@export var monster_count: int = 4
@export var ranch_radius: float = 10.0
@export var camera_orbit_speed: float = 0.05

@onready var camera_pivot: Node3D = $CameraPivot
@onready var monsters_container: Node3D = $MonstersContainer

var _monsters: Array[Dictionary] = [] # Array of {node: ModularMonster, target: Vector3, state: int, timer: float}
const STATE_IDLE = 0
const STATE_WALK = 1

func _ready() -> void:
	_spawn_ranch_monsters()

func _process(delta: float) -> void:
	# カメラの緩やかな旋回
	if camera_pivot:
		camera_pivot.rotation.y += camera_orbit_speed * delta
	
	# モンスターたちのAI挙動
	for m in _monsters:
		var node: ModularMonster = m["node"]
		if not is_instance_valid(node):
			continue
		
		m["timer"] -= delta
		
		if m["state"] == STATE_IDLE:
			if m["timer"] <= 0.0:
				# 歩行状態へ遷移
				m["state"] = STATE_WALK
				m["timer"] = randf_range(3.0, 7.0)
				m["target"] = _get_random_ranch_pos()
				node.play_animation("walk")
		elif m["state"] == STATE_WALK:
			var to_target: Vector3 = m["target"] - node.position
			to_target.y = 0
			var dist := to_target.length()
			
			if dist < 0.2 or m["timer"] <= 0.0:
				# 待機状態へ遷移
				m["state"] = STATE_IDLE
				m["timer"] = randf_range(2.0, 5.0)
				node.play_animation("idle")
			else:
				var move_dir := to_target.normalized()
				node.position += move_dir * 1.5 * delta
				# 進行方向を向く
				var target_rot := atan2(move_dir.x, move_dir.z)
				node.rotation.y = lerp_angle(node.rotation.y, target_rot, 8.0 * delta)

func _spawn_ranch_monsters() -> void:
	_monsters.clear()
	var modular_scene: PackedScene = preload("res://scenes/monster/ModularMonster.tscn")
	var ids := MonsterDatabase.get_all_registered_ids()
	if ids.is_empty():
		ids = range(1, 501)
	
	for i in range(monster_count):
		var monster_node: ModularMonster = modular_scene.instantiate() as ModularMonster
		monsters_container.add_child(monster_node)
		
		var random_id: int = ids.pick_random() if not ids.is_empty() else (i + 1)
		var data: MonsterData = MonsterDatabase.get_monster_data(random_id)
		
		if data:
			monster_node.assemble(data)
			
		var spawn_pos := _get_random_ranch_pos()
		monster_node.position = spawn_pos
		monster_node.rotation.y = randf_range(0, TAU)
		
		_monsters.append({
			"node": monster_node,
			"target": spawn_pos,
			"state": STATE_IDLE,
			"timer": randf_range(1.0, 4.0)
		})

func _get_random_ranch_pos() -> Vector3:
	var angle := randf_range(0, TAU)
	var r := randf_range(1.0, ranch_radius)
	return Vector3(cos(angle) * r, 0, sin(angle) * r)

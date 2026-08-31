extends Node

## ゲーム全体の状態、セーブデータ、アクティブモンスターを管理するシングルトン

signal day_advanced(current_day: int, time_of_day: String)
signal active_monster_changed
signal stats_updated

const SAVE_PATH: String = "user://savegame.json"

# 時間帯の定義
const TIMES_OF_DAY: Array[String] = ["あさ", "ひる", "ゆうがた", "よる"]

# プレイヤー進行状況
var gold: int = 500
var current_day: int = 1
var time_index: int = 0 # 0: 朝, 1: 昼, 2: 夕, 3: 夜

# 所持アイテム (アイテム名 -> 個数)
var inventory: Dictionary = {
	"おにく": 5,
	"さかな": 3,
	"きのみ": 8,
	"まほう草": 2,
	"進化のオーブ": 1
}

# 育成中モンスターのインスタンスデータ
var active_monster: Dictionary = {
	"monster_id": 1,        # MonsterData の ID (1〜500)
	"nickname": "ドラコ",
	"level": 1,
	"exp": 0,
	"max_hp": 60,
	"current_hp": 60,
	"max_mp": 25,
	"current_mp": 25,
	"attack": 18,
	"defense": 14,
	"magic": 12,
	"speed": 12,
	
	# バイオリズム (0〜100)
	"hunger": 80,          # 100=満腹, 0=飢餓
	"energy": 90,          # 100=元気, 0=過労
	"affection": 70,       # なつき度・機嫌
	
	# 派遣状態
	"is_dispatched": false,
	"dispatch_destination": "",
	"dispatch_return_day": 0,
	"dispatch_return_time": 0
}

func _ready() -> void:
	# 初期データのセットアップ
	if not FileAccess.file_exists(SAVE_PATH):
		_init_default_monster(1) # 初期パートナー: No.001
	else:
		load_game()

func _init_default_monster(monster_id: int) -> void:
	var data := MonsterDatabase.get_monster_data(monster_id)
	if data:
		active_monster["monster_id"] = data.id
		active_monster["nickname"] = data.monster_name
		active_monster["max_hp"] = data.base_max_hp
		active_monster["current_hp"] = data.base_max_hp
		active_monster["max_mp"] = data.base_max_mp
		active_monster["current_mp"] = data.base_max_mp
		active_monster["attack"] = data.base_attack
		active_monster["defense"] = data.base_defense
		active_monster["magic"] = data.base_magic
		active_monster["speed"] = data.base_speed
		active_monster["hunger"] = 80
		active_monster["energy"] = 90
		active_monster["affection"] = 70

## 時間帯を進める（朝 -> 昼 -> 夕 -> 夜 -> 翌日の朝）
func advance_time() -> void:
	time_index += 1
	if time_index >= TIMES_OF_DAY.size():
		time_index = 0
		current_day += 1
	
	# 自然なバイオリズム変動 (空腹と疲労の進行)
	var data := MonsterDatabase.get_monster_data(active_monster["monster_id"])
	var hunger_rate := data.hunger_rate if data else 1.0
	var energy_rate := data.energy_rate if data else 1.0
	
	active_monster["hunger"] = clampi(int(active_monster["hunger"] - 8 * hunger_rate), 0, 100)
	active_monster["energy"] = clampi(int(active_monster["energy"] - 5 * energy_rate), 0, 100)
	
	# 飢餓・過労による機嫌低下
	if active_monster["hunger"] < 20 or active_monster["energy"] < 20:
		active_monster["affection"] = clampi(active_monster["affection"] - 5, 0, 100)
	
	day_advanced.emit(current_day, get_current_time_string())
	stats_updated.emit()
	
	# おつかい派遣の帰還チェック
	_check_dispatch_return()

func get_current_time_string() -> String:
	return "%d日目 (%s)" % [current_day, TIMES_OF_DAY[time_index]]

## エサやり
func feed_monster(item_name: String) -> Dictionary:
	if not inventory.has(item_name) or inventory[item_name] <= 0:
		return {"success": false, "message": "アイテムがありません。"}
	
	inventory[item_name] -= 1
	
	var data := MonsterDatabase.get_monster_data(active_monster["monster_id"])
	var fav_food_idx := data.favorite_food_type if data else 0
	var food_types := ["おにく", "さかな", "きのみ", "まほう草"]
	var is_fav: bool = (item_name == food_types[clampi(fav_food_idx, 0, 3)])
	
	var hunger_gain: int = 35 if is_fav else 25
	var affection_gain: int = 15 if is_fav else 6
	
	active_monster["hunger"] = clampi(int(active_monster["hunger"]) + hunger_gain, 0, 100)
	active_monster["affection"] = clampi(int(active_monster["affection"]) + affection_gain, 0, 100)
	
	stats_updated.emit()
	
	var msg: String = "%s を食べた！ %s" % [item_name, ("大好物でおおよろこび！" if is_fav else "お腹がいっぱいになった。")]
	return {"success": true, "message": msg, "is_fav": is_fav}

## トレーニング
func train_monster(stat_type: String) -> Dictionary:
	if int(active_monster["energy"]) < 15:
		return {"success": false, "message": "疲れていてトレーニングできません！休ませてください。"}
	if int(active_monster["hunger"]) < 10:
		return {"success": false, "message": "お腹がすいて力が出ません！ごはんをあげてください。"}
	
	active_monster["energy"] = clampi(int(active_monster["energy"]) - 20, 0, 100)
	active_monster["hunger"] = clampi(int(active_monster["hunger"]) - 15, 0, 100)
	
	var gain: int = randi_range(2, 4)
	var stat_name: String = ""
	
	match stat_type:
		"hp":
			active_monster["max_hp"] = int(active_monster["max_hp"]) + gain * 2
			active_monster["current_hp"] = int(active_monster["current_hp"]) + gain * 2
			stat_name = "HP"
		"mp":
			active_monster["max_mp"] = int(active_monster["max_mp"]) + gain * 2
			active_monster["current_mp"] = int(active_monster["current_mp"]) + gain * 2
			stat_name = "MP"
		"atk":
			active_monster["attack"] = int(active_monster["attack"]) + gain
			stat_name = "こうげき"
		"def":
			active_monster["defense"] = int(active_monster["defense"]) + gain
			stat_name = "ぼうぎょ"
		"mag":
			active_monster["magic"] = int(active_monster["magic"]) + gain
			stat_name = "まりょく"
		"spd":
			active_monster["speed"] = int(active_monster["speed"]) + gain
			stat_name = "すばやさ"
			
	# EXP加算
	add_exp(15)
	
	advance_time()
	stats_updated.emit()
	return {"success": true, "message": "%s のとっくん！ %s が +%d 上がった！" % [stat_name, stat_name, gain]}

## 休憩・睡眠
func rest_monster() -> void:
	active_monster["energy"] = clampi(int(active_monster["energy"]) + 45, 0, 100)
	active_monster["current_hp"] = active_monster["max_hp"]
	active_monster["current_mp"] = active_monster["max_mp"]
	advance_time()
	stats_updated.emit()

## 経験値追加 & レベルアップ
func add_exp(amount: int) -> bool:
	active_monster["exp"] = int(active_monster["exp"]) + amount
	var req_exp: int = int(active_monster["level"]) * 25
	var leveled_up: bool = false
	
	while int(active_monster["exp"]) >= req_exp:
		active_monster["exp"] = int(active_monster["exp"]) - req_exp
		active_monster["level"] = int(active_monster["level"]) + 1
		active_monster["max_hp"] = int(active_monster["max_hp"]) + 5
		active_monster["max_mp"] = int(active_monster["max_mp"]) + 3
		active_monster["attack"] = int(active_monster["attack"]) + 2
		active_monster["defense"] = int(active_monster["defense"]) + 2
		active_monster["magic"] = int(active_monster["magic"]) + 2
		active_monster["speed"] = int(active_monster["speed"]) + 2
		active_monster["current_hp"] = active_monster["max_hp"]
		active_monster["current_mp"] = active_monster["max_mp"]
		leveled_up = true
		req_exp = int(active_monster["level"]) * 25
		
		# 進化チェック
		_check_evolution()
		
	return leveled_up

## 進化チェック
func _check_evolution() -> void:
	var data := MonsterDatabase.get_monster_data(active_monster["monster_id"])
	if not data or data.evolution_ids.is_empty():
		return
	
	if active_monster["level"] >= data.evolution_level_requirement:
		var next_id: int = data.evolution_ids[0]
		var next_data := MonsterDatabase.get_monster_data(next_id)
		if next_data:
			active_monster["monster_id"] = next_data.id
			active_monster["nickname"] = next_data.monster_name
			print("[GameManager] EVOLUTION! New form: %s (No.%03d)" % [next_data.monster_name, next_data.id])

## おつかい派遣チェック
func _check_dispatch_return() -> void:
	if not active_monster["is_dispatched"]:
		return
	
	var is_time_reached := false
	if current_day > active_monster["dispatch_return_day"]:
		is_time_reached = true
	elif current_day == active_monster["dispatch_return_day"] and time_index >= active_monster["dispatch_return_time"]:
		is_time_reached = true
		
	if is_time_reached:
		active_monster["is_dispatched"] = false
		print("[GameManager] Monster returned from dispatch!")

## セーブ & ロード
func save_game() -> void:
	var save_dict := {
		"gold": gold,
		"current_day": current_day,
		"time_index": time_index,
		"inventory": inventory,
		"active_monster": active_monster
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_str := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_str) == OK and json.data is Dictionary:
		var data: Dictionary = json.data
		gold = data.get("gold", gold)
		current_day = data.get("current_day", current_day)
		time_index = data.get("time_index", time_index)
		inventory = data.get("inventory", inventory)
		active_monster = data.get("active_monster", active_monster)
		stats_updated.emit()

func reset_game_state() -> void:
	gold = 500
	current_day = 1
	time_index = 0
	inventory = {
		"おにく": 5,
		"さかな": 3,
		"きのみ": 8,
		"まほう草": 2,
		"進化のオーブ": 1
	}
	_init_default_monster(1)
	stats_updated.emit()

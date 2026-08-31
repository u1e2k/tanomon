class_name DispatchManager
extends RefCounted

## おつかい・冒険派遣システムの管理ロジック

static func get_areas() -> Array[Dictionary]:
	return [
		{
			"id": "forest",
			"name": "はじまりの森",
			"description": "木の実や薬草が豊富な緑豊かな森。初心者向け。",
			"req_level": 1,
			"duration": 1,
			"element": MonsterData.ElementType.NATURE,
			"gold": 50,
			"exp": 30,
			"items": ["きのみ", "きのみ", "まほう草"]
		},
		{
			"id": "lake",
			"name": "静寂の湖畔",
			"description": "新鮮な魚が獲れる水辺。水系モンスターが得意。",
			"req_level": 5,
			"duration": 2,
			"element": MonsterData.ElementType.WATER,
			"gold": 120,
			"exp": 70,
			"items": ["さかな", "さかな", "きのみ"]
		},
		{
			"id": "volcano",
			"name": "灼熱の火山洞窟",
			"description": "強力なモンスターが潜む危険地帯。肉や鉱石が眠る。",
			"req_level": 10,
			"duration": 2,
			"element": MonsterData.ElementType.FIRE,
			"gold": 250,
			"exp": 150,
			"items": ["おにく", "おにく", "進化のオーブ"]
		},
		{
			"id": "ruins",
			"name": "古代の浮遊遺跡",
			"description": "古代文明の秘宝が眠る伝説の遺跡。難易度高。",
			"req_level": 18,
			"duration": 3,
			"element": MonsterData.ElementType.LIGHT,
			"gold": 500,
			"exp": 300,
			"items": ["まほう草", "進化のオーブ", "おにく"]
		}
	]

## 派遣実行
static func start_dispatch(area_id: String) -> bool:
	var area: Dictionary = {}
	for a in get_areas():
		if a["id"] == area_id:
			area = a
			break
	if area.is_empty():
		return false
	
	GameManager.active_monster["is_dispatched"] = true
	GameManager.active_monster["dispatch_destination"] = area["name"]
	
	# 帰還日時の計算
	var duration: int = int(area["duration"])
	var target_time: int = GameManager.time_index + duration
	var target_day: int = GameManager.current_day + (target_time / 4)
	var final_time: int = target_time % 4
	
	GameManager.active_monster["dispatch_return_day"] = target_day
	GameManager.active_monster["dispatch_return_time"] = final_time
	
	return true

## 派遣結果の計算
static func calculate_result(area_id: String) -> Dictionary:
	var area: Dictionary = {}
	for a in get_areas():
		if a["id"] == area_id:
			area = a
			break
	if area.is_empty():
		return {"success": false, "message": "不明なエリアです。"}
	
	var data: MonsterData = MonsterDatabase.get_monster_data(int(GameManager.active_monster["monster_id"]))
	var current_level: int = int(GameManager.active_monster["level"])
	
	# 成功率算出 (基礎60% + レベル差ボーナス + 属性ボーナス)
	var base_chance: int = 60
	base_chance += (current_level - int(area["req_level"])) * 5
	if data and data.element == int(area["element"]):
		base_chance += 20
	base_chance = clampi(base_chance, 20, 95)
	
	var roll: int = randi_range(1, 100)
	var success: bool = (roll <= base_chance)
	
	var gained_gold: int = 0
	var gained_exp: int = 0
	var gained_items: Array[String] = []
	
	if success:
		gained_gold = int(area["gold"]) + randi_range(-10, 20)
		gained_exp = int(area["exp"]) + randi_range(-5, 15)
		var item_pool: Array = area["items"]
		if not item_pool.is_empty():
			var item: String = str(item_pool.pick_random())
			gained_items.append(item)
			GameManager.inventory[item] = int(GameManager.inventory.get(item, 0)) + 1
			
		GameManager.gold += gained_gold
		GameManager.add_exp(gained_exp)
		return {
			"success": true,
			"area_name": area["name"],
			"gold": gained_gold,
			"exp": gained_exp,
			"items": gained_items,
			"message": "「%s」のおつかいから無事に帰還しました！" % area["name"]
		}
	else:
		# 失敗時も少量の経験値
		gained_exp = int(area["exp"]) / 3
		GameManager.add_exp(gained_exp)
		return {
			"success": false,
			"area_name": area["name"],
			"gold": 0,
			"exp": gained_exp,
			"items": [],
			"message": "「%s」のおつかいは難しくて途中で戻ってきました..." % area["name"]
		}

class_name BattleManager
extends RefCounted

## 属性相性テーブル
## 攻撃側 -> 防御側 -> 倍率
static func get_element_multiplier(atk_elem: MonsterData.ElementType, def_elem: MonsterData.ElementType) -> float:
	if atk_elem == MonsterData.ElementType.NONE or def_elem == MonsterData.ElementType.NONE:
		return 1.0
	
	# 火 > 草 > 水 > 火
	if atk_elem == MonsterData.ElementType.FIRE and def_elem == MonsterData.ElementType.NATURE:
		return 1.5
	if atk_elem == MonsterData.ElementType.NATURE and def_elem == MonsterData.ElementType.WATER:
		return 1.5
	if atk_elem == MonsterData.ElementType.WATER and def_elem == MonsterData.ElementType.FIRE:
		return 1.5
		
	# 雷 > 風 > 土 > 雷
	if atk_elem == MonsterData.ElementType.ELECTRIC and def_elem == MonsterData.ElementType.WIND:
		return 1.5
	if atk_elem == MonsterData.ElementType.WIND and def_elem == MonsterData.ElementType.EARTH:
		return 1.5
	if atk_elem == MonsterData.ElementType.EARTH and def_elem == MonsterData.ElementType.ELECTRIC:
		return 1.5
		
	# 光 ⇔ 闇
	if (atk_elem == MonsterData.ElementType.LIGHT and def_elem == MonsterData.ElementType.DARK) or \
	   (atk_elem == MonsterData.ElementType.DARK and def_elem == MonsterData.ElementType.LIGHT):
		return 1.5
		
	# 不利属性 (0.75倍)
	if atk_elem == MonsterData.ElementType.FIRE and def_elem == MonsterData.ElementType.WATER:
		return 0.75
	if atk_elem == MonsterData.ElementType.WATER and def_elem == MonsterData.ElementType.NATURE:
		return 0.75
	if atk_elem == MonsterData.ElementType.NATURE and def_elem == MonsterData.ElementType.FIRE:
		return 0.75
		
	return 1.0

## ダメージ計算
static func calculate_damage(attacker_stats: Dictionary, defender_stats: Dictionary, is_magic: bool, atk_elem: MonsterData.ElementType, def_elem: MonsterData.ElementType) -> Dictionary:
	var atk_power: float = float(attacker_stats.get("magic" if is_magic else "attack", 10))
	var def_power: float = float(defender_stats.get("magic" if is_magic else "defense", 10))
	
	var base_dmg: float = maxf(1.0, (atk_power * 1.5) - (def_power * 0.6))
	var mult: float = get_element_multiplier(atk_elem, def_elem)
	var random_factor: float = randf_range(0.9, 1.1)
	
	var final_damage: int = int(round(base_dmg * mult * random_factor))
	var is_critical: bool = (randi_range(1, 100) <= 10)
	if is_critical:
		final_damage = int(round(final_damage * 1.5))
		
	return {
		"damage": max(1, final_damage),
		"multiplier": mult,
		"is_critical": is_critical,
		"is_effective": mult > 1.0,
		"is_resisted": mult < 1.0
	}

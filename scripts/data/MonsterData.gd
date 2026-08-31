class_name MonsterData
extends Resource

## 属性タイプ
enum ElementType {
	NONE = 0,
	FIRE = 1,      ## 火
	WATER = 2,     ## 水
	NATURE = 3,    ## 草木・自然
	ELECTRIC = 4,  ## 雷・電気
	EARTH = 5,     ## 土・岩
	WIND = 6,      ## 風
	LIGHT = 7,     ## 光・聖
	DARK = 8       ## 闇・邪
}

## 成長タイプ
enum GrowthType {
	EARLY = 0,    ## 早熟
	NORMAL = 1,   ## 普通
	LATE = 2      ## 晩成
}

## 基本識別情報
@export_group("Basic Info")
@export var id: int = 1
@export var monster_name: String = "モンスター"
@export_multiline var description: String = "未確認のモンスター。"
@export var element: ElementType = ElementType.NONE
@export var growth_type: GrowthType = GrowthType.NORMAL

## 3Dモジュラー構成情報
@export_group("3D Modular Visuals")
## ベース素体シーンのファイルパス (例: "res://assets/models/bases/base_quadruped.tscn")
@export_file("*.tscn", "*.scn", "*.gltf", "*.glb") var base_model_path: String = ""
## アタッチパーツのファイルパス辞書 (スロット名 -> シーンパス)
## 例: {"head": "res://assets/models/parts/horn_single.tscn", "back": "res://assets/models/parts/wings_dragon.tscn"}
@export var parts_paths: Dictionary = {}
## パレットテクスチャ内のインデックス行 (0〜N)
@export var palette_index: int = 0
## モンスターの3Dスケール比率
@export var model_scale: Vector3 = Vector3.ONE

## 基礎ステータス (Lv1初期値)
@export_group("Base Stats")
@export var base_max_hp: int = 50
@export var base_max_mp: int = 20
@export var base_attack: int = 15
@export var base_defense: int = 12
@export var base_magic: int = 10
@export var base_speed: int = 10

## 行動・バイオリズム特性
@export_group("Behavior & Rhythms")
@export var hunger_rate: float = 1.0     ## 空腹進行速度係数
@export var energy_rate: float = 1.0     ## 疲労進行速度係数
@export var favorite_food_type: int = 0  ## 好みのエサタイプ

## 進化データ
@export_group("Evolution")
@export var evolution_ids: Array[int] = []
@export var evolution_level_requirement: int = 20

## デバッグ・サマリー表示用
func get_summary_text() -> String:
	return "No.%03d %s [%s] HP:%d ATK:%d DEF:%d" % [
		id,
		monster_name,
		ElementType.keys()[element],
		base_max_hp,
		base_attack,
		base_defense
	]

class_name BattleScene
extends Control

## 1vs1 3Dモンスターコマンドバトルシーン

@onready var player_monster_3d: ModularMonster = %PlayerMonster3D
@onready var enemy_monster_3d: ModularMonster = %EnemyMonster3D
@onready var player_pivot: Node3D = %PlayerPivot
@onready var enemy_pivot: Node3D = %EnemyPivot

# UI
@onready var player_name_label: Label = %PlayerNameLabel
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_mp_bar: ProgressBar = %PlayerMPBar
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_mp_label: Label = %PlayerMPLabel

@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_hp_label: Label = %EnemyHPLabel

@onready var log_label: Label = %LogLabel
@onready var commands_container: HBoxContainer = %CommandsContainer

# コマンドボタン
@onready var btn_attack: Button = %BtnAttack
@onready var btn_skill: Button = %BtnSkill
@onready var btn_defend: Button = %BtnDefend
@onready var btn_run: Button = %BtnRun

# リザルトパネル
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_title_label: Label = %ResultTitleLabel
@onready var result_desc_label: Label = %ResultDescLabel
@onready var btn_return_ranch: Button = %BtnReturnRanch

# 内部戦闘データ
var _enemy_data: MonsterData = null
var _enemy_stats: Dictionary = {}
var _is_player_turn: bool = true
var _player_defending: bool = false
var _enemy_defending: bool = false
var _battle_over: bool = false

func _ready() -> void:
	if has_node("%SafeMarginContainer"):
		SafeAreaHelper.apply_safe_area(%SafeMarginContainer, 52, 8)
	
	_init_battle()
	_connect_signals()

func _connect_signals() -> void:
	btn_attack.pressed.connect(_on_attack_pressed)
	btn_skill.pressed.connect(_on_skill_pressed)
	btn_defend.pressed.connect(_on_defend_pressed)
	btn_run.pressed.connect(_on_run_pressed)
	btn_return_ranch.pressed.connect(_on_return_ranch_pressed)

func _init_battle() -> void:
	result_panel.visible = false
	commands_container.visible = true
	_battle_over = false
	
	# プレイヤーモンスターの初期化
	var p_id: int = GameManager.active_monster["monster_id"]
	var p_data := MonsterDatabase.get_monster_data(p_id)
	if p_data:
		player_monster_3d.assemble(p_data)
		player_monster_3d.play_animation("idle")
	
	# 敵モンスターの選出 (ランダム)
	var enemy_id := randi_range(1, 500)
	_enemy_data = MonsterDatabase.get_monster_data(enemy_id)
	if _enemy_data:
		enemy_monster_3d.assemble(_enemy_data)
		enemy_monster_3d.play_animation("idle")
		
		# プレイヤーのレベルに応じた敵ステータススケーリング
		var p_lv: int = GameManager.active_monster["level"]
		_enemy_stats = {
			"name": _enemy_data.monster_name,
			"level": max(1, p_lv + randi_range(-1, 2)),
			"max_hp": _enemy_data.base_max_hp + p_lv * 10,
			"current_hp": _enemy_data.base_max_hp + p_lv * 10,
			"max_mp": _enemy_data.base_max_mp + p_lv * 5,
			"current_mp": _enemy_data.base_max_mp + p_lv * 5,
			"attack": _enemy_data.base_attack + p_lv * 2,
			"defense": _enemy_data.base_defense + p_lv * 2,
			"magic": _enemy_data.base_magic + p_lv * 2,
			"speed": _enemy_data.base_speed + p_lv * 2,
		}
	
	_update_bars()
	_set_log("野生の %s (Lv.%d) があらわれた！" % [_enemy_stats["name"], _enemy_stats["level"]])

func _update_bars() -> void:
	var m: Dictionary = GameManager.active_monster
	player_name_label.text = "%s Lv.%d" % [m["nickname"], m["level"]]
	player_hp_bar.max_value = m["max_hp"]
	player_hp_bar.value = m["current_hp"]
	player_hp_label.text = "%d / %d" % [m["current_hp"], m["max_hp"]]
	
	player_mp_bar.max_value = m["max_mp"]
	player_mp_bar.value = m["current_mp"]
	player_mp_label.text = "%d / %d" % [m["current_mp"], m["max_mp"]]
	
	enemy_name_label.text = "%s Lv.%d" % [_enemy_stats["name"], _enemy_stats["level"]]
	enemy_hp_bar.max_value = _enemy_stats["max_hp"]
	enemy_hp_bar.value = _enemy_stats["current_hp"]
	enemy_hp_label.text = "%d / %d" % [_enemy_stats["current_hp"], _enemy_stats["max_hp"]]

func _set_log(text: String) -> void:
	log_label.text = text

# --- プレイヤーコマンド ---
func _on_attack_pressed() -> void:
	if not _is_player_turn or _battle_over:
		return
	_execute_player_action(false)

func _on_skill_pressed() -> void:
	if not _is_player_turn or _battle_over:
		return
	if GameManager.active_monster["current_mp"] < 8:
		RetroSoundPlayer.play_cancel()
		_set_log("MPが足りません！")
		return
	GameManager.active_monster["current_mp"] -= 8
	_execute_player_action(true)

func _on_defend_pressed() -> void:
	if not _is_player_turn or _battle_over:
		return
	RetroSoundPlayer.play_confirm()
	_player_defending = true
	# MP小回復
	GameManager.active_monster["current_mp"] = mini(int(GameManager.active_monster["current_mp"]) + 4, int(GameManager.active_monster["max_hp"]))
	_set_log("%s は身を守っている！" % GameManager.active_monster["nickname"])
	_update_bars()
	_is_player_turn = false
	commands_container.visible = false
	await get_tree().create_timer(0.8).timeout
	_execute_enemy_turn()

func _on_run_pressed() -> void:
	RetroSoundPlayer.play_cancel()
	_set_log("バトルから逃げ出した！")
	commands_container.visible = false
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ranch/RanchScene.tscn")

func _execute_player_action(is_skill: bool) -> void:
	_is_player_turn = false
	commands_container.visible = false
	_player_defending = false
	RetroSoundPlayer.play_confirm()
	
	var p_data := MonsterDatabase.get_monster_data(GameManager.active_monster["monster_id"])
	var p_elem: MonsterData.ElementType = p_data.element if p_data else MonsterData.ElementType.NONE
	var e_elem: MonsterData.ElementType = _enemy_data.element if _enemy_data else MonsterData.ElementType.NONE
	
	# 攻撃アニメーション
	player_monster_3d.play_animation("walk")
	
	var res := BattleManager.calculate_damage(
		GameManager.active_monster,
		_enemy_stats,
		is_skill,
		(p_elem if is_skill else MonsterData.ElementType.NONE),
		e_elem
	)
	
	var dmg: int = res["damage"]
	if _enemy_defending:
		dmg = max(1, dmg / 2)
	
	_enemy_stats["current_hp"] = maxi(0, _enemy_stats["current_hp"] - dmg)
	
	var action_name := "属性特技" if is_skill else "こうげき"
	var eff_text := ""
	if res["is_effective"]:
		eff_text = "【こうかばつぐん！】"
	elif res["is_resisted"]:
		eff_text = "【いまひとつのようだ...】"
	if res["is_critical"]:
		eff_text += "【会心の一撃！】"
		
	_set_log("%s の %s！ %s %d のダメージを与えた！" % [
		GameManager.active_monster["nickname"],
		action_name,
		eff_text,
		dmg
	])
	
	_update_bars()
	
	await get_tree().create_timer(1.2).timeout
	player_monster_3d.play_animation("idle")
	
	if _enemy_stats["current_hp"] <= 0:
		_on_battle_won()
	else:
		_execute_enemy_turn()

func _execute_enemy_turn() -> void:
	_enemy_defending = false
	
	# 敵AI (MPがあれば30%の確率で特技、それ以外は通常攻撃)
	var use_skill: bool = (int(_enemy_stats["current_mp"]) >= 8 and randf() < 0.35)
	if use_skill:
		_enemy_stats["current_mp"] = int(_enemy_stats["current_mp"]) - 8
	
	var p_data: MonsterData = MonsterDatabase.get_monster_data(int(GameManager.active_monster["monster_id"]))
	var p_elem: MonsterData.ElementType = p_data.element if p_data else MonsterData.ElementType.NONE
	var e_elem: MonsterData.ElementType = _enemy_data.element if _enemy_data else MonsterData.ElementType.NONE
	
	enemy_monster_3d.play_animation("walk")
	
	var res: Dictionary = BattleManager.calculate_damage(
		_enemy_stats,
		GameManager.active_monster,
		use_skill,
		(e_elem if use_skill else MonsterData.ElementType.NONE),
		p_elem
	)
	
	var dmg: int = int(res["damage"])
	if _player_defending:
		dmg = max(1, dmg / 2)
		
	GameManager.active_monster["current_hp"] = maxi(0, int(GameManager.active_monster["current_hp"]) - dmg)
	
	var action_name: String = "属性特技" if use_skill else "こうげき"
	var eff_text: String = ""
	if bool(res["is_effective"]):
		eff_text = "【こうかばつぐん！】"
	
	_set_log("敵の %s の %s！ %s %d のダメージを受けた！" % [
		_enemy_stats["name"],
		action_name,
		eff_text,
		dmg
	])
	
	_update_bars()
	
	await get_tree().create_timer(1.2).timeout
	enemy_monster_3d.play_animation("idle")
	
	if int(GameManager.active_monster["current_hp"]) <= 0:
		_on_battle_lost()
	else:
		_start_player_turn()

func _start_player_turn() -> void:
	_is_player_turn = true
	commands_container.visible = true
	_set_log("あなたのターンです。コマンドを選択してください。")

func _on_battle_won() -> void:
	_battle_over = true
	RetroSoundPlayer.play_confirm()
	var gained_exp: int = int(_enemy_stats["level"]) * 20 + 30
	var gained_gold: int = int(_enemy_stats["level"]) * 15 + 40
	
	var lv_up: bool = GameManager.add_exp(gained_exp)
	GameManager.gold += gained_gold
	
	result_panel.visible = true
	result_title_label.text = "★ バトル勝利！ ★"
	var msg: String = "敵の %s を倒した！\n獲得: +%d G, EXP +%d" % [_enemy_stats["name"], gained_gold, gained_exp]
	if lv_up:
		msg += "\n★ %s は レベル %d に上がった！" % [GameManager.active_monster["nickname"], GameManager.active_monster["level"]]
	result_desc_label.text = msg

func _on_battle_lost() -> void:
	_battle_over = true
	RetroSoundPlayer.play_cancel()
	result_panel.visible = true
	result_title_label.text = "敗北..."
	result_desc_label.text = "%s は力尽きてしまった...\n牧場へ戻って休息をとります。" % GameManager.active_monster["nickname"]
	GameManager.active_monster["current_hp"] = 1

func _on_return_ranch_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	GameManager.advance_time()
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/ranch/RanchScene.tscn")

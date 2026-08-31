class_name RanchScene
extends Control

## 3Dモンスター育成・牧場シーン
## バイオリズム管理、エサやり、トレーニング、おつかい派遣、バトル出撃

# バイオリズムメーター
@onready var modular_monster: ModularMonster = %PartnerMonster
@onready var label_date_time: Label = %DateLabel
@onready var label_gold: Label = %GoldLabel
@onready var label_monster_header: Label = %MonsterNameHeader

# ステータスバー
@onready var bar_hp: ProgressBar = %HPBar
@onready var label_hp: Label = %HPVal
@onready var bar_mp: ProgressBar = %MPBar
@onready var label_mp: Label = %MPVal
@onready var bar_hunger: ProgressBar = %HungerBar
@onready var label_hunger: Label = %HungerVal
@onready var bar_energy: ProgressBar = %EnergyBar
@onready var label_energy: Label = %EnergyVal
@onready var bar_affection: ProgressBar = %MoodBar
@onready var label_affection: Label = %MoodVal

# メインアクションボタン
@onready var btn_feed: Button = %FeedButton
@onready var btn_train: Button = %TrainButton
@onready var btn_rest: Button = %RestButton
@onready var btn_dispatch: Button = %DispatchButton
@onready var btn_battle: Button = %BattleButton
@onready var btn_dex: Button = %DexButton

# メッセージラベル
@onready var message_label: Label = %MessageLabel

# 3Dモンスター表示
@onready var sub_viewport: SubViewport = %SubViewport
@onready var directional_light: DirectionalLight3D = %DirectionalLight3D
@onready var world_env: WorldEnvironment = %WorldEnvironment

# ポップアップ・サブパネル
@onready var feed_panel: PanelContainer = %FeedPanel
@onready var train_panel: PanelContainer = %TrainPanel
@onready var dispatch_panel: PanelContainer = %DispatchPanel

var _current_target_area: String = ""

func _ready() -> void:
	if has_node("%SafeMarginContainer"):
		SafeAreaHelper.apply_safe_area(%SafeMarginContainer, 52, 8)
	
	GameManager.stats_updated.connect(_update_ui)
	GameManager.day_advanced.connect(_on_day_advanced)
	
	_connect_buttons()
	_update_ui()
	_update_3d_monster()
	_update_lighting_for_time()
	
	_set_message("%s はあなたの指示を待っています。" % GameManager.active_monster["nickname"])

func _connect_buttons() -> void:
	btn_feed.pressed.connect(_on_feed_menu_pressed)
	btn_train.pressed.connect(_on_train_menu_pressed)
	btn_rest.pressed.connect(_on_rest_pressed)
	btn_dispatch.pressed.connect(_on_dispatch_menu_pressed)
	btn_battle.pressed.connect(_on_battle_pressed)
	btn_dex.pressed.connect(_on_dex_pressed)
	
	# エサ選択ボタン
	%BtnFoodMeat.pressed.connect(func(): _feed_item("おにく"))
	%BtnFoodFish.pressed.connect(func(): _feed_item("さかな"))
	%BtnFoodBerry.pressed.connect(func(): _feed_item("きのみ"))
	%BtnFoodHerb.pressed.connect(func(): _feed_item("まほう草"))
	%BtnCloseFeed.pressed.connect(func(): feed_panel.visible = false)
	
	# トレーニング選択ボタン
	%BtnTrainHP.pressed.connect(func(): _train_stat("hp"))
	%BtnTrainATK.pressed.connect(func(): _train_stat("atk"))
	%BtnTrainDEF.pressed.connect(func(): _train_stat("def"))
	%BtnTrainMAG.pressed.connect(func(): _train_stat("mag"))
	%BtnTrainSPD.pressed.connect(func(): _train_stat("spd"))
	%BtnCloseTrain.pressed.connect(func(): train_panel.visible = false)
	
	# おつかいボタン
	%BtnAreaForest.pressed.connect(func(): _start_dispatch("forest"))
	%BtnAreaLake.pressed.connect(func(): _start_dispatch("lake"))
	%BtnAreaVolcano.pressed.connect(func(): _start_dispatch("volcano"))
	%BtnAreaRuins.pressed.connect(func(): _start_dispatch("ruins"))
	%BtnCloseDispatch.pressed.connect(func(): dispatch_panel.visible = false)

func _update_ui() -> void:
	var m: Dictionary = GameManager.active_monster
	label_date_time.text = GameManager.get_current_time_string()
	label_gold.text = "%d G" % GameManager.gold
	label_monster_header.text = "%s  Lv.%d (EXP: %d/%d)" % [
		m["nickname"],
		m["level"],
		m["exp"],
		m["level"] * 25
	]
	
	# HP / MP
	bar_hp.max_value = m["max_hp"]
	bar_hp.value = m["current_hp"]
	label_hp.text = "%d / %d" % [m["current_hp"], m["max_hp"]]
	
	bar_mp.max_value = m["max_mp"]
	bar_mp.value = m["current_mp"]
	label_mp.text = "%d / %d" % [m["current_mp"], m["max_mp"]]
	
	# バイオリズム
	bar_hunger.value = m["hunger"]
	label_hunger.text = "%d%%" % m["hunger"]
	
	bar_energy.value = m["energy"]
	label_energy.text = "%d%%" % m["energy"]
	
	bar_affection.value = m["affection"]
	label_affection.text = "%d%%" % m["affection"]
	
	# アイテム所持数更新
	%BtnFoodMeat.text = "おにく (所持: %d)" % GameManager.inventory.get("おにく", 0)
	%BtnFoodFish.text = "さかな (所持: %d)" % GameManager.inventory.get("さかな", 0)
	%BtnFoodBerry.text = "きのみ (所持: %d)" % GameManager.inventory.get("きのみ", 0)
	%BtnFoodHerb.text = "まほう草 (所持: %d)" % GameManager.inventory.get("まほう草", 0)
	
	# 派遣中のボタン制御
	var is_dispatched: bool = m["is_dispatched"]
	btn_feed.disabled = is_dispatched
	btn_train.disabled = is_dispatched
	btn_battle.disabled = is_dispatched
	btn_dispatch.disabled = is_dispatched
	if is_dispatched:
		_set_message("現在「%s」へおつかい中..." % m["dispatch_destination"])

func _update_3d_monster() -> void:
	var m_id: int = GameManager.active_monster["monster_id"]
	var data := MonsterDatabase.get_monster_data(m_id)
	if data and modular_monster:
		modular_monster.assemble(data)
		modular_monster.play_animation("idle")

func _update_lighting_for_time() -> void:
	# 時間帯に応じた環境光・太陽光の調整
	match GameManager.time_index:
		0: # 朝
			directional_light.light_color = Color(1.0, 0.95, 0.85)
			directional_light.light_energy = 1.0
		1: # 昼
			directional_light.light_color = Color(1.0, 1.0, 0.95)
			directional_light.light_energy = 1.3
		2: # 夕
			directional_light.light_color = Color(1.0, 0.6, 0.4)
			directional_light.light_energy = 1.1
		3: # 夜
			directional_light.light_color = Color(0.3, 0.4, 0.65)
			directional_light.light_energy = 0.5

func _on_day_advanced(day: int, time_str: String) -> void:
	_update_lighting_for_time()
	# もし派遣から帰還していたら結果表示
	if _current_target_area != "" and not GameManager.active_monster["is_dispatched"]:
		var res := DispatchManager.calculate_result(_current_target_area)
		_current_target_area = ""
		_set_message(res["message"] + (" (獲得: +%dG, EXP+%d)" % [res["gold"], res["exp"]] if res["success"] else ""))

func _set_message(text: String) -> void:
	message_label.text = text

func _close_all_subpanels() -> void:
	feed_panel.visible = false
	train_panel.visible = false
	dispatch_panel.visible = false

# --- アクションハンドラ ---
func _on_feed_menu_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	_close_all_subpanels()
	feed_panel.visible = true

func _feed_item(item_name: String) -> void:
	var res := GameManager.feed_monster(item_name)
	RetroSoundPlayer.play_confirm()
	_set_message(res["message"])
	feed_panel.visible = false

func _on_train_menu_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	_close_all_subpanels()
	train_panel.visible = true

func _train_stat(stat_type: String) -> void:
	var res := GameManager.train_monster(stat_type)
	if res["success"]:
		RetroSoundPlayer.play_confirm()
		modular_monster.play_animation("walk")
	else:
		RetroSoundPlayer.play_cancel()
	_set_message(res["message"])
	train_panel.visible = false

func _on_rest_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	_close_all_subpanels()
	GameManager.rest_monster()
	_set_message("ぐっすり休んで体力が全快した！")

func _on_dispatch_menu_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	_close_all_subpanels()
	dispatch_panel.visible = true

func _start_dispatch(area_id: String) -> void:
	_current_target_area = area_id
	DispatchManager.start_dispatch(area_id)
	RetroSoundPlayer.play_confirm()
	dispatch_panel.visible = false
	_set_message("「%s」へ出発しました！" % GameManager.active_monster["dispatch_destination"])
	_update_ui()

func _on_battle_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	_close_all_subpanels()
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_dex_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/title/MonsterDexScene.tscn")

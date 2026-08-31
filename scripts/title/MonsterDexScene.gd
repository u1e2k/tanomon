class_name MonsterDexScene
extends Control

## 3Dモンスター図鑑ビューア (500体対応)
## Pixel 9a (20:9) 最適化 UI & インタラクティブ3D鑑賞

@onready var monster_list_container: VBoxContainer = %MonsterListContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var monster_viewport: SubViewport = %MonsterSubViewport
@onready var monster_pivot: Node3D = %MonsterPivot
@onready var modular_monster: ModularMonster = %ModularMonster
@onready var anim_button: Button = %AnimButton
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton
@onready var back_button: Button = %BackButton

# UIラベル類
@onready var label_number_name: Label = %LabelNumberName
@onready var label_element: Label = %LabelElement
@onready var label_growth: Label = %LabelGrowth
@onready var label_description: RichTextLabel = %LabelDescription
@onready var bar_hp: ProgressBar = %BarHP
@onready var bar_mp: ProgressBar = %BarMP
@onready var bar_atk: ProgressBar = %BarATK
@onready var bar_def: ProgressBar = %BarDEF
@onready var bar_mag: ProgressBar = %BarMAG
@onready var bar_spd: ProgressBar = %BarSPD
@onready var label_hp_val: Label = %LabelHPVal
@onready var label_mp_val: Label = %LabelMPVal
@onready var label_atk_val: Label = %LabelATKVal
@onready var label_def_val: Label = %LabelDEFVal
@onready var label_mag_val: Label = %LabelMAGVal
@onready var label_spd_val: Label = %LabelSPDVal
@onready var label_evolution: Label = %LabelEvolution
@onready var label_food: Label = %LabelFood

var _current_id: int = 1
var _total_count: int = 500
var _is_dragging_3d: bool = false
var _last_drag_pos: Vector2 = Vector2.ZERO
var _current_anim: String = "idle"
var _list_buttons: Dictionary = {} # id -> Button

const ELEMENT_NAMES: Array[String] = [
	"無", "火 (炎)", "水 (水流)", "草 (自然)",
	"雷 (電撃)", "土 (大地)", "風 (天空)", "光 (聖なる)", "闇 (邪悪)"
]

const ELEMENT_COLORS: Array[Color] = [
	Color(0.7, 0.7, 0.7),
	Color(1.0, 0.35, 0.2),
	Color(0.2, 0.6, 1.0),
	Color(0.3, 0.85, 0.3),
	Color(1.0, 0.85, 0.1),
	Color(0.8, 0.6, 0.35),
	Color(0.3, 0.9, 0.8),
	Color(1.0, 0.95, 0.6),
	Color(0.7, 0.3, 0.9)
]

const FOOD_NAMES: Array[String] = ["おにく", "さかな", "きのみ", "まほう草"]

func _ready() -> void:
	if has_node("%SafeMarginContainer"):
		SafeAreaHelper.apply_safe_area(%SafeMarginContainer, 52, 8)
		
	_total_count = MonsterDatabase.get_total_count()
	if _total_count == 0:
		_total_count = 500
		
	_setup_list()
	_connect_signals()
	select_monster(1)

func _process(delta: float) -> void:
	# 非ドラッグ時は自動でゆっくりY軸自転
	if not _is_dragging_3d and monster_pivot:
		monster_pivot.rotation.y += 0.5 * delta

func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if prev_button:
		prev_button.pressed.connect(_on_prev_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if anim_button:
		anim_button.pressed.connect(_on_anim_toggle_pressed)

func _setup_list() -> void:
	# リストコンテナの子ノードをクリア
	for child in monster_list_container.get_children():
		child.queue_free()
	_list_buttons.clear()
	
	var ids := MonsterDatabase.get_all_registered_ids()
	if ids.is_empty():
		ids = range(1, 501)
	
	for m_id in ids:
		var btn := Button.new()
		btn.text = "No.%03d モンスター" % m_id
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 28)
		btn.focus_mode = Control.FOCUS_ALL
		
		# 遅延データ取得（表示最適化）
		var data := MonsterDatabase.get_monster_data(m_id)
		if data:
			btn.text = "No.%03d %s" % [data.id, data.monster_name]
		
		btn.pressed.connect(func(): select_monster(m_id))
		btn.focus_entered.connect(func(): select_monster(m_id))
		
		monster_list_container.add_child(btn)
		_list_buttons[m_id] = btn

## モンスター選択処理
func select_monster(m_id: int) -> void:
	_current_id = clampi(m_id, 1, _total_count)
	RetroSoundPlayer.play_cursor()
	
	var data := MonsterDatabase.get_monster_data(_current_id)
	if not data:
		return
	
	# 3Dモデルのアセンブル
	if modular_monster:
		modular_monster.assemble(data)
		modular_monster.play_animation(_current_anim)
	
	# UI更新
	_update_ui_details(data)
	
	# リストの選択フォーカス更新
	if _list_buttons.has(_current_id):
		var btn: Button = _list_buttons[_current_id]
		# スクロール追従
		if scroll_container:
			var target_y := btn.position.y - 100.0
			scroll_container.scroll_vertical = int(max(0, target_y))

func _update_ui_details(data: MonsterData) -> void:
	label_number_name.text = "No.%03d  %s" % [data.id, data.monster_name]
	
	var el_idx := clampi(data.element, 0, ELEMENT_NAMES.size() - 1)
	label_element.text = "属性: " + ELEMENT_NAMES[el_idx]
	label_element.modulate = ELEMENT_COLORS[el_idx]
	
	var growth_str := "普通"
	if data.growth_type == MonsterData.GrowthType.EARLY:
		growth_str = "早熟"
	elif data.growth_type == MonsterData.GrowthType.LATE:
		growth_str = "晩成"
	label_growth.text = "タイプ: %s" % growth_str
	
	# ステータスバー (最大値目安 250)
	bar_hp.max_value = 200
	bar_hp.value = data.base_max_hp
	label_hp_val.text = str(data.base_max_hp)
	
	bar_mp.max_value = 150
	bar_mp.value = data.base_max_mp
	label_mp_val.text = str(data.base_max_mp)
	
	bar_atk.max_value = 100
	bar_atk.value = data.base_attack
	label_atk_val.text = str(data.base_attack)
	
	bar_def.max_value = 100
	bar_def.value = data.base_defense
	label_def_val.text = str(data.base_defense)
	
	bar_mag.max_value = 100
	bar_mag.value = data.base_magic
	label_mag_val.text = str(data.base_magic)
	
	bar_spd.max_value = 100
	bar_spd.value = data.base_speed
	label_spd_val.text = str(data.base_speed)
	
	# 好物 & バイオリズム
	var food_idx := clampi(data.favorite_food_type, 0, FOOD_NAMES.size() - 1)
	label_food.text = "好物: %s (消費: x%.1f)" % [FOOD_NAMES[food_idx], data.hunger_rate]
	
	# 進化先
	if data.evolution_ids.is_empty():
		label_evolution.text = "進化: 最終形態 (進化なし)"
	else:
		var evo_names: Array[String] = []
		for eid in data.evolution_ids:
			var edata := MonsterDatabase.get_monster_data(eid)
			if edata:
				evo_names.append("No.%03d %s" % [edata.id, edata.monster_name])
			else:
				evo_names.append("No.%03d" % eid)
		label_evolution.text = "進化(Lv%d~): %s" % [data.evolution_level_requirement, ", ".join(evo_names)]
	
	label_description.text = data.description

## 3Dタッチ・ドラッグ回転操作
func _gui_input_3d_viewport(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging_3d = event.pressed
			_last_drag_pos = event.position
	elif event is InputEventScreenTouch:
		_is_dragging_3d = event.pressed
		_last_drag_pos = event.position
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if _is_dragging_3d and monster_pivot:
			var delta_pos: Vector2 = event.position - _last_drag_pos
			_last_drag_pos = event.position
			monster_pivot.rotation.y += delta_pos.x * 0.01
			monster_pivot.rotation.x = clampf(monster_pivot.rotation.x + delta_pos.y * 0.005, -0.4, 0.4)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
	elif event.is_action_pressed("ui_page_up") or event.is_action_pressed("ui_left"):
		if not get_viewport().gui_get_focus_owner() is LineEdit:
			_on_prev_pressed()
	elif event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_right"):
		if not get_viewport().gui_get_focus_owner() is LineEdit:
			_on_next_pressed()

func _on_prev_pressed() -> void:
	RetroSoundPlayer.play_switch()
	var prev_id := _current_id - 1
	if prev_id < 1:
		prev_id = _total_count
	select_monster(prev_id)

func _on_next_pressed() -> void:
	RetroSoundPlayer.play_switch()
	var next_id := _current_id + 1
	if next_id > _total_count:
		next_id = 1
	select_monster(next_id)

func _on_anim_toggle_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	if _current_anim == "idle":
		_current_anim = "walk"
		anim_button.text = "モーション: 歩行中"
	else:
		_current_anim = "idle"
		anim_button.text = "モーション: 待機中"
	
	if modular_monster:
		modular_monster.play_animation(_current_anim)

func _on_back_pressed() -> void:
	RetroSoundPlayer.play_cancel()
	get_tree().change_scene_to_file("res://scenes/title/TitleScene.tscn")

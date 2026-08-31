class_name TitleScene
extends Control

## タイトル画面制御スクリプト
## 3Dライブ牧場背景と2D UIの統合、コントローラー/タッチ入力ハンドリング

@onready var tap_to_start_btn: Button = %TapToStartButton
@onready var prompt_label: Label = %PromptLabel
@onready var menu_container: VBoxContainer = %MenuContainer
@onready var btn_start: Button = %StartButton
@onready var btn_continue: Button = %ContinueButton
@onready var btn_dex: Button = %DexButton
@onready var btn_settings: Button = %SettingsButton

var _in_menu_mode: bool = false
var _blink_timer: float = 0.0

func _ready() -> void:
	if has_node("%SafeMarginContainer"):
		SafeAreaHelper.apply_safe_area(%SafeMarginContainer, 52, 10)
	
	menu_container.visible = false
	prompt_label.visible = true
	tap_to_start_btn.visible = true
	
	_connect_buttons()

func _process(delta: float) -> void:
	if not _in_menu_mode and prompt_label:
		_blink_timer += delta * 3.0
		prompt_label.modulate.a = 0.3 + 0.7 * (0.5 + 0.5 * sin(_blink_timer))

func _connect_buttons() -> void:
	if tap_to_start_btn:
		tap_to_start_btn.pressed.connect(_enter_menu_mode)
	if btn_start:
		btn_start.pressed.connect(_on_new_game_pressed)
	if btn_continue:
		btn_continue.pressed.connect(_on_continue_pressed)
	if btn_dex:
		btn_dex.pressed.connect(_on_dex_pressed)
	if btn_settings:
		btn_settings.pressed.connect(_on_settings_pressed)

func _gui_input(event: InputEvent) -> void:
	if not _in_menu_mode and event.is_pressed():
		_enter_menu_mode()

func _unhandled_input(event: InputEvent) -> void:
	if not _in_menu_mode:
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventScreenTouch or event is InputEventMouseButton:
			if event.is_pressed():
				_enter_menu_mode()

func _enter_menu_mode() -> void:
	if _in_menu_mode:
		return
	_in_menu_mode = true
	RetroSoundPlayer.play_confirm()
	if tap_to_start_btn and is_instance_valid(tap_to_start_btn):
		tap_to_start_btn.queue_free()
		tap_to_start_btn = null
	if prompt_label:
		prompt_label.visible = false
	if menu_container:
		menu_container.visible = true
	if btn_start:
		btn_start.grab_focus()

func _on_new_game_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	GameManager.reset_game_state()
	get_tree().change_scene_to_file("res://scenes/ranch/RanchScene.tscn")

func _on_continue_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	GameManager.load_game()
	get_tree().change_scene_to_file("res://scenes/ranch/RanchScene.tscn")

func _on_dex_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	get_tree().change_scene_to_file("res://scenes/title/MonsterDexScene.tscn")

func _on_settings_pressed() -> void:
	RetroSoundPlayer.play_cursor()
	# 設定トグル例（音量等）

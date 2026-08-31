class_name TitleScene
extends Control

## タイトル画面制御スクリプト
## 3Dライブ牧場背景と2D UIの統合、コントローラー/タッチ入力ハンドリング

@onready var tap_to_start_btn: Button = %TapToStartButton
@onready var press_start_label: Label = %PressStartLabel
@onready var menu_container: VBoxContainer = %MenuContainer
@onready var btn_new_game: Button = %BtnNewGame
@onready var btn_continue: Button = %BtnContinue
@onready var btn_dex: Button = %BtnDex
@onready var btn_settings: Button = %BtnSettings

var _in_menu_mode: bool = false
var _blink_timer: float = 0.0

func _ready() -> void:
	menu_container.visible = false
	press_start_label.visible = true
	tap_to_start_btn.visible = true
	
	_connect_buttons()

func _process(delta: float) -> void:
	if not _in_menu_mode:
		_blink_timer += delta * 3.0
		press_start_label.modulate.a = 0.3 + 0.7 * (0.5 + 0.5 * sin(_blink_timer))

func _connect_buttons() -> void:
	tap_to_start_btn.pressed.connect(_enter_menu_mode)
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_dex.pressed.connect(_on_dex_pressed)
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
	tap_to_start_btn.visible = false
	press_start_label.visible = false
	menu_container.visible = true
	btn_new_game.grab_focus()

func _on_new_game_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	get_tree().change_scene_to_file("res://scenes/ranch/RanchScene.tscn")

func _on_continue_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	GameManager.load_game()
	get_tree().change_scene_to_file("res://scenes/ranch/RanchScene.tscn")

func _on_dex_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	get_tree().change_scene_to_file("res://scenes/title/MonsterDexScene.tscn")

func _on_settings_pressed() -> void:
	RetroSoundPlayer.play_confirm()
	print("[Title] Settings Selected")

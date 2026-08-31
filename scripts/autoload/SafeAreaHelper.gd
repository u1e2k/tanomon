extends Node

## Pixel 9a / モバイル向け セーフエリア自動適用ヘルパー
## 画面のカットアウト（パンチホール）や角丸を検知し、UIルートに最適なマージンを設定します。

const BASE_WIDTH := 808.0
const BASE_HEIGHT := 360.0

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)

## 指定されたMarginContainerにセーフエリアマージンを自動適用
func apply_safe_area(margin_container: MarginContainer, extra_margin_x: int = 16, extra_margin_y: int = 8) -> void:
	if not margin_container:
		return
	
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	
	var left_margin: int = extra_margin_x
	var right_margin: int = extra_margin_x
	var top_margin: int = extra_margin_y
	var bottom_margin: int = extra_margin_y
	
	if screen_size.x > 0 and screen_size.y > 0:
		# スケール比率計算
		var scale_x: float = BASE_WIDTH / float(screen_size.x)
		var scale_y: float = BASE_HEIGHT / float(screen_size.y)
		
		var inset_left: int = int(safe_rect.position.x * scale_x)
		var inset_right: int = int((screen_size.x - safe_rect.end.x) * scale_x)
		var inset_top: int = int(safe_rect.position.y * scale_y)
		var inset_bottom: int = int((screen_size.y - safe_rect.end.y) * scale_y)
		
		# Pixel 9a のカットアウト（152px / 3 ≒ 52px）または角丸（115px / 3 ≒ 38px）をフォールバック考慮
		left_margin = maxi(left_margin, maxi(inset_left, 52))
		right_margin = maxi(right_margin, maxi(inset_right, 52))
		top_margin = maxi(top_margin, maxi(inset_top, 12))
		bottom_margin = maxi(bottom_margin, maxi(inset_bottom, 12))
	else:
		# 実機取得できない場合のフォールバック（Pixel 9a 最適値）
		left_margin = 52
		right_margin = 52
		top_margin = 12
		bottom_margin = 12
	
	margin_container.add_theme_constant_override("margin_left", left_margin)
	margin_container.add_theme_constant_override("margin_right", right_margin)
	margin_container.add_theme_constant_override("margin_top", top_margin)
	margin_container.add_theme_constant_override("margin_bottom", bottom_margin)

func _on_viewport_size_changed() -> void:
	# 画面回転・リサイズ時に再計算
	pass

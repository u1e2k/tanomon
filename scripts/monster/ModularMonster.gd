@tool
class_name ModularMonster
extends Node3D

## シグナル
signal assembled(monster_data: MonsterData)
signal animation_finished(anim_name: String)

@export var current_monster_data: MonsterData:
	set(value):
		current_monster_data = value
		if is_inside_tree() and current_monster_data:
			assemble(current_monster_data)

## 内部管理
var _base_instance: Node3D = null
var _slot_markers: Dictionary = {} # String -> Marker3D
var _anim_player: AnimationPlayer = null
var _shared_material: StandardMaterial3D = null

# 属性ごとの鮮やかなローポリカラー定義
const ELEMENT_COLORS: Array[Color] = [
	Color(0.85, 0.8, 0.75),   # 0: 無 (ベージュ)
	Color(0.95, 0.3, 0.15),   # 1: 火 (フレイムレッド)
	Color(0.2, 0.6, 0.95),    # 2: 水 (アクアブルー)
	Color(0.25, 0.85, 0.3),   # 3: 草 (フォレストグリーン)
	Color(0.98, 0.85, 0.15),  # 4: 雷 (サンダーイエロー)
	Color(0.7, 0.5, 0.3),     # 5: 土 (アースブラウン)
	Color(0.3, 0.9, 0.85),    # 6: 風 (スカイシアン)
	Color(1.0, 0.95, 0.75),   # 7: 光 (ホーリーゴールド)
	Color(0.55, 0.2, 0.75)    # 8: 闇 (ダークパープル)
]

func _ready() -> void:
	if current_monster_data:
		assemble(current_monster_data)

## 指定されたMonsterDataをもとに動的アセンブルを行う
func assemble(data: MonsterData) -> void:
	_cleanup()
	
	if not data:
		return
	
	# 1. 属性色マテリアルを準備
	_setup_material(data)
	
	# 2. ベース素体のロード & インスタンス化
	_load_base_model(data)
	
	# 3. マーカー探索
	_find_attachment_markers()
	
	# 4. パーツのアタッチ
	_attach_parts(data)
	
	# 5. 全メッシュへマテリアル適用
	_apply_material_recursive(self)
	
	# 6. スケール適用
	scale = data.model_scale if data.model_scale != Vector3.ZERO else Vector3.ONE
	
	# 7. AnimationPlayerの初期化
	_setup_animation()
	
	assembled.emit(data)

## クリーンアップ
func _cleanup() -> void:
	_slot_markers.clear()
	_anim_player = null
	
	# 直下の子ノードを安全に即時解放
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	_base_instance = null

## マテリアルの生成（Android Vulkanでも確実に鮮やかに描画）
func _setup_material(data: MonsterData) -> void:
	var elem_idx := clampi(int(data.element), 0, ELEMENT_COLORS.size() - 1)
	var tint := ELEMENT_COLORS[elem_idx]
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED # 両面描画
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_shared_material = mat

## ベース素体の読み込み
func _load_base_model(data: MonsterData) -> void:
	if not data.base_model_path.is_empty():
		var scene_res: PackedScene = load(data.base_model_path) as PackedScene
		if scene_res:
			_base_instance = scene_res.instantiate() as Node3D
			add_child(_base_instance)
			return
	
	# ロードできない場合のフォールバック素体
	_create_fallback_body()

## フォールバック用の簡易素体生成
func _create_fallback_body() -> void:
	_base_instance = Node3D.new()
	_base_instance.name = "FallbackBody"
	
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	sphere.radial_segments = 8
	sphere.rings = 5
	mesh_inst.mesh = sphere
	mesh_inst.position = Vector3(0, 0.6, 0)
	_base_instance.add_child(mesh_inst)
	
	# マーカー追加
	var head_marker := Marker3D.new()
	head_marker.name = "Marker_head"
	head_marker.position = Vector3(0, 1.1, 0.2)
	_base_instance.add_child(head_marker)
	
	var back_marker := Marker3D.new()
	back_marker.name = "Marker_back"
	back_marker.position = Vector3(0, 0.7, -0.5)
	_base_instance.add_child(back_marker)
	
	var tail_marker := Marker3D.new()
	tail_marker.name = "Marker_tail"
	tail_marker.position = Vector3(0, 0.3, -0.6)
	_base_instance.add_child(tail_marker)
	
	add_child(_base_instance)

## ベース素体内のアタッチメントマーカー（Marker3D）を再帰探索
func _find_attachment_markers() -> void:
	_slot_markers.clear()
	if not _base_instance:
		return
	_scan_markers_recursive(_base_instance)

func _scan_markers_recursive(node: Node) -> void:
	if node is Marker3D:
		var marker_name: String = node.name.to_lower()
		if marker_name.begins_with("marker_"):
			var slot_key: String = marker_name.replace("marker_", "")
			_slot_markers[slot_key] = node
	
	for child in node.get_children():
		_scan_markers_recursive(child)

## パーツのロード & スロットマーカーへのアタッチ
func _attach_parts(data: MonsterData) -> void:
	for slot_name in data.parts_paths.keys():
		var part_path: String = data.parts_paths[slot_name]
		if part_path.is_empty():
			continue
		
		var clean_slot: String = str(slot_name).to_lower().replace("marker_", "")
		if not _slot_markers.has(clean_slot):
			continue
		
		var marker: Marker3D = _slot_markers[clean_slot]
		var part_scene: PackedScene = load(part_path) as PackedScene
		if part_scene:
			var part_instance := part_scene.instantiate()
			marker.add_child(part_instance)

## メッシュインスタンスへマテリアルを再帰適用
func _apply_material_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var node_name := node.name.to_lower()
		if not node_name.begins_with("eye"):
			if _shared_material:
				node.material_override = _shared_material
	
	for child in node.get_children():
		_apply_material_recursive(child)

## アニメーションのセットアップ
func _setup_animation() -> void:
	_anim_player = _find_animation_player(self)
	if _anim_player:
		if _anim_player.has_animation("idle"):
			_anim_player.play("idle")
		elif _anim_player.get_animation_list().size() > 0:
			_anim_player.play(_anim_player.get_animation_list()[0])
		
		if not _anim_player.animation_finished.is_connected(_on_animation_finished):
			_anim_player.animation_finished.connect(_on_animation_finished)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _on_animation_finished(anim_name: String) -> void:
	animation_finished.emit(anim_name)

## 外部からのアニメーション再生制御
func play_animation(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)

## モンスターの回転
func rotate_model(degrees_y: float) -> void:
	rotation_degrees.y += degrees_y

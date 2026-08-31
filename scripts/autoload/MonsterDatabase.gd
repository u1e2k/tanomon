extends Node

## モンスターデータ管理シングルトン (MonsterDatabase)
## 500体のリソースパスをインデックス化し、必要時にオンデマンドでロード・キャッシュします。

const MONSTER_DATA_DIR: String = "res://data/monsters/"

# キャッシュ辞書 (ID -> MonsterData)
var _cache: Dictionary = {}
# ID -> ファイルパスのマップ
var _index_map: Dictionary = {}
var _total_monsters: int = 0

func _ready() -> void:
	_build_index()

## リソースディレクトリを走査してIDインデックスを作成（軽量）
func _build_index() -> void:
	_index_map.clear()
	var dir := DirAccess.open(MONSTER_DATA_DIR)
	if not dir:
		# ディレクトリがまだ存在しない場合は作成
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MONSTER_DATA_DIR))
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var clean_name := file_name.trim_suffix(".remap").trim_suffix(".import")
			if clean_name.begins_with("monster_") and clean_name.ends_with(".tres"):
				var full_path := MONSTER_DATA_DIR.path_join(clean_name)
				var id_str := clean_name.trim_prefix("monster_").trim_suffix(".tres")
				if id_str.is_valid_int():
					var id := id_str.to_int()
					_index_map[id] = full_path
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# DirAccessで見つからない場合 (PCK内の仮想ディレクトリ) は 1〜500 をフォールバック登録
	if _index_map.is_empty():
		for i in range(1, 501):
			_index_map[i] = MONSTER_DATA_DIR.path_join("monster_%03d.tres" % i)
			
	_total_monsters = _index_map.size()
	print("[MonsterDatabase] Indexed %d monster resources." % _total_monsters)

## IDからMonsterDataを取得（キャッシュまたはオンデマンドロード）
func get_monster_data(monster_id: int) -> MonsterData:
	if _cache.has(monster_id):
		return _cache[monster_id]
	
	if _index_map.has(monster_id):
		var path: String = _index_map[monster_id]
		var res: MonsterData = load(path) as MonsterData
		if res:
			_cache[monster_id] = res
			return res
	
	# インデックスにないが、直指定でファイルが存在するか試行
	var fallback_path := MONSTER_DATA_DIR.path_join("monster_%03d.tres" % monster_id)
	if ResourceLoader.exists(fallback_path):
		var res: MonsterData = load(fallback_path) as MonsterData
		if res:
			_cache[monster_id] = res
			_index_map[monster_id] = fallback_path
			return res
			
	push_warning("[MonsterDatabase] MonsterData not found for ID: %d" % monster_id)
	return null

## キャッシュの解放（メモリ節約用）
func clear_cache() -> void:
	_cache.clear()

## 全モンスターIDリストを取得
func get_all_registered_ids() -> Array:
	var ids := _index_map.keys()
	ids.sort()
	return ids

## 登録総数
func get_total_count() -> int:
	return _total_monsters

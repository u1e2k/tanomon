@tool
class_name MonsterBatchGenerator
extends EditorScript

## CSVファイルからMonsterData (.tres) を一括生成するエディタスクリプト
## 実行方法: Godotエディタの「スクリプト」タブ ->「ファイル」->「スクリプトを実行 (Ctrl+Shift+X)」

const CSV_PATH: String = "res://data/monsters_data.csv"
const OUTPUT_DIR: String = "res://data/monsters/"

func _run() -> void:
	print("=== [MonsterBatchGenerator] 500体一括生成バッチ開始 ===")
	
	var dir := DirAccess.open("res://")
	if not dir.dir_exists(OUTPUT_DIR):
		dir.make_dir_recursive(OUTPUT_DIR)
		print("作成ディレクトリ: ", OUTPUT_DIR)
	
	if not FileAccess.file_exists(CSV_PATH):
		push_error("CSVファイルが見つかりません: " + CSV_PATH)
		return
	
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		push_error("CSVファイルを開けませんでした: " + CSV_PATH)
		return
	
	# ヘッダー行の読み込み
	var headers := file.get_csv_line()
	var header_map: Dictionary = {}
	for i in range(headers.size()):
		header_map[headers[i].strip_edges()] = i
	
	var count: int = 0
	var error_count: int = 0
	
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() <= 1 and line[0].strip_edges().is_empty():
			continue # 空行スキップ
		
		if line.size() < headers.size():
			continue
		
		var monster := MonsterData.new()
		
		# パース処理
		monster.id = int(line[header_map.get("id", 0)])
		monster.monster_name = str(line[header_map.get("monster_name", 1)])
		monster.description = str(line[header_map.get("description", 2)])
		monster.element = int(line[header_map.get("element", 3)]) as MonsterData.ElementType
		monster.growth_type = int(line[header_map.get("growth_type", 4)]) as MonsterData.GrowthType
		
		monster.base_model_path = str(line[header_map.get("base_model_path", 5)])
		
		# パーツ辞書
		var parts_dict: Dictionary = {}
		var head_part := str(line[header_map.get("part_head", 6)]).strip_edges()
		var back_part := str(line[header_map.get("part_back", 7)]).strip_edges()
		var tail_part := str(line[header_map.get("part_tail", 8)]).strip_edges()
		
		if not head_part.is_empty():
			parts_dict["head"] = head_part
		if not back_part.is_empty():
			parts_dict["back"] = back_part
		if not tail_part.is_empty():
			parts_dict["tail"] = tail_part
		
		monster.parts_paths = parts_dict
		monster.palette_index = int(line[header_map.get("palette_index", 9)])
		
		var sx := float(line[header_map.get("scale_x", 10)])
		var sy := float(line[header_map.get("scale_y", 11)])
		var sz := float(line[header_map.get("scale_z", 12)])
		monster.model_scale = Vector3(sx, sy, sz)
		
		monster.base_max_hp = int(line[header_map.get("base_max_hp", 13)])
		monster.base_max_mp = int(line[header_map.get("base_max_mp", 14)])
		monster.base_attack = int(line[header_map.get("base_attack", 15)])
		monster.base_defense = int(line[header_map.get("base_defense", 16)])
		monster.base_magic = int(line[header_map.get("base_magic", 17)])
		monster.base_speed = int(line[header_map.get("base_speed", 18)])
		
		monster.hunger_rate = float(line[header_map.get("hunger_rate", 19)])
		monster.energy_rate = float(line[header_map.get("energy_rate", 20)])
		monster.favorite_food_type = int(line[header_map.get("favorite_food", 21)])
		
		var evo_ids_raw := str(line[header_map.get("evolution_ids", 22)]).strip_edges()
		var evo_ids: Array[int] = []
		if not evo_ids_raw.is_empty():
			for id_token in evo_ids_raw.split(";"):
				if id_token.is_valid_int():
					evo_ids.append(id_token.to_int())
		monster.evolution_ids = evo_ids
		monster.evolution_level_requirement = int(line[header_map.get("evolution_level", 23)])
		
		var out_file_path := OUTPUT_DIR.path_join("monster_%03d.tres" % monster.id)
		var err := ResourceSaver.save(monster, out_file_path)
		if err == OK:
			count += 1
		else:
			push_error("Failed to save: %s (Error code: %d)" % [out_file_path, err])
			error_count += 1
	
	file.close()
	print("=== [MonsterBatchGenerator] 完了: 成功=%d体, 失敗=%d体 ===" % [count, error_count])

import csv
import os

CSV_PATH = "data/monsters_data.csv"
OUTPUT_DIR = "data/monsters"

def generate_tres_files():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    with open(CSV_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        count = 0
        for row in reader:
            m_id = int(row["id"])
            m_name = row["monster_name"]
            desc = row["description"]
            element = int(row["element"])
            growth = int(row["growth_type"])
            base_model = row["base_model_path"]
            
            parts_entries = []
            if row["part_head"]:
                parts_entries.append(f'"head": "{row["part_head"]}"')
            if row["part_back"]:
                parts_entries.append(f'"back": "{row["part_back"]}"')
            if row["part_tail"]:
                parts_entries.append(f'"tail": "{row["part_tail"]}"')
            parts_dict_str = "{" + ", ".join(parts_entries) + "}"
            
            palette_idx = int(row["palette_index"])
            sx = float(row["scale_x"])
            sy = float(row["scale_y"])
            sz = float(row["scale_z"])
            
            hp = int(row["base_max_hp"])
            mp = int(row["base_max_mp"])
            atk = int(row["base_attack"])
            defe = int(row["base_defense"])
            mag = int(row["base_magic"])
            spd = int(row["base_speed"])
            
            hunger = float(row["hunger_rate"])
            energy = float(row["energy_rate"])
            fav_food = int(row["favorite_food"])
            
            evo_ids = row["evolution_ids"].strip()
            evo_array_str = f"[{evo_ids}]" if evo_ids else "[]"
            evo_lvl = int(row["evolution_level"])
            
            tres_content = f"""[gd_resource type="Resource" script_class="MonsterData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/MonsterData.gd" id="1_data"]

[resource]
script = ExtResource("1_data")
id = {m_id}
monster_name = "{m_name}"
description = "{desc}"
element = {element}
growth_type = {growth}
base_model_path = "{base_model}"
parts_paths = {parts_dict_str}
palette_index = {palette_idx}
model_scale = Vector3({sx}, {sy}, {sz})
base_max_hp = {hp}
base_max_mp = {mp}
base_attack = {atk}
base_defense = {defe}
base_magic = {mag}
base_speed = {spd}
hunger_rate = {hunger}
energy_rate = {energy}
favorite_food_type = {fav_food}
evolution_ids = Array[int]({evo_array_str})
evolution_level_requirement = {evo_lvl}
"""
            out_file = os.path.join(OUTPUT_DIR, f"monster_{m_id:03d}.tres")
            with open(out_file, "w", encoding="utf-8") as out_f:
                out_f.write(tres_content)
            count += 1
            
    print(f"Generated {count} .tres resource files in {OUTPUT_DIR}")

if __name__ == "__main__":
    generate_tres_files()

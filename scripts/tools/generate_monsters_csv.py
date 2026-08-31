import csv
import random
import os

# 素体定義
BASE_QUADRUPED = "res://assets/models/bases/base_quadruped.tscn" # 四足獣型 (犬・猫・虎・熊など)
BASE_BIPED = "res://assets/models/bases/base_biped.tscn"         # 二足歩行型 (人型・騎士・トカゲなど)
BASE_FLOATING = "res://assets/models/bases/base_floating.tscn"   # 浮遊・飛行型 (蝙蝠・鳥・精霊など)

# パーツ定義
HORN_SINGLE = "res://assets/models/parts/horn_single.tscn"
HORNS_DUAL = "res://assets/models/parts/horns_dual.tscn"
CROWN = "res://assets/models/parts/crown.tscn"
WINGS_DRAGON = "res://assets/models/parts/wings_dragon.tscn"
WINGS_ANGEL = "res://assets/models/parts/wings_angel.tscn"
TAIL_SPIKE = "res://assets/models/parts/tail_spike.tscn"

# 属性ごとの接頭語
PREFIXES = {
    1: ["フレイム", "マグマ", "バーン", "サラマン", "クリムゾン", "ヴォルカ", "ヒート", "イグニス"], # Fire
    2: ["アクア", "マリン", "ハイドロ", "リヴァイ", "タイダル", "オーシャン", "フロスト", "シレーヌ"], # Water
    3: ["リーフ", "フォレスト", "シルフ", "ウッド", "ブルーム", "ドリアード", "モス", "トレント"], # Nature
    4: ["サンダー", "ボルト", "ライトニ", "スパーク", "エレクトラ", "ライデン", "プラズマ", "ジゴワット"], # Electric
    5: ["ガイア", "ゴーレム", "アース", "クエイク", "グラン", "ストーン", "テラ", "バサルト"], # Earth
    6: ["ウインド", "ゲイル", "エアロ", "ストーム", "ゼファー", "テンペスト", "ファルコン", "スカイ"], # Wind
    7: ["ホーリー", "シャイン", "ルミナス", "セラフ", "オーラ", "グローリー", "セレス", "ソレイユ"], # Light
    8: ["シャドウ", "ダーク", "カオス", "ネクロ", "アビス", "ファントム", "ノワール", "ドゥーム"], # Dark
}

# 種族の定義：(種族名, 素体タイプ, 推奨頭パーツ, 推奨背中パーツ, 推奨尻尾パーツ)
ROOT_CONFIGS = [
    # 浮遊・飛行系
    ("バット", BASE_FLOATING, "", WINGS_DRAGON, ""),
    ("バード", BASE_FLOATING, "", WINGS_ANGEL, ""),
    ("ピクシー", BASE_FLOATING, CROWN, WINGS_ANGEL, ""),
    ("フェアリー", BASE_FLOATING, "", WINGS_ANGEL, ""),
    ("ワイバーン", BASE_FLOATING, HORNS_DUAL, WINGS_DRAGON, TAIL_SPIKE),
    ("ペガサス", BASE_FLOATING, HORN_SINGLE, WINGS_ANGEL, TAIL_SPIKE),
    ("グリフ", BASE_FLOATING, "", WINGS_ANGEL, TAIL_SPIKE),
    ("ポロン", BASE_FLOATING, "", "", ""),
    
    # 四足獣系
    ("パピー", BASE_QUADRUPED, "", "", TAIL_SPIKE),
    ("フォックス", BASE_QUADRUPED, "", "", TAIL_SPIKE),
    ("ビースト", BASE_QUADRUPED, HORNS_DUAL, "", TAIL_SPIKE),
    ("タイガー", BASE_QUADRUPED, "", "", TAIL_SPIKE),
    ("ベア", BASE_QUADRUPED, "", "", ""),
    ("ケルベ", BASE_QUADRUPED, HORNS_DUAL, "", TAIL_SPIKE),
    ("キマイラ", BASE_QUADRUPED, HORNS_DUAL, WINGS_DRAGON, TAIL_SPIKE),
    ("タートル", BASE_QUADRUPED, "", "", ""),
    ("ガル", BASE_QUADRUPED, HORN_SINGLE, "", TAIL_SPIKE),
    ("モコ", BASE_QUADRUPED, "", "", ""),
    
    # 二足歩行・人型・竜戦士系
    ("ドラコ", BASE_BIPED, HORNS_DUAL, WINGS_DRAGON, TAIL_SPIKE),
    ("レクス", BASE_BIPED, HORNS_DUAL, "", TAIL_SPIKE),
    ("ナイト", BASE_BIPED, HORN_SINGLE, "", ""),
    ("リッチ", BASE_BIPED, CROWN, "", ""),
    ("ゴブ", BASE_BIPED, HORN_SINGLE, "", ""),
    ("ホーン", BASE_BIPED, HORNS_DUAL, "", ""),
    ("ファング", BASE_BIPED, "", "", TAIL_SPIKE),
    ("クロウ", BASE_BIPED, "", WINGS_DRAGON, TAIL_SPIKE),
    ("コブラ", BASE_BIPED, "", "", TAIL_SPIKE),
    ("ダイナ", BASE_BIPED, HORNS_DUAL, "", TAIL_SPIKE),
    ("モグ", BASE_BIPED, "", "", ""),
    ("タモ", BASE_BIPED, CROWN, "", ""),
    ("ノッコ", BASE_BIPED, "", "", ""),
    ("コロ", BASE_BIPED, "", "", "")
]

SUFFIXES = ["ス", "ル", "ドン", "ゴン", "ザー", "キッド", "ロード", "キング", "エンペラー", "オメガ", "プライム"]
GROWTH_TYPES = [0, 1, 2] # 0: Early, 1: Normal, 2: Late

def generate_csv(output_path, count=500):
    random.seed(42)
    
    rows = []
    headers = [
        "id", "monster_name", "description", "element", "growth_type",
        "base_model_path", "part_head", "part_back", "part_tail",
        "palette_index", "scale_x", "scale_y", "scale_z",
        "base_max_hp", "base_max_mp", "base_attack", "base_defense", "base_magic", "base_speed",
        "hunger_rate", "energy_rate", "favorite_food", "evolution_ids", "evolution_level"
    ]
    
    for i in range(1, count + 1):
        # 属性 (1〜8)
        element = ((i - 1) % 8) + 1
        palette_idx = (element - 1) if (i % 3 != 0) else ((element + 7) % 16)
        
        # 進化段階 (1: 幼年, 2: 成熟, 3: 究極)
        tier = 1 if (i <= 200) else (2 if i <= 400 else 3)
        
        # 名前と種族設定
        p_list = PREFIXES[element]
        prefix = p_list[(i // 8) % len(p_list)]
        
        root_tuple = ROOT_CONFIGS[(i * 5 + (i // 12)) % len(ROOT_CONFIGS)]
        root_name, base_model, rec_head, rec_back, rec_tail = root_tuple
        
        suffix = SUFFIXES[(i + tier) % len(SUFFIXES)] if tier > 1 else ""
        name = f"{prefix}{root_name}{suffix}"
        
        # パーツ割り当て（進化段階や種族設定に基づく）
        head_part = rec_head
        back_part = rec_back
        tail_part = rec_tail
        
        # Tier 3 (メガ進化) の場合は王冠や翼、トゲを豪華に付与
        if tier == 3:
            if not head_part:
                head_part = CROWN if i % 2 == 0 else HORNS_DUAL
            if not back_part and base_model != BASE_QUADRUPED:
                back_part = WINGS_DRAGON if element in [1, 4, 8] else WINGS_ANGEL
            if not tail_part and base_model != BASE_FLOATING:
                tail_part = TAIL_SPIKE
        elif tier == 1:
            # 幼年期は王冠などの過剰装飾を抑えて可愛く
            if head_part == CROWN:
                head_part = ""
        
        # スケール
        base_s = 0.8 + (tier * 0.2) + (random.uniform(-0.04, 0.04))
        sx = sy = sz = round(base_s, 2)
        
        # ステータス
        base_hp = 30 + tier * 35 + random.randint(-4, 8)
        base_mp = 15 + tier * 20 + random.randint(-3, 6)
        base_atk = 10 + tier * 15 + random.randint(-2, 5)
        base_def = 8 + tier * 12 + random.randint(-2, 5)
        base_mag = 10 + tier * 14 + random.randint(-2, 5)
        base_spd = 10 + tier * 10 + random.randint(-3, 5)
        
        # 属性ボーナス
        if element == 1: # Fire: Atk+
            base_atk += 5 * tier
        elif element == 2: # Water: MP/Mag+
            base_mp += 5 * tier
            base_mag += 3 * tier
        elif element == 3: # Nature: HP/Def+
            base_hp += 8 * tier
            base_def += 3 * tier
        elif element == 4: # Electric: Spd+
            base_spd += 6 * tier
        elif element == 5: # Earth: Def+
            base_def += 6 * tier
        elif element == 6: # Wind: Spd/Atk+
            base_spd += 4 * tier
            base_atk += 2 * tier
        elif element == 7: # Light: Mag/Def+
            base_mag += 5 * tier
            base_def += 2 * tier
        elif element == 8: # Dark: Atk/Mag+
            base_atk += 4 * tier
            base_mag += 4 * tier
            
        growth = GROWTH_TYPES[i % len(GROWTH_TYPES)]
        
        # 進化先ID設定
        evo_ids_str = ""
        evo_req_lv = 0
        if tier == 1 and (i + 200) <= 500:
            evo_ids_str = f"{i + 200}"
            evo_req_lv = 15
        elif tier == 2 and (i + 100) <= 500:
            evo_ids_str = f"{i + 100}"
            evo_req_lv = 30
            
        desc = f"【第{tier}形態】{name}。古代より伝わる{prefix}の力を宿すモンスター。"
        
        row = [
            i, name, desc, element, growth,
            base_model, head_part, back_part, tail_part,
            palette_idx, sx, sy, sz,
            base_hp, base_mp, base_atk, base_def, base_mag, base_spd,
            round(random.uniform(0.8, 1.2), 2),
            round(random.uniform(0.8, 1.2), 2),
            element % 4,
            evo_ids_str, evo_req_lv
        ]
        rows.append(row)
        
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)
        
    print(f"Successfully generated {len(rows)} monsters in CSV: {output_path}")

if __name__ == "__main__":
    generate_csv("data/monsters_data.csv", count=500)

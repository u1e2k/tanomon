import struct
import zlib
import os
import csv
import random

def create_png(width, height, rgb_data, output_path):
    """
    純粋なPython（標準ライブラリのみ）でRGB PNG画像を出力するヘルパー
    """
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0) # Filter type 0 (None)
        for x in range(width):
            idx = (y * width + x) * 3
            raw_data.extend(rgb_data[idx:idx+3])
            
    def make_chunk(chunk_type, data):
        length = struct.pack(">I", len(data))
        crc = struct.pack(">I", zlib.crc32(chunk_type + data) & 0xffffffff)
        return length + chunk_type + data + crc

    png_header = b"\x89PNG\r\n\x1a\n"
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    ihdr_chunk = make_chunk(b"IHDR", ihdr_data)
    idat_chunk = make_chunk(b"IDAT", zlib.compress(raw_data))
    iend_chunk = make_chunk(b"IEND", b"")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(png_header + ihdr_chunk + idat_chunk + iend_chunk)

# 16種類の属性・系統別パレット（各16色）を定義 (16x16 = 256px)
# 0: Normal / Beast (茶・黄土)
# 1: Fire / Flame (赤・オレンジ・黄)
# 2: Water / Aqua (青・水色・紺)
# 3: Nature / Grass (緑・黄緑・森)
# 4: Electric / Thunder (黄・金・白)
# 5: Earth / Rock (岩肌・褐色・灰)
# 6: Wind / Sky (シアン・薄緑・白)
# 7: Light / Holy (白・金・パステル)
# 8: Dark / Shadow (紫・黒・深紅)
# 9: Poison / Slime (毒紫・蛍光緑)
# 10: Metal / Iron (銀・スチール・灰)
# 11: Magma / Volcano (黒曜石・溶岩橙)
# 12: Ice / Frost (氷青・淡青・純白)
# 13: Dragon / Myth (深緑・紫紺・金)
# 14: Spirit / Ghost (青紫・半透明感・ペール)
# 15: Ancient / Gold (古代金・ブロンズ)

def interpolate_color(c1, c2, factor):
    return (
        int(c1[0] + (c2[0] - c1[0]) * factor),
        int(c1[1] + (c2[1] - c1[1]) * factor),
        int(c1[2] + (c2[2] - c1[2]) * factor),
    )

palette_ramps = [
    # 0: Normal (Brown / Beige)
    [(35, 20, 10), (140, 90, 50), (220, 180, 130), (255, 240, 210)],
    # 1: Fire (Dark Red / Orange / Bright Yellow)
    [(60, 10, 0), (190, 40, 10), (255, 140, 0), (255, 240, 100)],
    # 2: Water (Navy / Deep Blue / Cyan / White)
    [(10, 20, 60), (30, 80, 180), (70, 180, 240), (210, 245, 255)],
    # 3: Nature (Dark Green / Forest / Lime / Cream)
    [(15, 45, 15), (40, 130, 40), (120, 210, 60), (220, 255, 170)],
    # 4: Electric (Amber / Gold / Bright Yellow / Pure White)
    [(60, 45, 0), (180, 130, 10), (255, 215, 0), (255, 255, 210)],
    # 5: Earth (Dark Slate / Brown / Tan / Sand)
    [(35, 25, 20), (110, 80, 60), (175, 140, 105), (235, 215, 185)],
    # 6: Wind (Teal / Sky Blue / Pale Mint / White)
    [(20, 50, 60), (50, 150, 160), (130, 220, 210), (230, 255, 250)],
    # 7: Light (Gold Shadow / Warm White / Radiant Gold / Pure White)
    [(80, 65, 30), (180, 160, 110), (255, 235, 170), (255, 255, 255)],
    # 8: Dark (Deep Purple / Violet / Crimson Accent / Pale Lilac)
    [(25, 10, 35), (80, 30, 100), (160, 50, 120), (220, 180, 230)],
    # 9: Poison (Deep Indigo / Acid Green / Neon Violet)
    [(30, 10, 45), (100, 20, 120), (80, 200, 50), (200, 255, 150)],
    # 10: Metal (Charcoal / Steel / Silver / Specular White)
    [(30, 35, 40), (85, 95, 105), (170, 185, 195), (240, 248, 255)],
    # 11: Magma (Obsidian / Dark Red / Lava Orange / Bright Yellow)
    [(20, 15, 20), (120, 20, 10), (255, 90, 0), (255, 230, 90)],
    # 12: Ice (Deep Ice / Glacier Blue / Frost White / Crystal)
    [(15, 35, 60), (60, 120, 190), (150, 215, 245), (240, 252, 255)],
    # 13: Dragon (Midnight Purple / Emerald / Dragon Gold / Flare)
    [(20, 15, 40), (20, 90, 70), (180, 150, 40), (255, 220, 150)],
    # 14: Spirit (Ghost Indigo / Soft Violet / Spectral Cyan / Pale Glow)
    [(25, 20, 50), (75, 60, 130), (120, 190, 220), (230, 245, 255)],
    # 15: Ancient Gold (Bronze / Ancient Brass / Imperial Gold / Highlight)
    [(50, 35, 15), (140, 100, 40), (225, 180, 60), (255, 245, 180)],
]

def generate_palette_png(output_path):
    width = 16
    height = 16
    data = []
    
    for row in range(height):
        ramp = palette_ramps[row]
        # 4つのキーカラーから16色を線形補間
        for col in range(width):
            t = col / 15.0 # 0.0 ~ 1.0
            # 区分け: 0~1/3 (ramp 0->1), 1/3~2/3 (ramp 1->2), 2/3~1 (ramp 2->3)
            if t <= 1.0/3.0:
                sub_t = t * 3.0
                c = interpolate_color(ramp[0], ramp[1], sub_t)
            elif t <= 2.0/3.0:
                sub_t = (t - 1.0/3.0) * 3.0
                c = interpolate_color(ramp[1], ramp[2], sub_t)
            else:
                sub_t = (t - 2.0/3.0) * 3.0
                c = interpolate_color(ramp[2], ramp[3], sub_t)
            data.extend(c)
            
    create_png(width, height, data, output_path)
    print(f"Generated palette texture: {output_path}")

if __name__ == "__main__":
    generate_palette_png("assets/palettes/monster_palettes.png")

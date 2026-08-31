# TANOMON 3D (タノモン 3D)

> **90年代N64・PS1の温もりとワクワク感を現代に再現した、レトロローポリ 3Dモンスター育成・派遣RPG**

![Godot Engine 4.x](https://img.shields.io/badge/Godot_Engine-4.x-478CBF?style=for-the-badge&logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-Static_Typing-blue?style=for-the-badge)
![Target: Android](https://img.shields.io/badge/Target-Android_Mobile-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Monsters: 500](https://img.shields.io/badge/Monsters-500_Modular_Creatures-FF6B6B?style=for-the-badge)

---

## 🎮 ゲーム概要

『TANOMON 3D（タノモン）』は、N64時代の名作『おねがいモンスター』に着想を得た、3Dモンスター育成＆派遣シミュレーションRPGです。

プレイヤーはブリーダーとしてモンスターをお世話・特訓し、各地へ「おつかい（派遣）」に出して素材や経験値を集め、ライバルモンスターとの1vs1コマンドバトルを勝ち抜いていきます。

### 🌟 主な特徴

* **N64ライクなレトロローポリ美学:**
  * ポイントサンプリング、パレットカラー共有、頂点スナップ（PS1ジッター対応）、フラットシェーディングによる懐かしくも温かみのある3Dグラフィックス。
* **全500種類のモジュラーモンスター生成システム:**
  * 「ベース素体（四足獣／二足歩行／浮遊飛行）」×「アタッチメントパーツ（角／翼／尻尾／王冠）」×「8属性カラーパレット」による動的アセンブル。
  * すべてのモンスターが固有のステータス、好物、成長曲線、進化ツリー（Lv15/Lv30）を保有。
* **充実の育成＆派遣サイクル:**
  * **ごはん（給餌）:** 4種類のフード（にく/さかな/まほう草/きのみ）。好物に応じた満腹度・機嫌ボーナス。
  * **とっくん（特訓）:** 各ステータス（HP/MP/攻撃/防御/魔力/素早さ）の強化。
  * **バイオリズム & 機嫌:** 満腹度・元気・機嫌がコマンド成功率やバトル性能に影響。
  * **おつかい（派遣システム）:** 近所の森、さばくの洞窟、天空の神殿などへモンスターを派遣。時間経過でアイテムと経験値を獲得。
* **1vs1 3Dコマンドバトル:**
  * こうげき・とくぎ・ぼうぎょ・にげる を駆使する戦略バトル。
* **3Dモンスター図鑑（3D Dex Viewer）:**
  * 全500体の3Dモデルを360度自由回転・待機／攻撃モーションで鑑賞可能。
* **スマホ・実機最適化（Google Pixel 9a等）:**
  * タッチ操作対応、パンチホール・ノッチを考慮したセーフエリアマージン（左右48px）設計、横画面（Landscape）固定。

---

## 📐 アーキテクチャ & プロジェクト構成

```
tanomon/
├── assets/
│   ├── models/
│   │   ├── bases/          # ベース素体 (四足型, 二足型, 浮遊飛行型)
│   │   └── parts/          # パーツ (角, ドラゴン翼, 天使翼, トゲ尻尾, 王冠)
│   ├── palettes/           # レトロカラーパレット (16x16 PNG)
│   └── shaders/            # N64/PS1風レトロパレットシェーダー
├── data/
│   ├── monsters/           # 全500体のMonsterData Resource (.tres)
│   └── monsters_data.csv   # モンスターマスターCSV
├── scenes/
│   ├── title/              # タイトル画面 & 3Dライブ牧場背景 & 3Dモンスター図鑑
│   ├── ranch/              # 3D牧場育成シーン
│   ├── battle/             # 1vs1 3Dコマンドバトルシーン
│   └── monster/            # ModularMonster 3Dアセンブラ
├── scripts/
│   ├── autoload/           # GameManager, MonsterDatabase, RetroSoundPlayer
│   ├── data/               # MonsterData Resource定義 (静的型付け)
│   ├── monster/            # 動的パーツ結合・アニメーション制御
│   ├── ranch/              # 育成UI・おつかい派遣マネージャー
│   ├── battle/             # バトルステートマシン・戦闘計算ロジック
│   ├── audio/              # プロシージャルレトロSE生成
│   └── tools/              # 500体CSV & .tres 自動ジェネレーター
├── export_presets.cfg      # Android向けエクスポートプリセット
├── project.godot            # 解像度・入力・Autoload設定
└── deploy_android.bat / ps1 # Androidビルド＆実機デプロイスクリプト
```

---

## 🚀 ビルド & Android実機デプロイ手順

### 前提条件
1. **Godot Engine 4.x** (標準版またはコンソール版)
2. **Android SDK / Build-Tools & ADB**
3. Android端末（USBデバッグを有効化してPCに接続）

### ワンクリック・デプロイ

#### Windows (PowerShell / コマンドプロンプト)
```powershell
.\deploy_android.ps1
# または
deploy_android.bat
```

#### 手動コマンド
```bash
# 1. APKのエクスポート
godot --headless --export-debug "Android" "build/android/tanomon.apk"

# 2. 実機へのインストール
adb install -r -d "build/android/tanomon.apk"

# 3. アプリの自動起動
adb shell monkey -p com.tanomon.game -c android.intent.category.LAUNCHER 1
```

---

## 🛠️ モンスターデータ再生成ツール (Python)

```bash
# 1. 500体のマスターCSV生成
python scripts/tools/generate_monsters_csv.py

# 2. Godot用 .tres リソースの一括書き出し
python scripts/tools/generate_tres_batch.py
```

---

## 📜 ライセンス
本プロジェクトのコードおよびアセットは、個人開発・学習・ゲーム制作のベースとして自由に改変・利用いただけます。

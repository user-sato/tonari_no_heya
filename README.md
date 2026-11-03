# となりの部屋

Godot 4.xで作る、一人称視点の静かな心理ホラー。設計資料は [`tonari_no_heya_design_v0.1/`](tonari_no_heya_design_v0.1/) を参照してください。

## 必要環境

- Godot Engine 4.x（Godot 4.6.3で検証済み）
- キーボードとマウス
- 描画方式は現在の `project.godot` に合わせて Compatibility を使用

## 起動

プロジェクトをインポートしてエディタから起動する場合は、Godot Project Managerでこのリポジトリの `project.godot` を選び、エディタの実行ボタン（F6ではなくプロジェクト実行のF5）を押します。

コマンドラインの場合：

```sh
godot4 --editor --path .
godot4 --path .
```

実行ファイル名が `godot` の環境では、上記の `godot4` を `godot` に読み替えてください。

メインシーンは `scenes/game_root.tscn` です。起動すると共用廊下から始まり、203号室を通ってベランダまで歩けます。

## 操作

| 操作 | 入力 |
|---|---|
| 移動 | WASD |
| 視点 | マウス |
| マウスカーソルの捕捉／解除 | Esc |

## M0の範囲

M0はGodotプロジェクトの土台、一人称操作、共用廊下・203号室・ベランダのグレーボックス、衝突、仮照明が対象です。202号室は外側の扉・表示・ベランダ外観だけで、内部は制作しません。調べる操作、イベント、書類、日付進行などはM1以降の範囲です。

## ディレクトリ

- `project.godot` — プロジェクト設定、入力、描画方式
- `scenes/game_root.tscn` — レベルとプレイヤーを組み合わせる起動シーン
- `scenes/levels/apartment_floor.tscn` — 共用廊下・203号室・ベランダのグレーボックス
- `scenes/player/player.tscn` — 一人称プレイヤー
- `scripts/` — GDScript
- `tonari_no_heya_design_v0.1/` — 企画・仕様・QAなどの設計資料

## 確認方法

Godot 4.xでプロジェクトを開き、エラーなく読み込めることを確認します。実行後、WASDで共用廊下から203号室へ入り、ベランダまで往復できること、マウスで視点操作できること、Escでマウスカーソルの捕捉と解除ができることを確認してください。

CLIでは次のコマンドでプロジェクトの起動とGDScriptの構文を確認できます。

```sh
godot4 --headless --path . --quit-after 30
godot4 --headless --path . --check-only --script res://scripts/player/player_controller.gd
```

Godot 4.6.3のヘッドレス検証では、メインシーンの起動、入力設定、主要ノード、衝突形状、および廊下からベランダまでの往復を確認済みです。照明の見え方、マウス操作、入口付近の引っかかりはGUIでの最終確認が必要です。

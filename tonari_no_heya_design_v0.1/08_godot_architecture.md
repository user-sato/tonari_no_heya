# 08. Godot 4 実装アーキテクチャ

## 推奨方針

**Godot 4.x + GDScript + Forward+ または Compatibility（PC性能に応じて選定）**。初期は標準機能だけで成立させる。3D室内、UI、イベント、音を分離し、シナリオの修正をコード変更に直結させない。

## ディレクトリ案

```text
res://
  scenes/
    main_menu.tscn
    game_root.tscn
    levels/apartment_floor.tscn
    levels/room_203.tscn
    levels/corridor.tscn
    levels/balcony_203.tscn
    player/player.tscn
    ui/hud.tscn
    ui/document_viewer.tscn
    ui/notebook.tscn
    ui/pause_menu.tscn
  scripts/
    autoload/game_state.gd
    autoload/event_director.gd
    autoload/save_manager.gd
    player/player_controller.gd
    interaction/interactable.gd
    interaction/interaction_ray.gd
    interaction/document_interactable.gd
    systems/audio_director.gd
    systems/day_director.gd
  data/
    documents/
    dialogues/
    events/
  assets/
    models/
    textures/
    audio/
    fonts/
  tests/
```

## ノードの概略

```text
GameRoot (Node3D)
├── ApartmentFloor (Node3D)
│   ├── Corridor
│   ├── Room203
│   ├── Balcony203
│   └── Triggers
├── Player (CharacterBody3D)
│   ├── CollisionShape3D
│   └── Head (Node3D)
│       ├── Camera3D
│       └── InteractionRay (RayCast3D)
├── AudioDirector (Node)
├── DayDirector (Node)
└── UI (CanvasLayer)
    ├── InteractionPrompt
    ├── DocumentViewer
    ├── Notebook
    └── FadeOverlay
```

## 責務分担

| モジュール | 責務 | 禁止する責務 |
|---|---|---|
| `GameState` | 日付・フラグ・既読情報 | 音の再生・UI直接操作 |
| `EventDirector` | イベントの条件判定・順序 | プレイヤーの移動処理 |
| `DayDirector` | 日付ごとの照明・家具状態 | 書類ビューの描画 |
| `InteractionRay` | 対象の検出・E入力 | シナリオ進行の直接書き換え |
| `DocumentViewer` | ページ表示・既読通知 | ノック音の再生 |
| `AudioDirector` | 環境音・ノック・通話加工 | フラグの永続化 |
| `SaveManager` | 状態の保存・読込・移行 | 物語上の解釈 |

## シグナル契約（例）

```gdscript
# interactable.gd
class_name Interactable
extends Node3D
signal interacted(interaction_id: StringName)
@export var interaction_id: StringName
@export var prompt_text: String = "調べる"
func interact() -> void:
    interacted.emit(interaction_id)
```

```gdscript
# game_state.gd（Autoload、骨格）
extends Node
signal flag_changed(flag_name: StringName, value: bool)
var day_index: int = 1
var flags: Dictionary = {}
func has_flag(name: StringName) -> bool:
    return bool(flags.get(name, false))
func set_flag(name: StringName, value: bool = true) -> void:
    if has_flag(name) == value:
        return
    flags[name] = value
    flag_changed.emit(name, value)
```

**注**：コードはインターフェースの例で、動作確認済みの完成コードではない。実装時にクラス参照・ノード接続・型を検証する。

## イベント実装の考え方

- `EventDirector`は`flag_changed`と`interacted`を受け、現在の`day_index`と前提条件を確認。
- 一度きりのイベントは発火直前に`evt_*_started`を立て、終了後に`evt_*_complete`を立てる。
- 演出中に入力をロックする場合は、ロック解除の責務を明確にする。
- 時間待ちだけで進行する演出には、再ロード時の復帰先を決める。
- 書類の本文・字幕・電話台本は外部リソース（JSON/Resource）で保持。

## 最初の実装順

1. 3Dプレイヤー＋衝突＋マウス視点。
2. 廊下・203・ベランダのグレーボックス。
3. Eで調べる→文書ビュー→Escで閉じる。
4. `GameState`と`EventDirector`の最小版。
5. 郵便→ノック→202扉→契約書→連絡→就寝。
6. 最後にPS1風ポストプロセスを追加。**画質演出を先に作り込まない**。

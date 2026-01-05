---
name: dev
description: 設計・実装・コミットを統合したDevコマンド（Devタブ用）
argument-hint: "<feature> | continue | commit"
---

あなたは Claude Code の開発担当（Dev）です。

## モード別の動作

### `/dev <feature>` - 新規機能開始

`/design` スキルを実行:
1. `ai/specs/<feature>/` にドキュメント作成
2. `ai/board.md` を更新
3. 設計完了後、実装へ移行

### `/dev continue` - 作業継続

`/implement` スキルを実行:
1. `ai/board.md` から現在の機能を確認
2. `ai/specs/<feature>/tasks.md` の未完了タスクに着手
3. 進捗を反映

### `/dev commit` - コミット作成

`/commit` スキルを実行:
1. `git diff --staged` を分析
2. コミット計画を提案
3. 確認後、コミット実行

### `/dev pr` - PR作成

`/pr` スキルを実行:
1. コミット済みの変更を確認
2. PRタイトル・本文を提案
3. 確認後、push + PR作成

## 権限

- ファイル編集: あり
- git操作: あり（add, commit）
- git push: なし（ユーザーが明示的に依頼した場合のみ）

## スキル一覧

| スキル | 役割 |
|--------|------|
| `/design` | 設計フェーズ（要件定義・設計判断・タスク分解） |
| `/implement` | 実装フェーズ（コード実装・テスト追加） |
| `/commit` | コミット計画・実行 |
| `/pr` | PR作成（push確認 + gh pr create） |

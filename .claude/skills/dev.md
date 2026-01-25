---
name: dev
description: 設計・TDD実装・コミットを統合した開発スキル
argument-hint: "<feature> | commit | pr"
---

あなたは Claude Code の開発担当（Dev）です。

## モード別の動作

### `/dev <feature>` - 新規機能開始

`/design` スキルを実行:
1. `ai/specs/<feature>/` にドキュメント作成
2. **TaskCreate** でTDDフェーズごとに実装タスクを作成
3. `ai/board.md` の Current Work を更新
4. `ai/board.md` の Active Tasks にTask ID参照を追加
5. 設計完了後、実装へ移行

**TaskCreate時のテンプレート:**
```
subject: "[Red] <機能名> - テスト作成"
description: |
  対象: <ファイルパス>
  期待動作: <期待する振る舞い>
  テストケース: <具体的なテストケース>
activeForm: "<機能名>テスト作成中"
```

### `/dev` (引数なし) - TDD実装

TDD実装は **常に** `tdd-executor` エージェントに委譲する。

**Claude 本体の役割:**

1. **TaskList** で現在のタスク状況を確認
2. `ai/board.md` から現在の機能を確認
3. `ai/specs/<feature>/tasks.md` の進捗状況を把握
4. **TaskUpdate** で対象タスクを `in_progress` に更新
5. `tdd-executor` エージェントを呼び出し

**エージェント呼び出し:**

Task tool を使用:

- `subagent_type`: `tdd-executor`
- `prompt`: `ai/specs/<feature>/tasks.md の未完了シナリオをTDDで実装してください`

エージェントが TDD サイクル（Red→Green→Refactor）を自動連鎖実行し、進捗を報告する。

**エージェント完了後:**

1. 実装結果を確認
2. **TaskUpdate** で完了タスクを `completed` に更新
3. `ai/specs/<feature>/tasks.md` の進捗を更新
4. `ai/board.md` の Active Tasks を簡潔に更新（Task ID + Phase + Status）

### `/dev commit` - コミット作成

`/commit` スキルを実行:
1. `git diff --staged` を分析
2. コミット計画を提案
3. 確認後、コミット実行
4. 対応するTaskを **TaskUpdate** で `completed` に更新
5. `ai/board.md` の History に記録

### `/dev pr` - PR作成

`/pr` スキルを実行:
1. コミット済みの変更を確認
2. PRタイトル・本文を提案
3. 確認後、push + PR作成

## 原則

- **TDD実装は tdd-executor に委譲**（コンテキスト節約）
- ビジネスロジックは必ず `app/packages/` 配下へ配置
- Packwerkの公開API方針を尊重
- 変更が他パッケージに影響する場合は依存関係への影響を説明
- 仕様差異が生じた場合は関連ドキュメントも更新

## 権限

- ファイル編集: あり
- git操作: あり（add, commit）
- git push: なし（ユーザーが明示的に依頼した場合のみ）

## スキル一覧

| スキル | 役割 |
|--------|------|
| `/design` | 設計フェーズ（要件定義・設計判断・タスク分解） |
| `/commit` | コミット計画・実行 |
| `/pr` | PR作成（push確認 + gh pr create） |

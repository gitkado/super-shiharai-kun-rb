---
name: implement
description: TDDで実装を進めるスキル（Red→Green→Refactor）
---

あなたは設計指針を忠実にTDDで実装へ落とし込む担当です。

## 役割

- 設計ドキュメント（ai/specs/<feature>/）を参照し、矛盾があれば質問してから作業
- **TDDサイクル（Red→Green→Refactor）を厳守**
- ビジネスロジックは必ず `app/packages/` 配下へ配置

## 自動実行モード（推奨）

複数のテストシナリオを連続実行する場合は、`tdd-executor` エージェントに委譲する。

Task tool を使用:

- `subagent_type`: `tdd-executor`
- `prompt`: `ai/specs/<feature>/tasks.md のテストシナリオを順に実装してください`

エージェントが TDD サイクル（Red→Green→Refactor）を自動連鎖実行し、進捗を報告する。

## TDDワークフロー（手動実行時）

### 1. Red Phase（テストを先に書く）

1. `ai/specs/<feature>/tasks.md` のテストシナリオを1つ選択
2. 失敗するテストを書く（specファイル作成・更新）
3. テストが失敗することを確認:

   ```bash
   bundle exec rspec <spec_file>:<line>
   ```

4. 失敗を確認したら Green Phase へ

### 2. Green Phase（最小限の実装）

1. テストを通す**最小限**のコードを実装
2. テストが成功することを確認:

   ```bash
   bundle exec rspec <spec_file>:<line>
   ```

3. 成功したら Refactor Phase へ

### 3. Refactor Phase（品質改善）

1. コード品質を改善（DRY、命名、責務分割）
2. テストが通ることを確認:

   ```bash
   bundle exec rspec <spec_file>
   ```

3. コードスタイルを整形:

   ```bash
   bundle exec rubocop -a <files>
   ```

4. 次のシナリオへ（1. Red Phase に戻る）

## 前提

### 参照ドキュメント

- `ai/specs/<feature>/requirements.md` - 要件定義
- `ai/specs/<feature>/design.md` - 設計判断
- `ai/specs/<feature>/tasks.md` - TODOリスト・テストシナリオ

### 品質ゲート

- `bundle exec rspec` - テストがグリーン
- `bundle exec rubocop` - スタイル違反なし
- `bundle exec packwerk check` - 境界違反なし
- `bundle exec brakeman -q` - セキュリティ警告なし

## 原則

- **テストを先に書く**（TDD厳守）
- Packwerkの公開API方針を尊重
- 変更が他パッケージに影響する場合は依存関係への影響を説明
- 仕様差異が生じた場合は関連ドキュメントも更新

## 成果物

### 1. コード実装（TDDサイクルごと）

- `spec/` 配下にテスト（Red Phase）
- `app/packages/<domain>/` 配下に実装（Green Phase）
- リファクタリング済みコード（Refactor Phase）

### 2. ai/specs/<feature>/tasks.md を更新

- 完了したテストシナリオにチェック
- 実施結果・確認済みテスト・残課題を追記

### 3. ai/board.md を更新

- Active Tasks に進捗を反映
- 現在のTDDフェーズを明示（例: `[Red] ユーザー登録テスト作成中`）

## 回答フォーマット

### TDDサイクル報告

```markdown
## TDD Cycle #N - <シナリオ名>

### Red Phase
- テストファイル: `spec/...`
- 失敗確認: `bundle exec rspec ...` → FAIL (expected)

### Green Phase
- 実装ファイル: `app/packages/...`
- 成功確認: `bundle exec rspec ...` → PASS

### Refactor Phase
- 改善内容: ...
- RuboCop: PASS
```

### サイクル完了時

1. **実装内容の概要とファイル一覧**
2. **変更理由と設計との整合性**
3. **残課題やフォローアップ**

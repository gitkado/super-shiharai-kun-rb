---
name: commit
description: コミット計画を策定・実行（TDD単位のコミット推奨）
disable-model-invocation: true
---

あなたはコミット職人です。ステージ済みの diff を元に Conventional Commits 準拠のコミット計画を提案・実行します。

## 役割

- `git diff --staged` を分析
- CLAUDE.md のコミット分割ポリシーに従って分割
- **TDD単位でのコミット分割を推奨**
- 各コミットのタイトルを作成（1行のみ）
- コミットを実行（確認プロンプトあり）

## コミットメッセージ形式

- **1行のみ**（本文は書かない）
- **スコープなし**: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`
- 50〜72文字以内、日本語で要約
- 例:
  - `feat: ユーザー認証APIを追加`
  - `fix: ログイン時のエラーハンドリングを修正`
  - `chore: 依存関係を更新`

## TDD単位のコミット推奨

TDDサイクルごとにコミットを分割:

```
1. test: テストケース追加
   → Red Phase 完了時

2. feat: 機能実装
   → Green Phase 完了時

3. refactor: リファクタリング
   → Refactor Phase 完了時（変更がある場合のみ）
```

### TDDコミットの例

```
# Red Phase
test: 請求書承認APIのテストを追加

# Green Phase
feat: 請求書承認APIを実装

# Refactor Phase
refactor: 承認ロジックをサービスに抽出
```

## 分割基準

### 優先的に分離する対象

以下のファイルは単独コミットとして分離:

- `db/migrate/*.rb` → `chore: マイグレーションを追加`
- `db/schema.rb` → `chore: スキーマを更新`
- `Gemfile.lock` → `chore: 依存関係を更新`
- `swagger/**/*.yaml` → `chore: API仕様書を更新`
- `config/routes.rb` → `chore: ルーティングを更新`

### パッケージ単位

- `app/packages/<domain>/` ごとにコミットを分ける
- 例:
  - `feat: 承認APIを追加`
  - `test: 承認APIの異常系テストを追加`

## 禁止事項

- Co-Authored-By トレーラーは含めない
- git push は行わない（ユーザーが明示的に依頼した場合のみ）

## 回答フォーマット

1. **全体サマリ**（変更概要）
2. **コミット計画**（タイトル、対象ファイル）
3. **実行確認**（ユーザーに確認後、コミット実行）

### コミット計画の例

```markdown
## コミット計画

### Commit 1
**タイトル**: test: 請求書承認APIのテストを追加

**対象ファイル**:
- spec/requests/api/v1/invoices/approve_spec.rb

---

### Commit 2
**タイトル**: feat: 請求書承認APIを実装

**対象ファイル**:
- app/packages/invoice/app/controllers/api/v1/invoices/approvals_controller.rb
- config/routes.rb
```

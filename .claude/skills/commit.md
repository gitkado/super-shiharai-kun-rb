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
- 各コミットのタイトル・本文を作成
- コミットを実行（確認プロンプトあり）

## TDD単位のコミット推奨

TDDサイクルごとにコミットを分割することを推奨:

```
1. test(pack-<domain>): テストケース追加
   → Red Phase 完了時

2. feat(pack-<domain>): 機能実装
   → Green Phase 完了時

3. refactor(pack-<domain>): リファクタリング
   → Refactor Phase 完了時（変更がある場合のみ）
```

### TDDコミットの例

```
# Red Phase
test(pack-invoice): 請求書承認APIのテストを追加

# Green Phase
feat(pack-invoice): 請求書承認APIを実装

# Refactor Phase
refactor(pack-invoice): 承認ロジックをサービスに抽出
```

## 分割基準

### 優先的に分離する対象

- `db/migrate/*.rb` → `chore(migration)` または `feat(db)`
- `db/schema.rb` → `chore(schema)`
- `Gemfile.lock` → `chore(lockfile)`
- `swagger/**/*.yaml` → `chore(swagger)`
- `config/routes.rb` → `chore(routes)`

### パッケージ単位

- `app/packages/<domain>/` ごとにコミットを分ける
- 実装: `feat(pack-<domain>)` / `fix(pack-<domain>)` / `refactor(pack-<domain>)`
- テスト: `test(pack-<domain>)`

## コミットメッセージ形式

### タイトル

- 50〜72文字以内、日本語で要約
- Conventional Commits準拠: `feat|fix|refactor|test|docs|chore`

### 本文

```
- Before: ...
- After: ...
- 影響: ...
- rollback: ...
- Related: #123
```

## 禁止事項

- Co-Authored-By トレーラーは含めない
- git push は行わない（ユーザーが明示的に依頼した場合のみ）

## 回答フォーマット

1. **全体サマリ**（変更概要・想定リスク）
2. **コミット計画**（タイトル、本文、対象ファイル）
   - TDD単位での分割を明示
3. **実行確認**（ユーザーに確認後、コミット実行）

### コミット計画の例

```markdown
## コミット計画

### Commit 1: test(pack-invoice)
**タイトル**: test(pack-invoice): 請求書承認APIのリクエストスペックを追加

**対象ファイル**:
- spec/requests/api/v1/invoices/approve_spec.rb

**本文**:
- Before: 承認APIのテストなし
- After: 正常系・異常系のテストを追加
- Related: #42

---

### Commit 2: feat(pack-invoice)
**タイトル**: feat(pack-invoice): 請求書承認APIを実装

**対象ファイル**:
- app/packages/invoice/app/controllers/api/v1/invoices/approvals_controller.rb
- config/routes.rb

**本文**:
- Before: 承認機能なし
- After: POST /api/v1/invoices/:id/approve で承認可能
- rollback: revert可
- Related: #42
```

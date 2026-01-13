# AI Development Board

> Claude Codeの /dev と /verify コマンドが共同で使用する作業ボード。
> 編集権限は Dev のみ。Verify は結果報告を行い、Dev が反映する。

---

## Current Work

| Feature | Spec Path | Status | Branch |
|---------|-----------|--------|--------|
| - | - | idle | - |

**Status**: `idle` | `planning` | `implementing` | `reviewing` | `completed`

---

## Active Tasks

<!-- Dev が更新するタスクリスト -->
<!-- TDDフェーズを明示: [Red] [Green] [Refactor] -->

_現在アクティブなタスクはありません_

### Active Tasks の記載例

```markdown
- [x] 設計完了
- [ ] [Red] ユーザー登録テスト作成中
- [ ] [Green] ユーザー登録実装
- [ ] [Refactor] リファクタリング
```

---

## Verify Log

<!-- Verify からの報告を Dev が追記 -->
<!-- フォーマット: 日時 - コマンド - 結果テーブル - アクション -->

_レビュー・テスト結果はここに記録されます_

### Verify Log の記載例

```markdown
### 2026-01-04 15:30 - /verify full

| Check | Status | Summary |
|-------|--------|---------|
| Test | PASS | 42 examples, 0 failures |
| Lint | PASS | 0 offenses |
| Review | PASS | 指摘なし |

**Action Required**: なし
```

```markdown
### 2026-01-04 14:00 - /verify test

| Check | Status | Summary |
|-------|--------|---------|
| Test | FAIL | 42 examples, 2 failures |

**Action Required**: [要対応] spec/requests/users_spec.rb:15, :42 を修正
```

---

## Completed Features

<!-- 完了した機能の記録 -->

### 認証機能（authentication） ✅

- **Spec Path**: `ai/specs/authentication/`
- **完了日**: 2025-10-24
- **実装方針**: BCrypt + JWT gem 直接利用
- **テスト結果**: 122 examples, 0 failures
- **エンドポイント**:
  - `POST /api/v1/auth/register` - ユーザー登録
  - `POST /api/v1/auth/login` - ログイン

### 請求書管理機能（invoice-management） ✅

- **Spec Path**: `ai/specs/invoice-management/`
- **完了日**: 2026-01-03
- **テスト結果**: 122 examples, 0 failures
- **エンドポイント**:
  - `POST /api/v1/invoices` - 請求書登録（手数料自動計算）
  - `GET /api/v1/invoices` - 請求書一覧取得（期間検索対応）

### VS Code + Ruby LSP導入（vscode-lsp-setup） 🔄

- **Spec Path**: `ai/specs/vscode-lsp-setup/`
- **ステータス**: フェーズ1 80%完了
- **完了項目**:
  - [x] Gemfileにruby-lsp追加
  - [x] `.vscode/settings.json` 作成
  - [x] Zeitwerkチェック完了
- **残タスク**:
  - [ ] 開発者によるVS Code拡張インストール（手動）
  - [ ] 動作確認（手動）

---

## History

<!-- 作業履歴 -->

- 2026-01-13: Spec進捗を最新化（authentication完了、invoice-management完了、vscode-lsp-setup 80%）
- 2026-01-04: ボード初期化

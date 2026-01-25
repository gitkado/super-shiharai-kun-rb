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

> 詳細は `TaskList` ツールで確認。Task機能はセッション内の実行管理に使用。
> 長期プロジェクトの記録は `ai/specs/<feature>/tasks.md` に永続化。

| Task ID | Subject | TDD Phase | Status | Notes |
|---------|---------|-----------|--------|-------|
| - | - | - | - | - |

<!--
Task ID参照形式の記載例:
| #1 | 計算カラム監視戦略改善 | Red | in_progress | テスト作成中 |
| #2 | InvoiceItem更新時の再計算 | pending | pending | #1完了後に着手 |
-->

---

## Priority Matrix（重要度×緊急度）

|  | 緊急（今すぐ対応） | 非緊急（計画的に対応） |
|---|---|---|
| **重要** | **FIXME: 計算カラム監視戦略**（`app/packages/invoice/app/models/invoice.rb:30`）<br>影響: 明細更新時に親再計算が走らず整合性崩壊の可能性 | **請求書機能拡張（MVP次段）**<br>優先度高: 更新・削除API（早めに欲しい）<br>優先度中: ステータス管理・承認フロー（後回し可）<br>優先度低: PDF生成・支払い実行・ページネーション |
| **重要ではない** | **（該当なし）** | **TODO: Serializer導入検討**（`app/packages/invoice/app/controllers/api/v1/invoices_controller.rb:58`）<br>API数増加時に負債化の可能性 |

**補足（整備系）**

- VS Code LSP フェーズ2-4（vendor/bundle設定 / RBS・Steep / ドキュメント）は「重要だが緊急ではない」位置づけ。RBS/Steepは「あれば良い」レベルのため後回しでOK。

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

- 2026-01-25: Task機能とboard.mdの統合（Active TasksをTask ID参照形式に簡略化、dev.mdにTaskCreate/TaskUpdate追加）
- 2026-01-13: Spec進捗を最新化（authentication完了、invoice-management完了、vscode-lsp-setup 80%）
- 2026-01-24: 優先度マトリクス更新（FIXME最優先、請求書拡張は計画対応、Serializer検討は後回し）
- 2026-01-04: ボード初期化

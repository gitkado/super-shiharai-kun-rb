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

## History

<!-- 作業履歴 -->

- 2026-01-04: ボード初期化

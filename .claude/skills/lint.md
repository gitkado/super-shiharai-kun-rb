---
name: lint
description: 品質チェックスキル（RuboCop・Packwerk・Brakeman）
---

静的解析とセキュリティチェックを一括実行するスキルです。

## 実行コマンド

```bash
bundle exec rubocop && bundle exec packwerk check && bundle exec brakeman -q
```

## チェック内容

| ツール | 役割 |
|--------|------|
| RuboCop | コードスタイル、簡易的な不具合検知 |
| Packwerk | パッケージ境界の依存関係違反 |
| Brakeman | Rails向けセキュリティ診断 |

## 報告形式

チェック完了後、以下の形式で報告:

```markdown
### Lint Results

| Tool | Status | Issues |
|------|--------|--------|
| RuboCop | PASS/FAIL | X offenses |
| Packwerk | PASS/FAIL | X violations |
| Brakeman | PASS/FAIL | X warnings |
```

### 違反がある場合の追加報告

```markdown
#### RuboCop Offenses

| File | Line | Cop | Message | Auto-fix |
|------|------|-----|---------|----------|
| app/... | 42 | Style/... | ... | Yes/No |

#### Packwerk Violations

| From | To | Type |
|------|-----|------|
| pack-A | pack-B | dependency |

#### Brakeman Warnings

| Severity | File | Warning |
|----------|------|---------|
| High | app/... | SQL Injection |
```

## Verify Log用テンプレート

`/verify` から呼ばれた場合、以下を報告テンプレートとして出力:

```markdown
### YYYY-MM-DD HH:MM - /verify lint

| Check | Status | Summary |
|-------|--------|---------|
| Lint | PASS/FAIL | RuboCop: X, Packwerk: X, Brakeman: X |

**Action Required**: なし / [要対応] 違反を修正
```

## 失敗時の対応

違反が検出された場合:

1. 違反内容と該当箇所を報告
2. 自動修正可能な場合は `rubocop -a` を提案
3. 修正が必要な場合は Dev に依頼（Verify モードの場合）
4. または直接修正（Dev モードの場合）

## 自動修正オプション

```bash
# 安全な自動修正
bundle exec rubocop -a

# 全ての自動修正（破壊的変更を含む）
bundle exec rubocop -A
```

## TDDでの活用

### Refactor Phase での使用

```bash
# リファクタリング後にスタイル違反を修正
bundle exec rubocop -a app/packages/<domain>/

# 境界違反がないことを確認
bundle exec packwerk check app/packages/<domain>/
```

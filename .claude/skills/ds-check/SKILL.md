---
name: ds-check
description: SmartHR Design System準拠チェック。コード解析とブラウザ検証でsmarthr-uiの使い方を確認する。
argument-hint: "[code|browser|full] [path]"
---

# SmartHR Design System 準拠チェック

## 重要な制約

- ファイル編集: 禁止
- git操作: 禁止
- 読み取り専用（レポートのみ出力）

## モード

| モード | 説明 |
|--------|------|
| `code` | コード静的解析のみ（Grep/Globベース） |
| `browser` | ブラウザ視覚検証のみ（dev server必須） |
| `full`（デフォルト） | code + browser |

引数にパスが指定された場合はそのパスのみチェック。省略時は `frontend/src/` 全体。

## 実行方法

`ds-checker` エージェントに委譲する（Task tool使用）。

```text
Task tool (subagent_type: ds-checker) に以下を渡す:
- mode: code / browser / full
- path: チェック対象パス（デフォルト: frontend/src/）
```

## レポート形式

エージェントから返却されるレポートをそのまま表示する。

```markdown
# SmartHR DS Compliance Report

| Phase | Status | Issues |
|-------|--------|--------|
| Code Analysis | PASS/FAIL | N violations |
| Browser Check | PASS/FAIL/SKIP | N issues |

## Code Analysis Findings

| Severity | File | Line | Rule | Issue | Suggestion |
|----------|------|------|------|-------|------------|

## Browser Verification Findings

| Page | Console Errors | Visual Issues |
|------|----------------|---------------|

## Summary
- BLOCKER: N件 / MUST: N件 / NICE: N件
```

Severity levels（`/verify` と統一）:

- **[BLOCKER]**: DS違反、即修正必須（素のHTML要素の使用など）
- **[MUST]**: 推奨パターン違反（冗長なprop、不正なprop使用）
- **[NICE]**: 改善推奨（レイアウトコンポーネント未使用など）

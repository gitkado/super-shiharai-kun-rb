---
name: test
description: RSpec実行とテスト結果報告スキル
---

RSpec を実行してテスト結果を報告するスキルです。

## 実行コマンド

```bash
bundle exec rspec ${args:-}
```

## 使用方法

| 呼び出し | 動作 |
|----------|------|
| `/test` | 全テスト実行 |
| `/test spec/path/to_spec.rb` | 指定ファイルのみ |
| `/test spec/path/to_spec.rb:42` | 指定行のみ |
| `/test --fail-fast` | 最初の失敗で停止 |

## 報告形式

テスト完了後、以下の形式で報告:

```markdown
### Test Results

- Command: `bundle exec rspec ...`
- Status: PASS / FAIL
- Summary: XX examples, X failures, X pending
- Coverage: XX% (SimpleCov)
- Duration: X.XX seconds
```

### 失敗時の追加報告

```markdown
#### 失敗詳細

| Spec | Line | Error |
|------|------|-------|
| spec/requests/... | 42 | Expected 200, got 404 |
| spec/models/... | 15 | undefined method `foo` |

#### 診断ガイダンス

- **原因の可能性**: ...
- **確認すべき箇所**: ...
- **推奨アクション**: ...
```

## Verify Log用テンプレート

`/verify` から呼ばれた場合、以下を報告テンプレートとして出力:

```markdown
### YYYY-MM-DD HH:MM - /verify test

| Check | Status | Summary |
|-------|--------|---------|
| Test | PASS/FAIL | XX examples, X failures |

**Action Required**: なし / [要対応] 失敗テストを修正
```

## 失敗時の対応

テストが失敗した場合:

1. エラーメッセージと失敗箇所を報告
2. 失敗原因の診断ガイダンスを提供
3. 修正が必要な場合は Dev に依頼（Verify モードの場合）
4. または直接修正（Dev モードの場合）

## TDDでの活用

### Red Phase での使用

```bash
# 失敗することを確認
bundle exec rspec spec/path/to_spec.rb:42
# → FAIL (expected)
```

### Green Phase での使用

```bash
# 成功することを確認
bundle exec rspec spec/path/to_spec.rb:42
# → PASS
```

### Refactor Phase での使用

```bash
# リファクタリング後も成功を確認
bundle exec rspec spec/path/to_spec.rb
# → PASS (all examples)
```

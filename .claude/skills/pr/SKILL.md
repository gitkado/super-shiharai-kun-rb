---
name: pr
description: PR作成（push確認 + gh pr create）
disable-model-invocation: true
---

あなたはPR作成担当です。コミット済みの変更をGitHubにpushし、PRを作成します。

## 前提条件

- 作業ブランチにコミットが存在すること
- mainブランチではないこと

## フロー

### 1. 状況確認

以下を確認して報告:

```bash
# 現在のブランチ
git branch --show-current

# mainからのコミット一覧
git log origin/main..HEAD --oneline

# リモートとの差分
git status
```

### 2. PRタイトル・本文の作成

コミット履歴と `ai/specs/<feature>/` のドキュメントを参照して:

- **タイトル**: 変更の要約（50文字以内）
- **本文**: `.github/pull_request_template.md` の形式に従う

### 3. push確認

**必ずユーザーに確認を求める**:

```text
以下の内容でpush + PR作成を行います。よろしいですか？

ブランチ: feature/xxx
コミット数: N件
PRタイトル: ...

[実行する / キャンセル]
```

### 4. 実行

承認後:

```bash
# push（force pushは絶対に使わない）
git push -u origin <branch-name>

# PR作成
gh pr create --title "..." --body "..." --base main
```

### 5. 結果報告

- PR URLを表示
- `ai/board.md` にPR情報を記録（任意）

## 禁止事項

- `git push --force` は絶対に行わない
- mainブランチへの直接pushは禁止
- ユーザー確認なしのpushは禁止

## PR本文テンプレート

```markdown
## Summary
<!-- ai/specs/<feature>/requirements.md から要約 -->

## Changes
<!-- コミット履歴から主な変更点 -->

## Test Plan
<!-- ai/specs/<feature>/tasks.md のテスト項目 -->

## Related Issues
<!-- 関連Issue -->
```

## エラー対応

### pushが失敗した場合

```bash
# リモートの変更を確認
git fetch origin main

# 差分を確認
git log HEAD..origin/main --oneline
```

rebaseが必要な場合はユーザーに報告し、手動対応を促す。

### gh認証エラー

```bash
gh auth status
```

認証されていない場合は `gh auth login` を案内。

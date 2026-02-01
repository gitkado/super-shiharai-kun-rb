---
name: create-pr
description: MUST use this skill to create or update pull requests. PR作成・更新（push + gh pr create/edit）。Trigger words include: PR作成, PR更新, プルリクエスト, create-pr.
argument-hint: "[update]"
---

あなたはPR作成・更新担当です。コミット済みの変更をGitHubにpushし、PRを作成または更新します。

## 重要な制約

- ファイル編集: 禁止
- git操作: push可（force push禁止）
- mainブランチへの直接push: 禁止
- ユーザー確認なしのpush: 禁止

## モード

| 引数 | 動作 |
|------|------|
| なし | 新規PR作成 |
| `update` | 既存PRの本文更新 |

## 新規PR作成フロー

### 1. 状況確認

```bash
git branch --show-current
git log origin/main..HEAD --oneline
git status
```

### 2. マージ先（base）の決定

- デフォルト: `main`
- ユーザーが明示的に指定した場合はそちらを使用
- `git log --oneline main..HEAD` でコミットが0件の場合、別のベースブランチを探す:

```bash
git branch -a --merged HEAD | grep -v HEAD
```

最終的にマージ先が不明な場合は **ユーザーに確認** する。

### 3. PR本文の生成

`.github/pull_request_template.md` を読み取り、そのセクション構成に従って本文を生成する。

コミット履歴と差分を分析し、各セクションを埋める:

```bash
git log <base>..HEAD --oneline
git diff <base>..HEAD --stat
```

`ai/specs/<feature>/` にドキュメントがあれば参照する。

### 4. スクリーンショットセクション

フロントエンド変更の有無を検出する:

```bash
git diff <base>..HEAD --name-only | grep '^frontend/'
```

**変更がある場合:**

ルーティング定義ファイル（`frontend/src/App.tsx` 等）を読み取り、各画面のパスを抽出して貼り付けプレースホルダーを生成する:

```markdown
## スクリーンショット/動画（Before / After）

<!-- TODO: 以下の画面キャプチャを貼り付けてください -->

### ログイン画面 (`/login`)
<!-- ここにスクリーンショットを貼り付け -->

### 請求書一覧画面 (`/invoices`)
<!-- ここにスクリーンショットを貼り付け -->
```

**変更がない場合:**

```markdown
## スクリーンショット/動画（Before / After）

該当なし
```

### 5. ユーザー確認

**必ず確認を求める:**

```text
以下の内容でpush + PR作成を行います。よろしいですか？

ブランチ: <branch>
マージ先: <base>
コミット数: N件
PRタイトル: ...

[実行する / キャンセル]
```

### 6. 実行

承認後:

```bash
git push -u origin <branch>
gh pr create --title "..." --body "..." --base <base>
```

### 7. 結果報告

- PR URLを表示

## 既存PR更新フロー (`update`)

### 1. 現在のPR情報を取得

```bash
gh pr view --json title,body,baseRefName,url
```

PRが見つからない場合はエラーを報告して終了。

### 2. PR本文の再生成

新規作成フローの手順3〜4と同様に、最新のコミット差分を反映してPR本文を再生成する。

### 3. ユーザー確認

変更前後の差分を提示し、確認を求める。

### 4. 実行

```bash
git push
gh pr edit <number> --title "..." --body "..."
```

### 5. 結果報告

- PR URLを表示

## エラー対応

### pushが失敗した場合

```bash
git fetch origin <base>
git log HEAD..origin/<base> --oneline
```

rebaseが必要な場合はユーザーに報告し、手動対応を促す。

### gh認証エラー

```bash
gh auth status
```

認証されていない場合は `gh auth login` を案内。

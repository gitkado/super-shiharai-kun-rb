---
name: commit-plan
description: ステージ済み差分を収集しコミット計画用の diff を生成するコマンド
command: >-
  bash -lc 'mkdir -p .claude && git diff --staged --unified=0 --no-color | tee .claude/.last_staged.diff >/dev/null && echo "[PLAN_READY] ステージ済み差分を .claude/.last_staged.diff に保存しました。committer にプラン作成を依頼してください。"'
---
`/commit-plan` は現在ステージされている変更を `.claude/.last_staged.diff` に書き出し、committer サブエージェントへコミット分割プランを依頼する準備を整えます。

手順:
- 必要な変更を `git add` でステージする
- `/commit-plan` を実行し、生成メッセージ `[PLAN_READY] ...` を確認
- 続けて committer にプラン作成を依頼する（例: `/committer`）

ステージが空の場合は diff が生成されないため、コミット計画前に対象ファイルが追加済みか確認してください。

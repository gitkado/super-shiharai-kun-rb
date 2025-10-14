---
name: commit-apply
description: committer が用意したコミットプランを順次適用するコマンド
command: >-
  bash -lc 'set -e; test -f .claude/.commit_plan.sh || { echo "No plan. Run /commit-plan and ask committer to write .claude/.commit_plan.sh"; exit 1; }; bash .claude/.commit_plan.sh'
---
`/commit-apply` は `.claude/.commit_plan.sh` に記述されたコミット手順をそのまま実行します。コミット粒度や順序は committer の提案に従います。

利用手順:
- `/commit-plan` → committer によるプラン生成 → 内容確認
- 問題なければ `/commit-apply` 実行（各ステップで確認プロンプトが出る場合があります）

中断する場合はプロンプトでキャンセルし、必要に応じて `.claude/.commit_plan.sh` を編集して再実行してください。コミット実行前にテスト・Lint が通っていることを確認しておくと安全です。

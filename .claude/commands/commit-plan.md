---
name: commit-plan
description: ステージ済み差分を保存してcommitterでコミット計画を自動作成
command: >-
  bash -lc 'mkdir -p .claude && git diff --staged --unified=0 --no-color | tee .claude/.last_staged.diff >/dev/null && echo "[DIFF_SAVED] ステージ済み差分を保存しました。committerを起動します..."'
agent: committer
agentPrompt: >-
  `.claude/.last_staged.diff` を読み込んで、CLAUDE.mdのコミット分割ポリシーに従い以下を実行してください:

  1. 差分を分析して全体サマリ（変更概要・想定リスク）を作成
  2. コミット分割プラン（タイトル、本文、対象ファイル、想定gitコマンド）を提案
  3. 実行スクリプト `.claude/.commit_plan.sh` を作成（各ステップ確認プロンプト付き、--no-verify使用）

  重要:
  - Co-Authored-By トレーラーは含めない（CLAUDE.mdのポリシーに従う）
  - コミットメッセージは日本語で作成
  - 分割が不要な場合は1コミットとして提案
---
# commit-plan

ステージ済み差分を保存してcommitterサブエージェントを起動し、コミット計画を自動作成します。

## 使い方

```bash
# 1. 変更をステージング
git add <files>

# 2. コミット計画を作成（diff保存 + committer起動）
/commit-plan

# 3. プラン確認後、実行
/commit-apply
```

## 実行内容

1. `git diff --staged`を`.claude/.last_staged.diff`に保存
2. committerサブエージェントを自動起動
3. CLAUDE.mdのポリシーに従ってコミット分割プランを作成
4. `.claude/.commit_plan.sh`スクリプトを生成

## 出力

- 全体サマリ（変更概要・想定リスク）
- コミット分割プラン（各コミットの詳細）
- `.claude/.commit_plan.sh`スクリプト（実行可能）

プラン確認後、`/commit-apply`で実際にコミットを作成します。

## 注意

ステージが空の場合は diff が生成されないため、事前に `git add` でファイルをステージしてください。

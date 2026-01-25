---
name: x-browser
description: X/Twitter（twitter.com, x.com）のURLを自動検出してブラウザで開く。ツイートの内容確認、スクリーンショット取得、データ抽出に使用。ユーザーがX/TwitterのURLを共有した場合に自動的に使用。
allowed-tools: Bash(agent-browser:*)
---

# X/Twitter Browser Automation

X/Twitter URLを自動的に検出し、agent-browserで操作・分析します。

## 対象URL

- `twitter.com/*`
- `x.com/*`
- `mobile.twitter.com/*`

## 自動使用の条件

以下の場合、ユーザーが明示的に指示しなくてもこのスキルを使用：

- X/TwitterのURLが会話に含まれている
- 「このツイートを見て」「ツイートの内容を確認して」などの指示

## 使用するコマンド（agent-browser）

```bash
# URLを開く
agent-browser open <url>

# ページのスナップショット取得（インタラクティブ要素付き）
agent-browser snapshot -i

# スクリーンショット取得
agent-browser screenshot

# テキスト取得
agent-browser get text @e1

# ブラウザを閉じる
agent-browser close
```

## 典型的なワークフロー

1. `agent-browser open <twitter-url>` でページを開く
2. `agent-browser snapshot -i` でページ構造を取得
3. 必要に応じてスクロール、クリック、スクリーンショット
4. 情報をユーザーに報告
5. `agent-browser close` でブラウザを閉じる

## 注意事項

- X/TwitterはWebFetchでは取得できない（認証・JavaScript必須）
- ログインが必要なコンテンツは取得できない場合がある

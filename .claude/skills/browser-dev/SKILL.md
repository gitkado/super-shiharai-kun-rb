---
name: browser-dev
description: "MUST use for browser-based UI verification during frontend development. フロントエンド開発時にagent-browserでUI表示確認・コンソールデバッグ・要素操作テストを行う。Trigger words include: ブラウザ確認, UI確認, 画面確認, スクリーンショット, browser-dev."
argument-hint: "[url]"
---

あなたはフロントエンド開発時のブラウザ検証担当です。`agent-browser` CLIを使って、UI確認・デバッグ・操作テストを行います。

## 重要な制約

- ファイル編集: 許可（フロントエンドコードの修正）
- git操作: 禁止

## 前提条件

- `agent-browser` CLIがインストール済みであること

## プロジェクト設定

このスキルを使うプロジェクトに合わせて以下を確認する:

- **dev server URL**: プロジェクトのdev serverが起動するURL（例: `http://localhost:3000`, `http://localhost:5173`）
- **スクリーンショット保存先**: セッションのscratchpadディレクトリを使用する

dev server URLが不明な場合は、プロジェクトの設定ファイル（`vite.config.*`, `next.config.*`, `nuxt.config.*`, `package.json`の`scripts`等）から特定する。

## いつ使うか

以下の場面で **AIが自動的に** このスキルを使用する:

- フロントエンドのコード変更後、表示が正しいか確認する時
- 画面が真っ白・表示崩れなどUIの問題を調査する時
- ユーザーから「画面を確認して」と依頼された時
- フォームやボタンの動作確認が必要な時
- 認証フローなど一連の画面遷移を通しで検証する時
- バックエンドのエラーがフロント側で適切に表示されるか確認する時
- 画面上の文言が仕様通りか確認する時

## 認証フローの自動処理

ログイン画面に遭遇した場合、以下の手順で自動的に認証を行う:

1. 環境変数 `BROWSER_DEV_AUTH_EMAIL` と `BROWSER_DEV_AUTH_PASSWORD` を確認する
2. 環境変数が設定されている場合、その値を使ってログインフォームに入力・送信する
3. 環境変数が未設定の場合、`AskUserQuestion` ツールでユーザーにメールアドレスとパスワードを問い合わせる
4. 取得した認証情報でログインフォームに入力・送信する
5. ログイン成功を確認してから元の操作を続行する

## 基本ワークフロー

### 0. dev serverの起動確認

ブラウザ確認の前に、dev serverが起動済みか確認する:

```bash
curl -fsS http://localhost:5173/ > /dev/null 2>&1 && echo "running" || echo "stopped"
```

- **起動済み（running）** → そのまま利用。**新たに `pnpm dev` を実行しない**
- **未起動（stopped）** → ユーザーに起動を依頼する（`cd frontend && pnpm dev`）
  - ユーザーが明示的に許可した場合のみ、自動起動してよい

### 1. ページを開く

```bash
agent-browser open <url>
agent-browser wait --load networkidle
```

### 2. エラー確認

```bash
agent-browser errors    # コンソールエラーを確認
agent-browser console   # コンソールメッセージ全体を確認
```

### 3. スクリーンショット取得

スクリーンショットはscratchpadディレクトリに保存し、Readツールで表示する。

```bash
agent-browser screenshot <scratchpad>/screenshot.png
```

### 4. 要素操作（必要に応じて）

```bash
agent-browser snapshot -i           # インタラクティブ要素を取得
agent-browser fill @e1 "入力値"      # フォーム入力
agent-browser click @e2             # ボタンクリック
agent-browser wait --load networkidle
agent-browser screenshot <scratchpad>/after-action.png  # 操作後を確認
```

### 5. 終了

```bash
agent-browser close
rm <scratchpad>/*.png    # スクリーンショットを削除
```

## 用途別パターン

### UI表示確認

コード変更後の表示を確認する:

1. ページを開く
2. `errors` でコンソールエラーがないか確認
3. スクリーンショットを取得して表示確認
4. 問題があればユーザーに報告

### デバッグ

画面が白い・表示がおかしい等の問題調査:

1. ページを開く
2. `errors` でエラー内容を確認 → 原因特定の手がかりにする
3. `console` で追加情報を確認
4. スクリーンショットで現状を記録
5. エラー内容をもとにコードを修正 → 再確認

### 操作テスト

フォーム送信・画面遷移などの動作確認:

1. ページを開く
2. `snapshot -i` で操作可能な要素を取得
3. フォーム入力・ボタンクリック等を実行
4. `wait --load networkidle` で遷移を待機
5. 遷移後のスクリーンショットで結果確認
6. 必要に応じて `errors` でエラーチェック

### 修正前後の比較

コード変更の影響を視覚的に確認する:

1. 変更前にスクリーンショットを `before.png` として取得
2. コードを変更
3. ページをリロードし `after.png` を取得
4. 両方のスクリーンショットを表示して差分を報告

### 認証フローの通し確認

登録→ログイン→認証後ページなど一連の操作を検証:

1. 登録ページを開いてフォーム入力・送信
2. ログインページに遷移してフォーム入力・送信
3. 認証後のページが表示されることを確認
4. 各ステップでスクリーンショットと `errors` を確認

### APIエラーのフロント側影響確認

バックエンド停止中やエラーレスポンス時のフロント表示を確認:

1. ページを開く
2. エラーを誘発する操作を実行（存在しないリソースへのアクセス等）
3. `errors` でコンソールエラーを確認
4. スクリーンショットでエラー表示が適切か確認

### アクセシビリティチェック

`snapshot`のaccessibility treeを活用した基本チェック:

1. ページを開く
2. `snapshot`（フルツリー）を取得
3. img要素のalt属性、フォームのlabel、aria属性の漏れを確認
4. 問題があればユーザーに報告

### レスポンシブ確認

異なるビューポートサイズでの表示を確認:

1. ページを開く
2. スクリーンショットを取得（デスクトップ）
3. `agent-browser eval "window.innerWidth"` 等でビューポートを確認
4. 必要に応じてビューポートサイズを変えて再確認

### 表示テキスト確認

画面上の文言が仕様通りか確認する:

1. ページを開く
2. `snapshot` または `get text @ref` で表示テキストを取得
3. 仕様と照合して差異があれば報告

## 注意事項

- 確認が終わったら必ず `agent-browser close` でブラウザを閉じる
- **スクリーンショットは確認完了後に削除する**（`rm <scratchpad>/*.png`）
- dev serverの多重起動禁止: `curl` で起動確認済みの場合、`pnpm dev` を実行しない
- dev server未起動時は原則ユーザーに起動を依頼する（明示的許可があれば自動起動可）

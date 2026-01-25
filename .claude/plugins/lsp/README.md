# local-lsp Marketplace

Claude Code用のローカルLSPプラグインマーケットプレイス。

## セットアップ

Claude Codeで以下のコマンドを実行してマーケットプレイスを追加:

```bash
/plugin marketplace add ./.claude/plugins/lsp
```

追加後、プラグインを有効化:

```bash
/plugin enable ruby-lsp@local-lsp
```

### なぜコマンド実行が必要か

プロジェクト配下にマーケットプレイスを配置しても、Claude Codeが認識するにはユーザースコープ（`~/.claude/plugins/known_marketplaces.json`）への登録が必要です。

これはセキュリティ上の設計で、信頼できないマーケットプレイスの自動読み込みを防ぐためです。各開発者が明示的にコマンドを実行することで、そのマーケットプレイスを信頼することを確認します。

**補足**: `settings.json`の`extraKnownMarketplaces`でも登録可能ですが、絶対パスが必須のため環境依存になります。コマンド経由での追加は相対パスを受け付け、内部で絶対パスに変換して保存されます。

## 確認方法

マーケットプレイス一覧:

```bash
/plugin marketplace list
```

有効なプラグイン一覧:

```bash
/plugin list
```

## 含まれるプラグイン

| プラグイン | 説明 |
|-----------|------|
| ruby-lsp | Ruby言語サーバー |

各プラグインの詳細は個別のREADMEを参照してください。

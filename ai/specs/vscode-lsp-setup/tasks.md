# VS Code + Ruby LSP導入 - 実装タスク

> **ステータス:** フェーズ1 80%完了（Gemfile・settings.json完了、拡張インストール待ち）

## 実装TODO

### フェーズ1: 最小構成（5分で動く）

#### タスク1-1: Ruby LSP拡張のインストール（手動操作）

- [ ] VS Code拡張機能マーケットプレイスで「Ruby LSP」を検索
- [ ] 以下の拡張をインストール:
  - **Ruby LSP** (Shopify.ruby-lsp) - 必須
  - **Ruby LSP Rails** (Shopify.ruby-lsp-rails) - 推奨
  - **Ruby LSP RSpec** (Shopify.ruby-lsp-rspec) - 推奨
  - **Ruby LSP RuboCop** (Shopify.ruby-lsp-rubocop) - 任意

**検証コマンド:**

```bash
# VS Codeの拡張一覧で確認
code --list-extensions | grep ruby-lsp
```

**期待結果:**

```text
Shopify.ruby-lsp
Shopify.ruby-lsp-rails
Shopify.ruby-lsp-rspec
Shopify.ruby-lsp-rubocop
```

---

#### タスク1-2: Gemfileへのruby-lsp追加 ✅

- [x] `Gemfile` の `group :development` に以下を追加:

```ruby
group :development do
  gem "ruby-lsp", require: false
  gem "ruby-lsp-rails", require: false
  gem "ruby-lsp-rspec", require: false
  gem "ruby-lsp-rubocop", require: false  # 任意
end
```

- [x] `bundle install` を実行

**検証コマンド:**

```bash
bundle list | grep ruby-lsp
```

**実行結果:**

```text
  * ruby-lsp (0.26.1)
  * ruby-lsp-rails (0.4.8)
  * ruby-lsp-rspec (0.1.28)
```

---

#### タスク1-3: `.vscode/settings.json` の作成 ✅

- [x] プロジェクトルートに `.vscode/settings.json` を作成（存在しない場合）
- [x] 以下の設定を記述:

```json
{
  "rubyLsp.rubyVersionManager": "bundler",
  "rubyLsp.rubyCommand": "bundle",
  "files.watcherExclude": {
    "**/tmp/**": true,
    "**/log/**": true,
    "**/node_modules/**": true,
    "**/vendor/bundle/**": true,
    "**/coverage/**": true,
    "**/storage/**": true
  },
  "search.exclude": {
    "**/tmp": true,
    "**/log": true,
    "**/coverage": true,
    "**/vendor/bundle": true,
    "**/storage": true
  },
  "editor.inlayHints.enabled": "on"
}
```

**設定のポイント:**

- `rubyVersionManager: "bundler"` - asdf管理のRubyを安定的に使用
- `files.watcherExclude` - 不要なファイル監視を除外（パフォーマンス向上）
- `editor.inlayHints.enabled` - 引数名や型情報をインラインで表示

**検証コマンド:**

```bash
cat .vscode/settings.json | jq '.rubyLsp.rubyVersionManager'
# 出力: "bundler"
```

---

#### タスク1-4: 動作確認

- [ ] VS Codeを再起動（完全に終了してから再度開く）
- [ ] 右下のステータスバーに「Ruby LSP」アイコンが表示され、"Running" になることを確認
- [ ] 以下のファイルを開いて動作確認:
  - `app/packages/authentication/app/models/account.rb`
  - `app/packages/hello/app/controllers/hello_controller.rb`
- [ ] 動作確認項目:
  - [ ] クラス名やメソッド名にカーソルを合わせると情報が表示される（ホバー）
  - [ ] `F12`（定義へジャンプ）が動作する
  - [ ] `Ctrl+Space`（補完）でメソッド候補が表示される
  - [ ] `Shift+F12`（参照検索）が動作する

**検証コマンド（LSPログ確認）:**

VS Codeの「出力」パネル → ドロップダウンから「Ruby LSP」を選択してログを確認

**期待結果:**

```text
[Info] Indexing ...
[Info] Indexed 1234 entries
```

---

### フェーズ2: 実務強化（任意）

#### タスク2-1: Zeitwerkチェックの定期実行 ✅

- [x] 現在のZeitwerkエラーを確認・修正:

```bash
bin/rails zeitwerk:check
```

- [ ] エラーが出た場合の対処:
  - ファイル名とクラス名の不一致を修正
  - 詳細は `doc/vscode_lsp_setup.md` の「1-2. Zeitwerkの健全性チェック」参照

**検証コマンド:**

```bash
bin/rails zeitwerk:check
```

**期待結果:**

```text
All is good!
```

---

#### タスク2-2: vendor/bundle使用の検討（任意）

**注意:** デフォルトではシステムgemを使用。LSPが重い場合のみ検討。

- [ ] チーム方針を確認（ディスク使用量増加のトレードオフ）
- [ ] 導入する場合は以下を実行:

```bash
# .gitignoreに追加（まだない場合）
echo "/vendor/bundle" >> .gitignore

# Gemをローカル配置
bundle config set --local path "vendor/bundle"
bundle install
```

- [ ] VS Codeを再起動してLSPの動作を確認

**検証コマンド:**

```bash
bundle config get path
# 出力: "vendor/bundle"
```

**ロールバック方法:**

```bash
bundle config unset path
rm -rf vendor/bundle
bundle install
```

---

#### タスク2-3: ワークスペース分割の検討（大規模リポジトリ向け）

**注意:** 現時点ではパッケージ数が少ないため不要。将来的に検討。

- [ ] `.vscode/<project-name>.code-workspace` を作成（必要に応じて）

```json
{
  "folders": [
    { "path": ".." },
    { "path": "../app/packages/authentication" },
    { "path": "../app/packages/hello" }
  ],
  "settings": {
    "rubyLsp.rubyVersionManager": "bundler",
    "rubyLsp.rubyCommand": "bundle"
  }
}
```

- [ ] ワークスペースファイルを開く:

```bash
code .vscode/super-shiharai-kun.code-workspace
```

**検証:** 各パッケージごとに独立したLSPインスタンスが起動することを確認

---

### フェーズ3: 型連携（RBS/Steep）

**注意:** Sorbet不使用方針に準拠。RBS/Steepのみ導入可能。

#### タスク3-1: RBS/Steepのインストール

- [ ] `Gemfile` の `group :development` に追加:

```ruby
group :development do
  gem "rbs", require: false
  gem "steep", require: false
  gem "rbs_rails", require: false
end
```

- [ ] `bundle install` を実行

**検証コマンド:**

```bash
bundle list | grep -E "(rbs|steep)"
```

**期待結果:**

```text
  * rbs (x.x.x)
  * rbs_rails (x.x.x)
  * steep (x.x.x)
```

---

#### タスク3-2: RBSコレクションの初期化

- [ ] 依存GemのRBS型定義を解決:

```bash
bundle exec rbs collection init
bundle exec rbs collection install
```

- [ ] `rbs_collection.lock.yaml` がコミット対象か確認（推奨: コミットする）

**検証コマンド:**

```bash
cat rbs_collection.lock.yaml | head -10
```

**期待結果:**

```yaml
sources:
  - name: ruby/gem_rbs_collection
    remote: https://github.com/ruby/gem_rbs_collection.git
    ...
```

---

#### タスク3-3: Rails型定義の自動生成

- [ ] Rails由来の型定義を生成:

```bash
bundle exec rbs_rails rbs
```

- [ ] `sig/rbs_rails/` 配下に型定義ファイルが生成されることを確認
- [ ] Git管理するか決定（推奨: コミットする）

**検証コマンド:**

```bash
ls -la sig/rbs_rails/
# 出力例:
# app/models/account.rbs
# config/routes.rbs
```

**`.gitignore` への追加（Git管理しない場合のみ）:**

```gitignore
# RBS generated files
/sig/rbs_rails/
```

---

#### タスク3-4: Steepの初期化と型チェック

- [ ] Steep設定ファイル生成:

```bash
bundle exec steep init
```

- [ ] `Steepfile` を編集して対象パスを調整:

```ruby
target :app do
  check "app/packages"  # Packwerk環境に合わせる

  # 自動生成された型定義を読み込み
  signature "sig"

  # Rails標準ライブラリの型定義
  library "pathname", "uri", "logger"
end
```

- [ ] 型チェック実行:

```bash
bundle exec steep check
```

**検証コマンド:**

```bash
bundle exec steep check --severity-level=error
```

**期待結果（初回）:**

多数の型エラーが出る可能性あり。段階的に修正する方針を取る。

---

#### タスク3-5: Lefthookへの型チェック統合

- [ ] `.lefthook.yml` に以下を追加:

```yaml
pre-commit:
  parallel: true
  commands:
    # 既存: rubocop, packwerk-validate, packwerk-check, rspec

    # 型定義の再生成（Rails変更時のみ実行）
    rbs-rails:
      tags: types
      glob: "{db/migrate,db/schema.rb,config/routes.rb,app/packages/**/models/**/*.rb}"
      run: bundle exec rbs_rails rbs
      skip:
        - merge
        - rebase

pre-push:
  commands:
    # 既存: brakeman, bundler-audit, rspec

    # Zeitwerkチェック（Rails起動コストが高いためpre-pushで実行）
    zeitwerk:
      tags: autoload
      run: bin/rails zeitwerk:check

    # 型チェック（全体チェックに時間がかかるためpre-pushで実行）
    steep:
      tags: types
      run: bundle exec steep check --severity-level=error
```

- [ ] 動作確認:

```bash
# pre-commit試験
git add .
LEFTHOOK_EXCLUDE="" lefthook run pre-commit

# pre-push試験
lefthook run pre-push
```

**検証コマンド:**

```bash
# フックがスキップされないことを確認
lefthook run pre-commit -v
```

**期待結果:**

```text
EXECUTE > rbs-rails
EXECUTE > rubocop
EXECUTE > packwerk-validate
...
```

---

### フェーズ4: ドキュメント整備

#### タスク4-1: doc/vscode_lsp_setup.md の削除判断

**判断基準:**

- ✅ `specs/vscode-lsp-setup/` に全情報が集約されている
- ✅ 開発者向けリファレンスとしての役割を `specs/` が担える
- ❌ トラブルシューティングなど、詳細な手順が必要な場合は残す

**推奨方針:**

`doc/vscode_lsp_setup.md` を削除し、`README.md` または `CLAUDE.md` から `specs/vscode-lsp-setup/` へのリンクを追加する。

- [ ] `doc/vscode_lsp_setup.md` を削除:

```bash
git rm doc/vscode_lsp_setup.md
```

- [ ] `README.md` に以下を追加（開発環境セクション）:

```markdown
## 開発環境セットアップ

### VS Code + Ruby LSP

詳細は [specs/vscode-lsp-setup/](specs/vscode-lsp-setup/) を参照してください。

#### クイックスタート

1. VS Code拡張「Ruby LSP」をインストール
2. `bundle install`
3. VS Codeを再起動

詳細な設定・トラブルシューティングは上記リンク先を参照。
```

- [ ] コミット:

```bash
git add README.md
git commit -m "docs(readme): VS Code LSP導入ガイドへのリンクを追加"
```

**検証:** README.mdのリンクが正しく動作することを確認

---

#### タスク4-2: CLAUDE.md への参照追加

- [ ] `CLAUDE.md` の「参考ドキュメント」セクションに追加:

```markdown
## 参考ドキュメント

詳細は以下を参照:

- `specs/vscode-lsp-setup/` - VS Code + Ruby LSP導入ガイド
- `doc/modular_monolith.md` - モジュラーモノリスアーキテクチャの詳細
- ...
```

**検証:** ドキュメントのリンクが正しく動作することを確認

---

## テスト観点

### 1. LSP基本動作テスト

**テストケース:**

| テスト項目 | 手順 | 期待結果 |
|-----------|------|---------|
| 補完動作 | `Invoice.` と入力して Ctrl+Space | ActiveRecordのメソッド候補が表示される |
| 定義ジャンプ | クラス名にカーソルを合わせてF12 | 該当クラスの定義ファイルへジャンプ |
| 参照検索 | メソッド名にカーソルを合わせてShift+F12 | 全参照箇所が一覧表示される |
| ホバー情報 | メソッド名にカーソルを合わせる | ドキュメントや型情報が表示される |
| インレイヒント | メソッド呼び出し時 | 引数名がインラインで表示される |

### 2. Packwerk境界テスト

**テストケース:**

```ruby
# app/packages/billing/app/services/test_service.rb
class TestService
  def call
    # ❌ 意図的なPackwerk違反を作る
    Invoice.all
  end
end
```

**検証:**

- [ ] LSPで `Invoice` が補完される（F12でジャンプ可能）
- [ ] `bundle exec packwerk check` でDependency violationエラーが出る
- [ ] Lefthook pre-commitでコミットが拒否される

### 3. Zeitwerk準拠テスト

**テストケース:**

```bash
# 意図的に命名規則違反を作る
# app/packages/payment/app/models/invoice.rb に以下を記述:
class PaymentInvoice < ApplicationRecord
end
```

**検証:**

- [ ] `bin/rails zeitwerk:check` でエラーが出る
- [ ] LSPの定義ジャンプが失敗する（Zeitwerk違反のため）

**期待エラー:**

```text
expected file app/packages/payment/app/models/payment_invoice.rb to define constant Invoice
```

### 4. 型チェックテスト（RBS導入後）

**テストケース:**

```ruby
# app/packages/payment/app/models/invoice.rb
class Invoice < ApplicationRecord
  has_many :line_items
end

# ===== テスト対象 =====
inv = Invoice.first
inv.line_items.where(amount: "invalid")  # ← 型エラー（amountはinteger）
```

**検証:**

- [ ] `bundle exec steep check` で型エラーが検出される
- [ ] Lefthook pre-pushでエラーが報告される

---

## 検証コマンド一覧

### 基本動作確認

```bash
# Ruby環境確認
asdf current ruby

# LSP gemインストール確認
bundle list | grep ruby-lsp

# VS Code拡張確認
code --list-extensions | grep ruby-lsp

# Zeitwerk準拠確認
bin/rails zeitwerk:check

# Packwerk違反確認
bundle exec packwerk check
```

### RBS/Steep導入後

```bash
# RBSコレクション状態確認
bundle exec rbs collection install --frozen

# Rails型定義生成
bundle exec rbs_rails rbs

# 型チェック実行
bundle exec steep check

# 型チェック（エラーのみ）
bundle exec steep check --severity-level=error
```

### Lefthook動作確認

```bash
# pre-commit試験
lefthook run pre-commit

# pre-push試験
lefthook run pre-push

# 特定のタグのみ実行
LEFTHOOK_INCLUDE=types lefthook run pre-commit

# 全フックをスキップ（緊急時のみ）
LEFTHOOK=0 git commit -m "message"
```

---

## 想定リードタイム

### フェーズ1: 最小構成

- **所要時間**: 10分
- **前提条件**: Ruby 3.4.6がインストール済み、VS Codeが利用可能
- **完了基準**: LSPが起動し、基本的な補完・ジャンプが動作

### フェーズ2: 実務強化

- **所要時間**: 30分〜1時間
- **前提条件**: フェーズ1完了
- **完了基準**: Zeitwerkチェックが通り、パフォーマンスが許容範囲

### フェーズ3: 型連携

- **所要時間**: 2〜4時間（初回型エラー修正含む）
- **前提条件**: フェーズ2完了、チームでの方針合意
- **完了基準**: CIで型チェックが実行され、重大な型エラーが解消

### フェーズ4: ドキュメント整備

- **所要時間**: 30分
- **前提条件**: 全フェーズ完了
- **完了基準**: `doc/vscode_lsp_setup.md` 削除、`specs/` への参照が整備

---

## 進捗ログ

### 2025-10-21: 初期構成

- [x] `specs/vscode-lsp-setup/` ディレクトリ作成
- [x] `requirements.md` 作成
- [x] `design.md` 作成
- [x] `tasks.md` 作成（このファイル）
- [x] フェーズ1実装完了

### 2025-10-21: フェーズ1実装完了

#### 実施内容

**タスク1-2: Gemfileへのruby-lsp追加**

- [x] `Gemfile` の `group :development, :test` に以下を追加:
  - `ruby-lsp` (0.26.1)
  - `ruby-lsp-rails` (0.4.8)
  - `ruby-lsp-rspec` (0.1.28)
  - ~~`ruby-lsp-rubocop`~~ (gemが存在しないため除外。Ruby LSP本体がRuboCop統合機能を持つため不要)
- [x] `bundle install` 実行完了

**タスク1-3: `.vscode/settings.json` の作成**

- [x] `.vscode/` ディレクトリ作成
- [x] 以下の設定を記述:
  - `rubyLsp.rubyVersionManager: "bundler"` - asdf環境での安定動作
  - `rubyLsp.rubyCommand: "bundle"` - bundler経由でLSP起動
  - `files.watcherExclude` - 不要なファイル監視を除外（tmp, log, coverage等）
  - `search.exclude` - 検索対象から除外（tmp, log, coverage等）
  - `editor.inlayHints.enabled: "on"` - 引数名・型情報をインライン表示

**タスク2-1: Zeitwerkチェックの実行**

- [x] `bin/rails zeitwerk:check` 実行
- [x] 結果: **All is good!** - Zeitwerk準拠を確認
- ⚠️ DEPRECATION警告あり（影響なし、後で対応）:
  - `Account` モデルのenum定義（Railsのキーワード引数形式が非推奨）
  - rswag-api, rswag-uiのメソッド名変更予定

**タスク4-1: README.md への参照**

- [x] README.md には既にVS Code LSPセクションが存在（35-47行目）
- [x] `specs/vscode-lsp-setup/` へのリンクが記載済み

#### 検証結果

```bash
# Ruby LSP gem確認
$ bundle list | grep ruby-lsp
  * ruby-lsp (0.26.1)
  * ruby-lsp-rails (0.4.8)
  * ruby-lsp-rspec (0.1.28)

# Zeitwerk健全性確認
$ bin/rails zeitwerk:check
All is good!

# .vscode/settings.json 確認
$ cat .vscode/settings.json | jq '.rubyLsp.rubyVersionManager'
"bundler"
```

#### 次のステップ（開発者向け）

1. **VS Code拡張のインストール**（手動操作）
   - VS Code拡張機能マーケットプレイスで「Ruby LSP」を検索
   - 以下の拡張をインストール:
     - **Ruby LSP** (Shopify.ruby-lsp) - 必須
     - **Ruby LSP Rails** (Shopify.ruby-lsp-rails) - 推奨
     - **Ruby LSP RSpec** (Shopify.ruby-lsp-rspec) - 推奨

2. **VS Codeの再起動**
   - VS Codeを完全に終了してから再度開く
   - 右下のステータスバーに「Ruby LSP」アイコンが表示され、"Running" になることを確認

3. **動作確認**
   - 任意のRubyファイルを開いて以下を確認:
     - [ ] クラス名やメソッド名にカーソルを合わせると情報が表示される（ホバー）
     - [ ] `F12`（定義へジャンプ）が動作する
     - [ ] `Ctrl+Space`（補完）でメソッド候補が表示される
     - [ ] `Shift+F12`（参照検索）が動作する

#### 残課題

- [ ] 開発者全員によるVS Code拡張インストールと動作確認
- [ ] Accountモデルのenum定義をRails 8.0準拠形式に変更（DEPRECATION対応）
- [ ] rswag-api, rswag-uiのメソッド名変更（v3.0準拠形式）

---

## 残課題・検討事項

### 短期（1週間以内）

- [ ] フェーズ1の動作確認（全開発者）
- [ ] トラブルシューティング事例の収集
- [ ] Zeitwerkチェックの定期実行ルール策定

### 中期（1ヶ月以内）

- [ ] RBS/Steep導入の是非を判断（チーム合意）
- [ ] vendor/bundle使用の是非を判断（パフォーマンス測定）
- [ ] Lefthookへの型チェック統合（RBS導入時）

### 長期（3ヶ月以内）

- [ ] 型カバレッジ目標の設定（RBS導入後）
- [ ] 段階的な型エラー解消計画
- [ ] ワークスペース分割の検討（パッケージ数増加時）

---

## 実装者への引き継ぎ事項

### 重要な注意点

1. **Sorbet不使用**: プロジェクト方針により、RBS/Steepのみ導入可能
2. **bundler経由でLSP起動**: asdf環境での安定性のため必須
3. **Packwerk境界の理解**: LSPとPackwerkは独立したレイヤー
4. **Zeitwerk準拠の徹底**: 定義ジャンプの精度に直結

### 推奨する進め方

1. **フェーズ1を全開発者で実施** - 基本的な開発体験向上を優先
2. **2週間運用して課題収集** - トラブルシューティング事例を蓄積
3. **RBS/Steep導入を検討** - 型チェックの投資対効果を評価
4. **段階的に型カバレッジを向上** - 重要なパッケージから優先的に型定義

### 質問・相談先

- Zeitwerk関連: `doc/modular_monolith.md` 参照
- Packwerk関連: `doc/packwerk_guide.md` 参照
- LSP全般: `specs/vscode-lsp-setup/design.md` 参照
- 技術判断: テックリードへ相談

---

## 参考リンク

- [Ruby LSP公式ドキュメント](https://shopify.github.io/ruby-lsp/)
- [RBS公式ドキュメント](https://github.com/ruby/rbs)
- [Steep公式ドキュメント](https://github.com/soutaro/steep)
- [rbs_rails](https://github.com/pocke/rbs_rails)
- プロジェクト固有:
  - [doc/modular_monolith.md](../../doc/modular_monolith.md)
  - [doc/packwerk_guide.md](../../doc/packwerk_guide.md)
  - [CLAUDE.md](../../CLAUDE.md)

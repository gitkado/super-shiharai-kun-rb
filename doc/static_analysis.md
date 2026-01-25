# 静的解析と品質チェック

このプロジェクトでは、コード品質とセキュリティを保つために [Lefthook](https://github.com/evilmartians/lefthook) を使用した自動チェックを導入しています。

## 概要

Lefthookは、Gitフックを簡単に管理できるツールです。コミットやプッシュ時に自動的に静的解析を実行し、品質の低いコードやセキュリティリスクのあるコードがリポジトリに混入するのを防ぎます。

## 導入しているツール

### RuboCop

Rubyコードスタイルと品質チェックツールです。

- **ベース設定**: [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase)
- **プラグイン**:
  - `rubocop-rails`: Rails固有のベストプラクティス
  - `rubocop-performance`: パフォーマンス最適化
  - `rubocop-rspec`: RSpecのベストプラクティス
  - `rubocop-packs`: Packwerk/Packsとの統合

**特徴:**

- `frozen_string_literal: true`マジックコメントを強制（パフォーマンス向上とバグ予防）
- Sorbet copは無効化（型アノテーションは使用しないため）

### Packwerk

パッケージ間の依存関係を管理するツールです。

- **依存関係チェック**: 未宣言の依存を検出
- **プライバシーチェック**: 公開API以外への参照を検出
- **循環依存の検出**: パッケージ間の循環参照を防止

詳細は [Packwerk使用ガイド](packwerk_guide.md) を参照してください。

### Brakeman

Railsアプリケーションのセキュリティ脆弱性スキャナーです。

- SQLインジェクション
- XSS（クロスサイトスクリプティング）
- CSRF（クロスサイトリクエストフォージェリ）
- 安全でないリダイレクト
- マスアサインメントの脆弱性

### Bundler Audit

依存gemの既知の脆弱性をチェックします。

- RubyGems Advisory Database（<https://rubysec.com/）から脆弱性情報を取得>
- インストールされているgemに既知の脆弱性がないかチェック
- **ローカル開発**: キャッシュされたDBを使用（高速・安定）
- **CI/CD**: `--update`オプションで最新DBを取得（網羅性重視）

### markdownlint

Markdownファイルのスタイルと構文をチェックします。

- **ツール**: markdownlint-cli2
- **設定ファイル**: `.markdownlint.json`, `.markdownlint-cli2.jsonc`
- **除外対象**: `plans/`（自動生成ファイル）

**主な設定方針:**

- MD013（行長制限）: 無効化（日本語対応）
- MD024: siblings_only（セクション内での重複見出しは許可）
- MD033: 一部HTML要素を許可（`<br>`, `<details>`, `<summary>`等）
- MD040: コードブロックの言語指定を要求
- MD041（最初の行がh1）: 無効化
- MD060（テーブルスペーシング）: 無効化

## フックタイミングと実行内容

### pre-commit（コミット前）

コミット時に以下のチェックが**並列実行**されます:

```yaml
rubocop:            # 変更されたRubyファイルのスタイルチェック
packwerk-validate:  # Packwerk設定の検証
packwerk-check:     # パッケージ間の依存関係チェック
markdownlint:       # Markdownファイルのスタイルチェック
```

これらはコミット前に実行され、違反があればコミットが中断されます。

### pre-push（プッシュ前）

プッシュ時に以下のチェックが実行されます:

```yaml
brakeman:       # セキュリティ脆弱性スキャン
bundler-audit:  # 依存関係の脆弱性チェック（キャッシュDBを使用）
rspec:          # 全テスト実行
```

**注意**: bundler-auditはローカルキャッシュのDBを使用します。CI/CDでは`--update`オプションで最新DBを取得することを推奨します。

## 手動実行コマンド

Gitフックを待たずに手動で実行することも可能です。

### RuboCop

```bash
# 自動修正あり（推奨）
bundle exec rubocop -a

# 自動修正なし（チェックのみ）
bundle exec rubocop

# 特定のファイルのみチェック
bundle exec rubocop app/packages/hello/app/controllers/hello_controller.rb

# 全自動修正（危険な修正も含む）
bundle exec rubocop -A
```

### Packwerk

```bash
# 設定の検証
bundle exec packwerk validate

# 依存関係チェック
bundle exec packwerk check

# 特定のパッケージのみチェック
bundle exec packwerk check app/packages/hello/

# 既存の違反をTODOファイルに記録
bundle exec packwerk update-todo
```

### Brakeman

```bash
# 基本的なスキャン
bundle exec brakeman

# 詳細なレポート
bundle exec brakeman -A

# HTMLレポート生成
bundle exec brakeman -o brakeman_report.html
```

### Bundler Audit

```bash
# 脆弱性チェック（ローカル開発用、キャッシュDB使用）
bundle exec bundler-audit check

# DBを最新に更新してチェック（CI/CD推奨、または定期的に実行）
bundle exec bundler-audit check --update

# DBのみ更新（キャッシュ破損時のリカバリ用）
bundle exec bundler-audit update
```

### markdownlint

```bash
# 全Markdownファイルをチェック
npx markdownlint-cli2 "**/*.md"

# 自動修正（可能なもののみ）
npx markdownlint-cli2 "**/*.md" --fix

# 特定のディレクトリのみチェック
npx markdownlint-cli2 "doc/**/*.md"
```

## Lefthookの管理コマンド

### フックのインストール

```bash
bundle exec lefthook install
```

プロジェクトをクローンした後、最初に実行します。`.git/hooks/`にフックスクリプトがインストールされます。

### フックのアンインストール

```bash
bundle exec lefthook uninstall
```

Gitフックを一時的に無効化したい場合に使用します。

### 特定のフックを手動実行

```bash
# pre-commitフックを手動実行
bundle exec lefthook run pre-commit --verbose

# pre-pushフックを手動実行
bundle exec lefthook run pre-push --verbose
```

`--verbose`オプションで詳細なログを表示します。

## フックのスキップ

緊急時にフックをスキップする場合:

```bash
# コミット時のフックをスキップ
LEFTHOOK=0 git commit -m "message"

# プッシュ時のフックをスキップ
LEFTHOOK=0 git push
```

**注意**: セキュリティチェックをスキップする場合は、後で必ず手動実行してください。

## 設定ファイル

### .lefthook.yml

```yaml
pre-commit:
  parallel: true
  commands:
    rubocop:
      glob: "**/*.{rb,rake}"
      run: bundle exec rubocop --force-exclusion
    packwerk-validate:
      run: bundle exec packwerk validate
    packwerk-check:
      glob: "**/*.rb"
      run: bundle exec packwerk check
    rspec:
      run: RAILS_ENV=test bin/rails db:test:prepare && bundle exec rspec --fail-fast
    markdownlint:
      glob: "**/*.md"
      run: npx markdownlint-cli2 {staged_files}

pre-push:
  commands:
    brakeman:
      run: bundle exec brakeman -q --no-progress --no-pager
    bundler-audit:
      run: bundle exec bundler-audit check  # キャッシュDBを使用（安定性優先）
    rspec:
      run: RAILS_ENV=test bin/rails db:test:prepare && bundle exec rspec
```

**注意**: pre-pushのbundler-auditは`--update`なしでキャッシュDBを使用します。ネットワーク問題やキャッシュ破損によるエラーを防ぐためです。CI/CDでは`--update`を使用して最新DBでチェックすることを推奨します。

### .rubocop.yml

```yaml
inherit_gem:
  rubocop-rails-omakase: rubocop.yml

require:
  - rubocop-rspec
  - rubocop-packs

# Packwerkとの統合
Packs/RootNamespaceIsPackName:
  Enabled: true

# frozen_string_literalを強制
Style/FrozenStringLiteralComment:
  Enabled: true
  EnforcedStyle: always

# Sorbetは使用しないため無効化
Sorbet:
  Enabled: false
```

## CI/CDとの統合

GitHub ActionsなどのCI/CDパイプラインでも同じチェックを実行することを推奨します。

### GitHub Actionsの例

```yaml
name: CI

on: [push, pull_request]

jobs:
  rubocop:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec rubocop

  packwerk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec packwerk validate
      - run: bundle exec packwerk check

  brakeman:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec brakeman

  bundler-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec bundler-audit check --update
```

## ベストプラクティス

### 1. 早期のフィードバック

コミット前にチェックを実行することで、問題を早期に発見できます。レビュー後に指摘されるよりも効率的です。

### 2. 自動修正の活用

RuboCopの自動修正（`-a`）を積極的に活用します。手動で修正するよりも確実で高速です。

### 3. 段階的な改善

既存のコードベースに後から導入する場合は、`packwerk update-todo`や`.rubocop_todo.yml`を使用して段階的に改善します。

```bash
# RubocopのTODOファイル生成
bundle exec rubocop --auto-gen-config
```

### 4. チーム全体での共有

全てのメンバーが同じ設定でチェックを実行できるよう、設定ファイルをリポジトリに含めます。

### 5. 定期的な更新

ツールと脆弱性データベースを定期的に更新します。

```bash
bundle update rubocop rubocop-rails-omakase brakeman bundler-audit
```

## トラブルシューティング

### フックが実行されない

1. Lefthookがインストールされているか確認:

   ```bash
   bundle exec lefthook install
   ```

2. `.git/hooks/`にフックスクリプトが存在するか確認:

   ```bash
   ls -la .git/hooks/
   ```

### RuboCop違反が多すぎる

既存のコードベースでは、TODOファイルを生成して段階的に修正します:

```bash
bundle exec rubocop --auto-gen-config
```

これにより、`.rubocop_todo.yml`が生成され、既存の違反は許容されます。

### Packwerkが遅い

大規模なコードベースでは、特定のパッケージのみチェックすることで高速化できます:

```bash
bundle exec packwerk check app/packages/hello/
```

### Brakeman誤検知

誤検知の場合は、`brakeman.ignore`ファイルで無視できます:

```bash
bundle exec brakeman -I
```

### Bundler Auditでエラーが発生する

`--update`オプション使用時に以下のようなエラーが発生する場合:

```text
fatal: couldn't find remote ref master
failed to update "/Users/<username>/.local/share/ruby-advisory-db"
```

**原因**: ローカルのruby-advisory-dbキャッシュが破損または不整合な状態になっています。

**解決方法**: キャッシュを削除して再構築します:

```bash
rm -rf ~/.local/share/ruby-advisory-db
bundle exec bundler-audit update
```

**予防策**: ローカルのpre-pushフックでは`--update`なしで実行し、CI/CDで`--update`付きチェックを行う運用を推奨します。

## 関連ドキュメント

- [Packwerk使用ガイド](packwerk_guide.md) - Packwerkの詳細な使い方
- [モジュラーモノリスアーキテクチャ](modular_monolith.md) - パッケージ構造の理解

## 関連ファイル

- [.lefthook.yml](../.lefthook.yml)
- [.rubocop.yml](../.rubocop.yml)

## 参考リンク

- [Lefthook公式ドキュメント](https://github.com/evilmartians/lefthook)
- [RuboCop公式ドキュメント](https://docs.rubocop.org/)
- [Brakeman公式サイト](https://brakemanscanner.org/)
- [Bundler Audit](https://github.com/rubysec/bundler-audit)

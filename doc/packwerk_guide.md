# Packwerk使用ガイド

[Packwerk](https://github.com/Shopify/packwerk)は、Railsアプリケーションのモジュール化を支援するツールです。パッケージ間の依存関係を管理し、アーキテクチャの境界を強制します。

## 概要

Packwerkを使用することで、以下が可能になります:

- **依存関係チェック**: 宣言されていない依存を検出
- **循環依存の検出**: パッケージ間の循環参照を防止
- **Privacy enforcement**: 公開API (`app/public/`) 以外への参照を検出
- **設定の検証**: `package.yml`の妥当性チェック

## 主なコマンド

### 設定の検証

```bash
bundle exec packwerk validate
```

全てのパッケージの`package.yml`が正しく設定されているかチェックします。

### 依存関係チェック

```bash
# 全パッケージをチェック
bundle exec packwerk check

# 特定のパッケージのみチェック
bundle exec packwerk check app/packages/hello/
```

未宣言の依存関係や、プライバシー違反を検出します。

### 違反の自動記録

```bash
bundle exec packwerk update-todo
```

既存の違反を`package_todo.yml`に記録し、段階的な修正を可能にします。

## package.ymlの設定

各パッケージのルートディレクトリに`package.yml`を配置します。

### 基本構成

```yaml
# app/packages/your_domain/package.yml
enforce_dependencies: true    # 依存関係チェックを有効化
enforce_privacy: true         # プライバシーチェックを有効化

dependencies:
  - "."                      # ルートパッケージ（ApplicationControllerなど）
  - "app/packages/authentication"  # 他のパッケージへの依存

public_path: app/public      # 公開APIのパス（デフォルト）
```

### 設定項目

| 項目 | 説明 | デフォルト |
|-----|------|----------|
| `enforce_dependencies` | 依存関係チェックを有効化 | `false` |
| `enforce_privacy` | プライバシーチェックを有効化 | `false` |
| `dependencies` | 依存可能なパッケージのリスト | `[]` |
| `public_path` | 公開APIのパス | `app/public` |

## 依存関係の管理

### 依存の追加

他のパッケージに依存する場合は、`dependencies`に追加します。

```yaml
# app/packages/payments/package.yml
dependencies:
  - "."                              # ルートパッケージ
  - "app/packages/authentication"    # 認証パッケージ
```

これにより、`payments`パッケージから`authentication`パッケージの公開APIを利用できます。

### 依存の制限

依存関係は**一方向のみ**に保つことが重要です。循環依存は避けるべきです。

**良い例:**

```text
payments → authentication → root
hello → authentication → root
```

**悪い例（循環依存）:**

```text
payments → authentication → payments  # NG!
```

## 公開APIの管理

### 公開APIとは

デフォルトでは、パッケージ内の全てのクラス/モジュールは**非公開（private）**です。他のパッケージから利用されるものだけを`app/public/`に配置します。

### 公開APIの配置

```ruby
# app/packages/authentication/app/public/authenticatable.rb
module Authentication
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_user!
    end

    private

    def authenticate_user!
      # 認証ロジック
    end
  end
end
```

### 公開APIの利用

```ruby
# app/packages/payments/app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  include Authentication::Authenticatable  # 公開APIを利用

  def index
    # current_userなどが利用可能
  end
end
```

### プライバシー違反の例

```ruby
# app/packages/payments/app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  def index
    # NG: 非公開のモデルに直接アクセス
    user = Authentication::User.find(params[:user_id])

    # OK: 公開APIを経由してアクセス
    user = Authentication::UserFinder.find(params[:user_id])
  end
end
```

## Git連携（Lefthook）

Lefthookにより、コミット時に自動的にPackwerkチェックが実行されます。

```yaml
# .lefthook.yml（抜粋）
pre-commit:
  parallel: true
  commands:
    packwerk-validate:
      run: bundle exec packwerk validate
    packwerk-check:
      run: bundle exec packwerk check
```

### フックのスキップ

緊急時にフックをスキップする場合:

```bash
LEFTHOOK=0 git commit -m "message"
```

**注意**: 違反がある場合は、後で必ず修正してください。

## 段階的な移行

既存のコードベースに後からPackwerkを導入する場合、`package_todo.yml`を使用して段階的に移行できます。

### 1. 既存の違反を記録

```bash
bundle exec packwerk update-todo
```

これにより、既存の違反が`package_todo.yml`に記録されます。

### 2. 新しい違反を防止

`package_todo.yml`に記録された違反は許容されますが、**新しい違反は検出されます**。

### 3. 段階的に違反を解消

違反を修正したら、`package_todo.yml`から該当エントリーを削除します。

```bash
# 違反を修正後、TODOファイルを更新
bundle exec packwerk update-todo
```

## ベストプラクティス

### 1. 依存関係の最小化

パッケージ間の依存は最小限に保ちます。依存が増えすぎる場合は、設計を見直すサインです。

### 2. 公開APIの最小化

公開APIは必要最小限に抑えます。公開しすぎると、変更が困難になります。

### 3. 循環依存の回避

循環依存は必ず回避します。Packwerkが検出したら、設計を見直してください。

### 4. 定期的なチェック

CI/CDパイプラインでPackwerkチェックを実行し、違反を早期に検出します。

```yaml
# GitHub Actionsの例
- name: Run Packwerk check
  run: bundle exec packwerk check
```

## トラブルシューティング

### 違反が検出されたら

1. エラーメッセージを確認
2. 依存が必要なら`package.yml`に追加
3. 公開APIが必要なら`app/public/`に移動
4. 不要な依存なら、コードを修正

### パフォーマンスが遅い

大規模なコードベースでは、特定のパッケージのみチェックすることで高速化できます。

```bash
# 変更されたパッケージのみチェック
bundle exec packwerk check app/packages/hello/
```

## 関連ドキュメント

- [モジュラーモノリスアーキテクチャ](modular_monolith.md)
- [Packwerk公式ドキュメント](https://github.com/Shopify/packwerk)

## 参考リンク

- [ApplicationController](../app/controllers/application_controller.rb)
- [サンプルパッケージ設定](../app/packages/hello/package.yml)

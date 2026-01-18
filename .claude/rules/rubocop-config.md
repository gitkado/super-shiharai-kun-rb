# RuboCopの設定

- ベース: `rubocop-rails-omakase`
- プラグイン: `rubocop-packs`, `rubocop-rspec`
- Packwerk境界の強制:
  - `Packs/ClassMethodsAsPublicApis`: 有効（パターンマッチングで例外管理）
    - ActiveRecordモデル: `app/packages/*/app/public/*.rb`
    - Concern: `app/packages/*/app/public/**/*able.rb`
  - `Packs/RootNamespaceIsPackName`: 有効
- frozen_string_literal: 常に有効（自動修正可能）
- Sorbetのcops: すべて無効化（Sorbetを利用していないため）

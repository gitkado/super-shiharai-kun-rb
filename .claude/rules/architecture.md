# アーキテクチャ

## モジュラーモノリスの構造

```text
app/
├── controllers/         # 共通基盤 - ApplicationControllerと技術的concernのみ
├── models/              # 共通基盤 - ApplicationRecordと技術的concernのみ
├── jobs/                # 共通基盤 - ApplicationJobのみ
├── mailers/             # 共通基盤 - ApplicationMailerのみ
├── middleware/          # Rackミドルウェア（RequestTraceIdなど）
└── packages/            # ビジネスロジック層（全てのドメイン機能）
    └── hello/           # Helloドメイン（サンプル）
        ├── package.yml  # パッケージ設定
        ├── app/
        │   ├── controllers/  # 非公開（内部実装）
        │   └── public/       # 公開API（他パッケージから利用可能）
        └── spec/
```

## 重要な原則

**app直下（共通基盤・インフラ層）:**

- 基底クラス（Application*）
- 全パッケージで共有する技術的な機能
- Rackミドルウェア
- ビジネスロジックは禁止 → `app/packages/` へ

**app/packages/（ビジネスロジック層）:**

- 全てのドメイン固有のController, Model, Job, Mailer
- ビジネスルール、機能実装
- Railsの標準構成（MVC）に従う
- Fat Model, Skinny Controller

**公開APIの方針:**

- デフォルトは全て非公開（packages内のapp/配下）
- 他パッケージから利用されるものだけ `app/public/` に配置
- 公開API配置のパターン:
  - ActiveRecordモデル: `app/public/*.rb` (public直下)
  - サービスクラス: `app/public/<module>/*.rb`
  - Concern: `app/public/**/*able.rb` (*ableで終わる命名規則推奨)

## 新しいパッケージの追加

```bash
# 1. ディレクトリ構造作成
mkdir -p app/packages/your_domain/app/{controllers,models,jobs}
mkdir -p app/packages/your_domain/spec/requests

# 2. package.yml作成
cat > app/packages/your_domain/package.yml <<EOF
enforce_dependencies: true
enforce_privacy: true

dependencies:
  - "."  # ルートパッケージ（ApplicationControllerなど）
  # - "app/packages/authentication"  # 必要に応じて追加

public_path: app/public
EOF

# 3. Packwerkチェック
bundle exec packwerk validate
bundle exec packwerk check
```

## パッケージ間の依存関係ルール

- 各ドメインパッケージはルートパッケージに依存できる
- **循環依存は禁止**（Packwerkが検出）
- 他パッケージの非公開クラスへの直接参照は禁止（`app/public/` のみアクセス可能）

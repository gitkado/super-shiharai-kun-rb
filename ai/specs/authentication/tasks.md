# 認証機能 実装タスク

> **ステータス: ✅ 実装完了** (2025-10-24)

## 実装方針

**採用技術:** BCrypt + JWT gem 直接利用

当初はRodauth採用を計画していましたが、以下の理由からBCrypt + JWT直接利用に変更しました：
- 本プロジェクトの主目的は請求管理ドメインの実装であり、認証は標準的な実装で十分
- シンプルさ優先: RailsのFat Model, Skinny Controller方針に従い、保守しやすい構成
- Rodauth-rails gemは依存関係に残っていますが、現在は直接利用していません（将来の拡張用）

---

## 実装フェーズ

### フェーズ1: 基盤準備 ✅

- [x] Gemfile に依存gem追加（jwt, bcrypt, rodauth-rails）
- [x] `bundle install` 実行
- [x] `app/packages/authentication/package.yml` 作成
- [x] Packwerk検証成功

---

### フェーズ2: 環境設定 ✅

- [x] ディレクトリ構造作成
- [x] 環境変数設定（JWT_SECRET_KEY）
- [x] `.env.example` に追加
- [x] `dotenv-rails` gem追加

---

### フェーズ3: モデル実装 ✅

- [x] `Account` モデル作成
  - メールアドレスバリデーション（必須、形式、一意性）
  - メール正規化（小文字変換、空白除去）
  - status Enum定義（unverified/verified/locked/closed）
- [x] `AccountPasswordHash` モデル作成
  - BCryptパスワードハッシュ管理

---

### フェーズ4: マイグレーション ✅

- [x] `db/migrate/20251021025537_create_authentication_tables.rb` 作成
- [x] `accounts` テーブル作成（email, status）
- [x] `account_password_hashes` テーブル作成（account_id, password_hash）
- [x] インデックス・外部キー制約追加
- [x] マイグレーション実行（開発・テスト環境）

---

### フェーズ5: モデルテスト ✅

- [x] `app/packages/authentication/spec/models/account_spec.rb` 作成
- [x] バリデーションテスト
- [x] 正規化ロジックテスト
- [x] status Enumテスト
- [x] 24テストケース全てパス

---

### フェーズ6: Controller実装 ✅

- [x] `RegistrationsController` 作成（BCrypt直接利用）
  - `POST /api/v1/auth/register`
  - アカウント作成 + パスワードハッシュ保存 + JWT発行
- [x] `SessionsController` 作成
  - `POST /api/v1/auth/login`
  - BCryptパスワード検証 + JWT発行
- [x] ルーティング設定

---

### フェーズ7: 公開API実装 ✅

- [x] `Authentication::JwtService` 作成（公開API）
  - `generate(account)` - JWT生成
  - `decode(token)` - JWT検証・デコード
- [x] `Authentication::Authenticatable` concern作成（公開API）
  - `authenticate_account!` - JWT認証
  - `current_account` - 認証済みアカウント取得
- [x] `ApplicationController` に組み込み

---

### フェーズ8: リクエストスペック ✅

- [x] `registrations_spec.rb` 作成（14テスト）
  - 正常系: ユーザー登録とJWT発行
  - 異常系: メールアドレス重複、無効形式、パスワード不足
- [x] `sessions_spec.rb` 作成（24テスト）
  - 正常系: ログイン成功とJWT発行
  - 異常系: 認証失敗、パラメータ不足、アカウントステータス
  - JWT検証テスト

---

### フェーズ9: RSwag統合 ✅

- [x] `app/packages/authentication/spec/integration/authentication_spec.rb` 作成
- [x] OpenAPI仕様定義（登録・ログインエンドポイント）
- [x] `swagger/v1/swagger.yaml` 生成
- [x] 22テストケース全てパス

---

### フェーズ10: 統合テスト・品質チェック ✅

- [x] 全テスト実行: **122 examples, 0 failures**
- [x] RuboCop: 違反なし
- [x] Packwerk: 違反なし
- [x] Brakeman: 重大な脆弱性なし

---

## 実装ファイル一覧

```
app/packages/authentication/
├── package.yml
├── app/
│   ├── controllers/api/v1/auth/authentication/
│   │   ├── registrations_controller.rb
│   │   └── sessions_controller.rb
│   ├── models/
│   │   ├── account.rb
│   │   └── account_password_hash.rb
│   └── public/
│       ├── account.rb
│       └── authentication/
│           ├── authenticatable.rb
│           └── jwt_service.rb
└── spec/
    ├── models/account_spec.rb
    ├── requests/authentication/
    │   ├── registrations_spec.rb
    │   └── sessions_spec.rb
    └── integration/authentication_spec.rb

db/migrate/
└── 20251021025537_create_authentication_tables.rb
```

---

## APIエンドポイント

| メソッド | パス | 説明 |
|----------|------|------|
| POST | `/api/v1/auth/register` | ユーザー登録 |
| POST | `/api/v1/auth/login` | ログイン |

---

## 将来の拡張（未実装）

- [ ] トークンリフレッシュ機能
- [ ] パスワードリセット機能（メール送信）
- [ ] レート制限（Rack::Attack）
- [ ] アカウントロック機能
- [ ] ログイン履歴管理
- [ ] 2要素認証

# 認証機能 設計書

## 設計判断

### アーキテクチャ選定

| 項目 | 選定技術 | 理由 |
|------|---------|------|
| **認証方式** | BCrypt + JWT gem 直接利用 | シンプルで保守しやすい、学習コストが低い |
| **トークン方式** | JWT (HS256) | ステートレス認証、APIモードに最適 |
| **パスワードハッシュ** | bcrypt | 業界標準 |
| **パッケージ配置** | `app/packages/authentication/` | モジュラーモノリスの原則に従い独立ドメインとして配置 |

### 設計判断の経緯

**当初計画:** Rodauth + rodauth-rails を採用予定

**最終決定:** BCrypt + JWT gem 直接利用

**変更理由:**

1. **本プロジェクトの主目的は請求管理ドメインの実装** - 認証は標準的な実装で十分
2. **シンプルさ優先** - RailsのFat Model, Skinny Controller方針に従い、保守しやすい構成
3. **Rodauth APIの複雑さ** - Rails統合に追加の学習コストがかかる
4. **将来の拡張性** - パスワードリセット・2FA等が必要になれば、Rodauthへの段階的移行も可能

**補足:** `rodauth-rails` gemは依存関係に残っていますが、現在は直接利用していません。

---

## パッケージ構造

```text
app/packages/authentication/
├── package.yml                           # Packwerk設定
├── app/
│   ├── controllers/api/v1/auth/authentication/
│   │   ├── registrations_controller.rb   # ユーザー登録
│   │   └── sessions_controller.rb        # ログイン
│   ├── models/
│   │   ├── account.rb                    # ユーザーモデル
│   │   └── account_password_hash.rb      # パスワードハッシュ
│   └── public/                           # 公開API
│       ├── account.rb                    # Accountモデル公開
│       └── authentication/
│           ├── jwt_service.rb            # JWT生成・検証
│           └── authenticatable.rb        # 認証concern
└── spec/
    ├── models/account_spec.rb
    ├── requests/authentication/
    │   ├── registrations_spec.rb
    │   └── sessions_spec.rb
    └── integration/authentication_spec.rb
```

### package.yml

```yaml
enforce_dependencies: true
enforce_privacy: true

dependencies:
  - "."  # ルートパッケージ（ApplicationController, ApplicationRecord等）

public_path: app/public
```

---

## 主要クラスの責務

### 1. Account (`app/models/account.rb`)

**責務:**

- ユーザー情報管理
- メールアドレスバリデーション
- メール正規化（小文字変換）
- アカウントステータス管理（Enum）

**Enum定義:**

```ruby
enum :status, {
  unverified: "unverified",
  verified: "verified",
  locked: "locked",
  closed: "closed"
}, prefix: true
```

**バリデーション:**

- `email`: 必須、メール形式、一意性（大文字小文字区別なし）

### 2. AccountPasswordHash (`app/models/account_password_hash.rb`)

**責務:**

- BCryptパスワードハッシュの保存
- `belongs_to :account`

### 3. Authentication::JwtService (`app/public/authentication/jwt_service.rb`)

**責務:**

- JWT生成・検証（公開API）
- 他パッケージから利用可能

**主要メソッド:**

```ruby
module Authentication
  module JwtService
    def self.generate(account, expires_in: 3600)
      # JWT生成
    end

    def self.decode(token)
      # JWT検証・デコード
    end
  end
end
```

### 4. Authentication::Authenticatable (`app/public/authentication/authenticatable.rb`)

**責務:**

- 他パッケージから利用可能な認証ヘルパー
- JWT検証・デコード
- `current_account` 提供

**使用例:**

```ruby
class SomeController < ApplicationController
  before_action :authenticate_account!

  def index
    # current_account が利用可能
  end
end
```

### 5. RegistrationsController

**エンドポイント:** `POST /api/v1/auth/register`

**処理フロー:**

1. パラメータ検証
2. Accountレコード作成
3. BCryptでパスワードハッシュ化
4. AccountPasswordHashレコード作成
5. JWT発行
6. レスポンス返却

### 6. SessionsController

**エンドポイント:** `POST /api/v1/auth/login`

**処理フロー:**

1. メールアドレスでAccount検索
2. BCryptでパスワード検証
3. JWT発行
4. レスポンス返却

---

## データモデル

### ER図

```text
accounts ||--|| account_password_hashes : has_one

accounts {
    bigint id PK
    string email UK "NOT NULL"
    string status "DEFAULT 'verified'"
    timestamp created_at
    timestamp updated_at
}

account_password_hashes {
    bigint id PK
    bigint account_id FK "UNIQUE, NOT NULL"
    string password_hash "NOT NULL"
}
```

### テーブル定義

#### accounts

| カラム | 型 | 制約 | 説明 |
|--------|---|------|------|
| id | bigint | PK | アカウントID |
| email | string | NOT NULL, UNIQUE | メールアドレス |
| status | string | NOT NULL, DEFAULT 'verified' | ステータス |
| created_at | timestamp | NOT NULL | 作成日時 |
| updated_at | timestamp | NOT NULL | 更新日時 |

#### account_password_hashes

| カラム | 型 | 制約 | 説明 |
|--------|---|------|------|
| id | bigint | PK | ID |
| account_id | bigint | FK, UNIQUE, NOT NULL | アカウントID |
| password_hash | string | NOT NULL | bcryptハッシュ |

---

## APIエンドポイント

### POST /api/v1/auth/register

**リクエスト:**

```json
{
  "email": "user@example.com",
  "password": "secure_password123"
}
```

**レスポンス（成功 201）:**

```json
{
  "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "account": {
    "id": 1,
    "email": "user@example.com",
    "status": "verified"
  }
}
```

**レスポンス（失敗 422）:**

```json
{
  "error": {
    "code": "REGISTRATION_FAILED",
    "message": "Email has already been taken",
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  }
}
```

### POST /api/v1/auth/login

**リクエスト:**

```json
{
  "email": "user@example.com",
  "password": "secure_password123"
}
```

**レスポンス（成功 200）:**

```json
{
  "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "account": {
    "id": 1,
    "email": "user@example.com",
    "status": "verified"
  }
}
```

**レスポンス（失敗 401）:**

```json
{
  "error": {
    "code": "LOGIN_FAILED",
    "message": "Invalid email or password",
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  }
}
```

---

## 公開API（他パッケージ向け）

| モジュール/クラス | 配置 | 用途 |
|------------------|------|------|
| `Account` | `app/public/account.rb` | Accountモデル参照 |
| `Authentication::JwtService` | `app/public/authentication/jwt_service.rb` | JWT生成・検証 |
| `Authentication::Authenticatable` | `app/public/authentication/authenticatable.rb` | 認証concern |

---

## セキュリティ考慮事項

- パスワードはBCryptでハッシュ化して保存
- JWT秘密鍵は環境変数（`JWT_SECRET_KEY`）で管理
- ログイン失敗時のメッセージを統一（アカウント存在推測を防止）
- SQLインジェクション対策（ActiveRecordのパラメータ化クエリ）

---

## 将来の拡張オプション

### Rodauthへの移行

将来、以下の機能が必要になった場合、Rodauthへの段階的移行を検討：

- パスワードリセット（メール送信）
- 2要素認証
- アカウントロック機能
- SSO連携

`rodauth-rails` gemは依存関係に残っているため、必要に応じて有効化可能です。

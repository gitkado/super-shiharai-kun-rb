# プロジェクト概要

Ruby on Rails 7.2で構築した企業向け支払い管理システムのREST APIサービス。**モジュラーモノリス**アーキテクチャを採用し、Packwerkによるパッケージ境界の強制を行っています。

## 技術スタック

- Ruby 3.4.6（asdfまたはrbenv推奨、`.tool-versions`と`.ruby-version`参照）
- Rails 7.2.2
- PostgreSQL 16 (Docker)
- Redis 7
- Sidekiq (非同期ジョブ処理、将来実装予定)
- RSpec 7.1
- Packwerk 3.2 (パッケージ管理)
- **認証**: BCrypt + JWT（Rodauth不使用）

## 認証実装の方針（重要）

本プロジェクトの認証機能は **BCrypt + JWT gem の直接利用** により実装されています。

**現在の実装:**

- `app/packages/authentication/` パッケージ配下
- BCryptによるパスワードハッシュ化（`AccountPasswordHash`モデル）
- JWT gemによるトークン認証（`Authentication::JwtService`公開API）
- エンドポイント: `POST /api/v1/auth/register`, `POST /api/v1/auth/login`

**この設計判断の理由:**

1. **本プロジェクトの主目的は請求管理ドメインの実装**であり、認証は標準的な実装で十分
2. **シンプルさ優先**: RailsのFat Model, Skinny Controller方針に従い、保守しやすい構成
3. **将来の拡張性**: パスワードリセット・2FA等が必要になれば、Rodauthへの段階的移行も可能

**重要: Rodauthについて**

- `rodauth-rails` gemは依存関係に含まれていますが、**現在は直接利用していません**（将来の拡張用に保持）
- 新規認証機能を実装する際は、まずBCrypt + JWTの枠内で実装できないか検討すること
- Rodauth導入を提案する場合は、その必要性を明確に説明し、ユーザーの承認を得ること

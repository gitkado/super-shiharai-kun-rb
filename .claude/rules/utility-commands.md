# その他のコマンド

## ヘルスチェック

```bash
# アプリケーションが起動しているか確認
curl -if http://localhost:3000/up
```

## データベース操作

```bash
# マイグレーション実行
bin/rails db:migrate

# ロールバック
bin/rails db:rollback

# データベースリセット（開発環境のみ）
bin/rails db:reset

# シードデータ投入
bin/rails db:seed
```

**データベース接続情報:**

- `config/database.yml` および `docker-compose.yml` を参照
- デフォルト: PostgreSQL on localhost:5432

## コンソール

```bash
# Railsコンソール起動
bin/rails console

# 特定環境で起動
RAILS_ENV=test bin/rails console
```

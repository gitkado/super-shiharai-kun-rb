---
name: lint
description: RuboCop・Packwerk・Brakeman をまとめて実行する品質チェックコマンド
command: "bundle exec rubocop && bundle exec packwerk check && bundle exec brakeman -q"
---
`/lint` は主要な静的解析とセキュリティチェックを一括で走らせます。

- RuboCop: スタイルと簡易的な不具合検知
- Packwerk: パッケージ境界の依存関係違反を検出
- Brakeman: Rails 向けセキュリティ診断（サイレンスモード）

失敗したツールがあればログを確認し、修正後に再実行してください。テスト前やコミット前のゲートとして活用できます。

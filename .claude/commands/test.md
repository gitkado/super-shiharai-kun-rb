---
name: test
description: RSpec全体または指定ファイルを実行するテスト用スラッシュコマンド
command: "bundle exec rspec ${args:-}"
argumentHint: "[spec_path | options]"
---
`/test` は RSpec を起動して、プロジェクト全体または引数で指定した spec のみを実行します。

- 引数なし: 全テストを実行（時間がかかるため必要に応じて絞り込み推奨）
- 引数あり: `bundle exec rspec <SPEC>` と同じ構文で任意の spec を指定
- 例: `/test spec/packages/foo/bar_spec.rb`

テストが失敗した場合は直前のログを参照し、必要なら `/lint` や `/commit-plan` の実行前に修正してください。

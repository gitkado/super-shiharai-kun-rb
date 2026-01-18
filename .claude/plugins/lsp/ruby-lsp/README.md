# ruby-lsp Plugin

Ruby language server for Claude Code.

## Prerequisites

ruby-lsp gemがインストールされている必要があります：

```bash
gem install ruby-lsp
```

## Supported Extensions

- `.rb`, `.rbw` - Ruby
- `.rake` - Rake files
- `.gemspec` - Gem specifications
- `.ru` - Rack config
- `.builder`, `.jbuilder` - Builder templates
- `.erb` - ERB templates

## Usage

マーケットプレイス経由で有効化（親ディレクトリのREADME参照）:

```
/plugin enable ruby-lsp@local-lsp
```

## LSP機能

- 定義へ移動（Go to Definition）
- 参照検索（Find References）
- ホバー情報（Hover）
- 診断（Diagnostics）

## 補足

Claude公式のplugin(claude-plugins-official)に追加される流れも観測しているので、追加されたら公式版を利用する
- https://github.com/anthropics/claude-plugins-official/pull/106

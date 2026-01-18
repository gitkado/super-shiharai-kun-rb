# AI開発ディレクトリ（`ai/`）

Claude Codeの `/dev` と `/verify` コマンドが使用する開発支援ディレクトリ。

## ディレクトリ構造

```
ai/
├── board.md              # 作業ボード（現在の実装状況）
├── specs/                # 機能仕様（永続保存）
│   └── <feature>/
│       ├── requirements.md
│       ├── design.md
│       └── tasks.md
└── README.md             # 運用ガイド
```

## タブ分離（並列作業）

| タブ | コマンド | 役割 | 編集権限 |
|------|----------|------|----------|
| Dev | `/dev` | 設計・実装・コミット | あり |
| Verify | `/verify` | テスト・レビュー | なし（報告のみ） |

詳細ガイド: `ai/README.md`

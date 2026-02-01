---
name: skill-create
description: ALWAYS use this skill to create or migrate Claude Code skills and agents. スキルの新規作成・既存スキルの規約準拠への改修に使用。Trigger words include: スキル作成, skill作成, 新しいスキル, スキル改修, migrate skill, add skill, create skill.
argument-hint: "[スキル名や目的] | migrate [スキル名]"
---

# スキル作成・改修ワークフロー

プロジェクトの規約に沿った品質の一定したスキルを対話的に作成・改修する。

## モード

| モード | 使い方 | 説明 |
|--------|--------|------|
| 新規作成（デフォルト） | `/skill-create <目的>` | 新しいスキルを対話的に作成 |
| 改修 | `/skill-create migrate <name>` | 既存スキルをガイドライン準拠に改修 |

---

## 新規作成モード

### Step 1: ユースケース定義

ユーザーに以下をヒアリングする（AskUserQuestion使用）:

1. **目的**: スキルが何をするか
2. **トリガー**: いつ使うか（具体的なフレーズ）
3. **ユースケース**: 2-3の具体的な使用シナリオ
4. **権限**: 読み取り専用か、編集可能か、git操作が必要か
5. **エージェント委譲**: 複数フェーズの自動パイプラインが必要か

### Step 2: スキル設計

ヒアリング結果から設計を決定し、ユーザーに提示して確認を得る。

決定事項:

- name（ケバブケース）
- description（新ガイド形式: 強い指示語 + バイリンガル + トリガーワード）
- argument-hint
- disable-model-invocation（手動操作のみの場合）
- エージェント委譲の有無と構成
- 権限レベル

### Step 3: ファイル生成

設計に基づいてファイルを生成する:

1. `.claude/skills/<name>/SKILL.md`
2. エージェント委譲ありの場合: `.claude/agents/<name>-agent.md`

### Step 4: 検証

1. フロントマターの構文チェック（YAMLバリデーション）
2. 既存スキルとの名前衝突チェック（`ls .claude/skills/`）
3. 生成されたファイルの内容をユーザーに提示
4. ユーザーの承認を得る
5. CCを再起動して `/` で呼び出せることを確認するよう案内

---

## 改修（migrate）モード

`/skill-create migrate <name>` で実行。

### Step M1: 現状読み取り

既存のスキルファイル・エージェントファイルを読み込む:

- `.claude/skills/<name>.md`（フラットファイル）
- `.claude/skills/<name>/SKILL.md`（フォルダ形式）
- `.claude/agents/<name>*.md`（関連エージェント）

### Step M2: 規約チェック・差分レポート

プロジェクト規約チェックリストと照合し、差分をレポートする:

- [ ] ディレクトリ: フォルダ形式（`<name>/SKILL.md`）になっているか
- [ ] description: 強い指示語 + バイリンガル + トリガーワード形式か
- [ ] 制約セクション: ファイル編集/git操作の許可・禁止が明記されているか
- [ ] モードがある場合: モード別の動作が定義されているか
- [ ] レポート系: severity levelsは [BLOCKER]/[MUST]/[NICE] を使用しているか
- [ ] エージェント委譲: tools は必要最小限、model: sonnet か
- [ ] エラーハンドリング: 主要なエラーケースの対応が記載されているか
- [ ] Quick Start セクション（該当する場合）
- [ ] 注意事項（Caveats）セクション（該当する場合）

### Step M3: 改修提案

具体的な変更内容をユーザーに提示する:

- フラットファイル → フォルダ形式への移行
- description の新ガイド形式対応
- 本文構造の整備（重要な制約、Quick Start 等の追加）
- エージェントファイルの調整（必要な場合）

### Step M4: 承認・適用

ユーザーの承認後にファイルを編集する。
フォルダ移行時は旧ファイルの削除を案内する。

---

## 共通: description形式（必須）

```text
ALWAYS/MUST + 英語の動詞句。日本語の説明文。Trigger words include: キーワード1, キーワード2.
```

例:

```text
ALWAYS use this skill to check SmartHR Design System compliance. コード解析とブラウザ検証でsmarthr-uiの使い方を確認する。Trigger words include: DS準拠, デザインシステム, smarthr-ui確認, ds-check.
```

## 共通: スキルファイル標準構造

```markdown
---
name: <name>
description: <新ガイド形式>
argument-hint: "<引数>"
---

# <スキル名>

## 重要な制約
- ファイル編集: 許可/禁止
- git操作: 許可/禁止

## Quick Start（該当する場合）
簡潔な使用例

## モード別の動作（モードがある場合）

## 実行方法
（エージェント委譲の場合はTask toolへの委譲を記載）

## レポート形式（レポート系の場合）

## 注意事項
```

## 共通: エージェントファイルテンプレート（必要な場合のみ）

```yaml
---
name: <name>
description: <説明>
tools: <必要なツールのみ>
model: sonnet
---
```

- 読み取り専用: `tools: Read, Grep, Glob, Bash`
- 編集可能: `tools: Read, Edit, Write, Bash, Grep, Glob`

## 共通: 権限パターン

| パターン | ファイル編集 | git | 用途 |
|----------|------------|-----|------|
| 読み取り専用 | 禁止 | 禁止 | 検証・レポート系 |
| 編集可 | 許可 | add/commit可 | 実装系 |
| 手動操作 | 禁止 | push可 | デプロイ系 |

## 既存スキル一覧（参考）

| スキル | 説明 | エージェント委譲 |
|--------|------|----------------|
| dev | 設計・TDD実装・コミット統合 | tdd-executor |
| verify | テスト・レビュー | verifier |
| ds-check | SmartHR DS準拠チェック | ds-checker |
| test | RSpec実行 | なし |
| lint | RuboCop/Packwerk/Brakeman | なし |
| review | コードレビュー | なし |
| design | 要件定義・設計 | なし |
| commit | コミット作成 | なし |
| pr | PR作成・push | なし |

## 参考資料

スキル設計の詳細なガイドラインは `references/skills-guide.md` を参照。

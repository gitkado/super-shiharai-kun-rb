---
name: commit-diff
description: コミット計画を策定・実行（diff分析→分割判断→実行→フック失敗リカバリ）
disable-model-invocation: true
---

あなたはコミット職人です。変更内容を分析し、Conventional Commitsベースのコミット計画を提案・実行します。

## フロー

```text
1. 状況確認 → 2. diff分析 → 3. 分割判断 → 4. コミット計画提示 → 5. 実行 → (6. フック失敗時リカバリ)
```

## 1. 状況確認

以下を**並列**で実行し、ワーキングツリーの状態を把握する。

```bash
git diff --staged --stat   # ステージ済み変更
git diff --stat            # 未ステージ変更
git status --short         # 全体状況（未追跡ファイル含む）
```

**判定:**

- **ステージ済みあり** → Step 2 へ
- **ステージ済みなし・未ステージあり** → 未ステージの変更内容を提示し、ステージするか確認
- **変更なし** → 「コミット対象の変更がありません」と報告して終了

## 2. diff分析

`git diff --staged` の内容を読み、以下を分類する。

| 分類軸 | 具体例 |
|--------|--------|
| 変更カテゴリ | 機能追加 / バグ修正 / リファクタ / テスト / 設定 / ドキュメント / 依存更新 |
| 影響パッケージ | `app/packages/<name>/` 単位で特定 |
| 横断変更 | `app/` 直下（共通基盤）、`lib/`、`config/`、ルート直下のファイル |
| インフラファイル | migrate, schema.rb, Gemfile/Gemfile.lock, swagger, routes.rb |

## 3. 分割判断

### 単一コミットで十分な条件

以下を**すべて**満たす場合、分割せず1コミットにする。

1. 変更ファイル10個以下
2. 単一の論理的変更（1つの目的）
3. 影響パッケージが1つ以下
4. インフラファイルが機能変更と不可分（例: migrationと対応するモデル追加）

### 分割アルゴリズム（優先順位順）

上記条件を満たさない場合、以下の優先順位で分割する。
**重要**: 各ステップで「分離するとコミット単体でビルド/テストが通らなくなる」場合は分離しない（不可分性優先）。

1. **インフラファイル分離** — migrate, schema.rb, Gemfile/Gemfile.lock, swagger/*.yaml, routes.rb（ただしmigration+対応モデルなど不可分な場合はまとめる）
2. **パッケージ単位分離** — `app/packages/<name>/` ごとに分ける
3. **TDDフェーズ分離** — test → feat/fix → refactor の順
4. **設定・ドキュメント分離** — config/, .rubocop.yml, *.md など
5. **横断変更** — `app/` 直下、`lib/`、`config/` などパッケージ外の変更は関連する機能コミットに含めるか、独立した `chore:` / `refactor:` コミットにする

## 4. コミットメッセージ形式

### ルール

- **1行のみ**（本文なし。ただし破壊的変更時は `type!:` 形式を使用）
- **日本語**で要約、**72文字以内**推奨
- **タイプ**: `feat:` / `fix:` / `refactor:` / `test:` / `chore:` / `docs:` / `perf:` / `ci:` / `revert:`
- **スコープ**: 原則なし。**Dependabot由来のみ** `chore(deps):` / `chore(deps-dev):` を許容
- **破壊的変更**: `feat!:` のように `!` を付与（本文やフッターは使わない）
- **Co-Authored-By トレーラー禁止**

### 例

```text
feat: ユーザー認証APIを追加
fix: ログイン時のエラーハンドリングを修正
test: 請求書承認APIのテストを追加
refactor: 承認ロジックをサービスに抽出
chore: マイグレーションを追加
docs: API仕様書を更新
chore(deps): lefthookを2.1.1に更新
```

## 5. コミット計画提示と実行

### 計画提示フォーマット

```markdown
## コミット計画

### Commit 1
**タイトル**: test: 請求書承認APIのテストを追加
**対象ファイル**:
- spec/requests/api/v1/invoices/approve_spec.rb

---

### Commit 2
**タイトル**: feat: 請求書承認APIを実装
**対象ファイル**:
- app/packages/invoice/app/controllers/api/v1/invoices/approvals_controller.rb
- config/routes.rb
```

ユーザーに確認後、実行する。

### 実行方法

**単一コミットの場合:**

```bash
git commit -m "$(cat <<'EOF'
feat: ユーザー認証APIを追加
EOF
)"
```

**複数コミットの場合:**

最初のコミット対象以外をアンステージし、コミット単位でadd→commitを繰り返す。

```bash
# Commit 1: 対象外をアンステージ
git restore --staged app/packages/invoice/app/controllers/api/v1/invoices/approvals_controller.rb config/routes.rb
git commit -m "$(cat <<'EOF'
test: 請求書承認APIのテストを追加
EOF
)"

# Commit 2: 残りをステージ
git add app/packages/invoice/app/controllers/api/v1/invoices/approvals_controller.rb config/routes.rb
git commit -m "$(cat <<'EOF'
feat: 請求書承認APIを実装
EOF
)"
```

**注意**: 1ファイル内に複数論点が混在する場合は `git add -p` でhunk単位のステージングを検討する。

## 6. pre-commitフック失敗時リカバリ

### フック構成（Lefthook）

pre-commitで以下が**並列実行**される:

| フック | 対象 | タグ |
|--------|------|------|
| RuboCop | `**/*.{rb,rake}` | backend |
| Packwerk validate | 全体 | packwerk |
| Packwerk check | `**/*.rb` | packwerk |
| RSpec | 全テスト（fail-fast） | test |
| markdownlint | `**/*.md` | docs |

### 失敗パターン別対応

| フック | 典型的な失敗 | 対応 |
|--------|-------------|------|
| RuboCop | スタイル違反 | `bundle exec rubocop -A <files>` で自動修正 → 再ステージ → コミット再試行 |
| Packwerk | 境界違反・定数参照エラー | publicパス・依存設定を修正 → 再ステージ → コミット再試行 |
| RSpec | テスト失敗 | テストまたは実装を修正 → 再ステージ → コミット再試行 |
| markdownlint | Markdownスタイル違反 | `npx markdownlint-cli2 --fix <files>` で自動修正 → 再ステージ → コミット再試行 |

### markdownlintハング問題

markdownlintが`staged_files`展開で応答しなくなる場合がある。**ユーザーに状況を説明し、許可を得てから**以下で回避:

```bash
LEFTHOOK_EXCLUDE=docs git commit -m "$(cat <<'EOF'
コミットメッセージ
EOF
)"
```

### リカバリの原則

- **`--amend` は使わない** — フック失敗時コミットは作成されていないため、amendすると前のコミットを破壊する
- フック失敗 = コミット未生成。修正後は**同じコミットメッセージで再試行**する（「新規コミット」ではない）
- フックスキップ（`LEFTHOOK=0` / `LEFTHOOK_EXCLUDE`）は**ユーザーの明示的指示がある場合のみ**

## 禁止事項

- `git commit --amend` の使用
- Co-Authored-By トレーラーの付与
- `git push`（ユーザーが明示的に依頼した場合のみ）
- `LEFTHOOK=0` や `--no-verify` によるフックスキップ（ユーザー指示なし時）

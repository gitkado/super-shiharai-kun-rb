# 請求書管理機能 実装タスク

> **実装者へ:** このドキュメントは architect が作成した初期ドラフトです。実装を進めながら適宜更新してください。

## 実装フェーズ

### フェーズ1: 基盤準備

- [ ] **ディレクトリ構造作成**

  ```bash
  mkdir -p app/packages/invoice/app/controllers/api/v1
  mkdir -p app/packages/invoice/app/models
  mkdir -p app/packages/invoice/spec/models
  mkdir -p app/packages/invoice/spec/requests/api/v1
  ```

- [ ] **package.yml 作成**
  - ファイル: `app/packages/invoice/package.yml`
  - 内容:

    ```yaml
    enforce_dependencies: true
    enforce_privacy: true

    dependencies:
      - "."  # ルートパッケージ（ApplicationControllerなど）
      - "app/packages/authentication"  # JWT認証機能

    public_path: app/public
    ```

- [ ] **AppConfig設定追加**
  - ファイル: `config/app_config.rb`
  - 以下のメソッドを追加:

    ```ruby
    def invoice_fee_rate(default_value = 0.04)
      fetch_float("INVOICE_FEE_RATE", default_value)
    end

    def invoice_tax_rate(default_value = 0.10)
      fetch_float("INVOICE_TAX_RATE", default_value)
    end
    ```

  - private メソッドに追加:

    ```ruby
    def fetch_float(key, default_value)
      ENV.fetch(key, default_value).to_f
    end
    ```

- [ ] **環境変数設定**
  - `.env.example` に追加:

    ```bash
    # Invoice Management - Fee and Tax Rates
    # Fee rate for payment processing (default: 4%)
    INVOICE_FEE_RATE=0.04
    # Tax rate for consumption tax (default: 10%)
    INVOICE_TAX_RATE=0.10
    ```

  - `.env` ファイルに同じ内容を追加（Git管理外）

- [ ] **検証コマンド:**

  ```bash
  # ディレクトリ構造確認
  ls -la app/packages/invoice/

  # Packwerk検証
  bundle exec packwerk validate

  # 環境変数確認
  grep INVOICE .env.example
  ```

- [ ] **コミット:** `chore(config): 請求書管理用環境変数を追加`

---

### フェーズ2: 値オブジェクト実装

#### 2-1. Money 値オブジェクト

- [ ] **Moneyクラス作成**
  - ファイル: `app/packages/invoice/app/models/money.rb`
  - 内容:

    ```ruby
    # frozen_string_literal: true

    # 金額を表す値オブジェクト
    # 責務: BigDecimalによる精度保証、演算メソッド提供、ActiveRecord統合
    class Money
      include Comparable

      attr_reader :value

      def initialize(value)
        @value = BigDecimal(value.to_s).round(2)
      end

      # 加算
      def +(other)
        Money.new(@value + other.value)
      end

      # 減算
      def -(other)
        Money.new(@value - other.value)
      end

      # 乗算（料率との掛け算）
      def *(rate)
        case rate
        when Rate
          Money.new(@value * rate.value)
        when Numeric
          Money.new(@value * rate)
        else
          raise ArgumentError, "Cannot multiply Money by #{rate.class}"
        end
      end

      # 比較
      def <=>(other)
        @value <=> other.value
      end

      def to_s
        sprintf("%.2f", @value)
      end

      # ActiveRecord Attributes統合
      class Type < ActiveRecord::Type::Value
        def cast(value)
          case value
          when Money
            value
          when Numeric, String
            Money.new(value)
          else
            nil
          end
        end

        def serialize(value)
          value&.value
        end

        def deserialize(value)
          value ? Money.new(value) : nil
        end
      end
    end
    ```

- [ ] **Moneyユニットテスト作成**
  - ファイル: `app/packages/invoice/spec/models/money_spec.rb`
  - 内容:

    ```ruby
    require "rails_helper"

    RSpec.describe Money, type: :model do
      describe "#initialize" do
        it "creates Money from integer" do
          money = Money.new(100)
          expect(money.value).to eq(BigDecimal("100.00"))
        end

        it "creates Money from string" do
          money = Money.new("100.50")
          expect(money.value).to eq(BigDecimal("100.50"))
        end

        it "rounds to 2 decimal places" do
          money = Money.new("100.999")
          expect(money.value).to eq(BigDecimal("101.00"))
        end
      end

      describe "arithmetic operations" do
        let(:money1) { Money.new(100) }
        let(:money2) { Money.new(50) }

        it "adds two Money objects" do
          result = money1 + money2
          expect(result.value).to eq(BigDecimal("150.00"))
        end

        it "subtracts two Money objects" do
          result = money1 - money2
          expect(result.value).to eq(BigDecimal("50.00"))
        end

        it "multiplies Money by Rate" do
          rate = Rate.new(0.04)
          result = money1 * rate
          expect(result.value).to eq(BigDecimal("4.00"))
        end

        it "multiplies Money by Numeric" do
          result = money1 * 2
          expect(result.value).to eq(BigDecimal("200.00"))
        end
      end

      describe "comparison" do
        it "compares Money objects" do
          expect(Money.new(100)).to be > Money.new(50)
          expect(Money.new(50)).to be < Money.new(100)
          expect(Money.new(100)).to eq(Money.new(100))
        end
      end

      describe "#to_s" do
        it "returns string representation with 2 decimal places" do
          money = Money.new("100.50")
          expect(money.to_s).to eq("100.50")
        end

        it "returns string with trailing zeros" do
          money = Money.new("100")
          expect(money.to_s).to eq("100.00")
        end
      end

      describe "ActiveRecord Type" do
        it "casts string to Money" do
          type = Money::Type.new
          result = type.cast("100.50")
          expect(result).to be_a(Money)
          expect(result.value).to eq(BigDecimal("100.50"))
        end

        it "serializes Money to BigDecimal" do
          type = Money::Type.new
          money = Money.new(100)
          result = type.serialize(money)
          expect(result).to eq(BigDecimal("100.00"))
        end

        it "deserializes BigDecimal to Money" do
          type = Money::Type.new
          result = type.deserialize(BigDecimal("100.50"))
          expect(result).to be_a(Money)
          expect(result.value).to eq(BigDecimal("100.50"))
        end
      end
    end
    ```

- [ ] **テスト実行**

  ```bash
  bundle exec rspec app/packages/invoice/spec/models/money_spec.rb
  ```

- [ ] **コミット:** `feat(pack-invoice): Money値オブジェクトを追加`

#### 2-2. Rate 値オブジェクト

- [ ] **Rateクラス作成**
  - ファイル: `app/packages/invoice/app/models/rate.rb`
  - 内容:

    ```ruby
    # frozen_string_literal: true

    # 料率（割合）を表す値オブジェクト
    # 責務: BigDecimalによる精度保証（小数点4桁）、ActiveRecord統合
    class Rate
      include Comparable

      attr_reader :value

      def initialize(value)
        @value = BigDecimal(value.to_s).round(4)
      end

      # 比較
      def <=>(other)
        @value <=> other.value
      end

      def to_s
        sprintf("%.4f", @value)
      end

      # パーセント表示（0.04 → "4.00"）
      def to_percent
        sprintf("%.2f", @value * 100)
      end

      # ActiveRecord Attributes統合
      class Type < ActiveRecord::Type::Value
        def cast(value)
          case value
          when Rate
            value
          when Numeric, String
            Rate.new(value)
          else
            nil
          end
        end

        def serialize(value)
          value&.value
        end

        def deserialize(value)
          value ? Rate.new(value) : nil
        end
      end
    end
    ```

- [ ] **Rateユニットテスト作成**
  - ファイル: `app/packages/invoice/spec/models/rate_spec.rb`
  - 内容:

    ```ruby
    require "rails_helper"

    RSpec.describe Rate, type: :model do
      describe "#initialize" do
        it "creates Rate from float" do
          rate = Rate.new(0.04)
          expect(rate.value).to eq(BigDecimal("0.0400"))
        end

        it "creates Rate from string" do
          rate = Rate.new("0.1234")
          expect(rate.value).to eq(BigDecimal("0.1234"))
        end

        it "rounds to 4 decimal places" do
          rate = Rate.new("0.12345")
          expect(rate.value).to eq(BigDecimal("0.1235"))
        end
      end

      describe "comparison" do
        it "compares Rate objects" do
          expect(Rate.new(0.1)).to be > Rate.new(0.05)
          expect(Rate.new(0.05)).to be < Rate.new(0.1)
          expect(Rate.new(0.1)).to eq(Rate.new(0.1))
        end
      end

      describe "#to_s" do
        it "returns string representation with 4 decimal places" do
          rate = Rate.new(0.04)
          expect(rate.to_s).to eq("0.0400")
        end

        it "returns string with trailing zeros" do
          rate = Rate.new(0.1)
          expect(rate.to_s).to eq("0.1000")
        end
      end

      describe "#to_percent" do
        it "returns percentage representation with 2 decimal places" do
          rate = Rate.new(0.04)
          expect(rate.to_percent).to eq("4.00")
        end

        it "returns percentage with trailing zeros" do
          rate = Rate.new(0.1)
          expect(rate.to_percent).to eq("10.00")
        end
      end

      describe "ActiveRecord Type" do
        it "casts string to Rate" do
          type = Rate::Type.new
          result = type.cast("0.04")
          expect(result).to be_a(Rate)
          expect(result.value).to eq(BigDecimal("0.0400"))
        end

        it "serializes Rate to BigDecimal" do
          type = Rate::Type.new
          rate = Rate.new(0.04)
          result = type.serialize(rate)
          expect(result).to eq(BigDecimal("0.0400"))
        end

        it "deserializes BigDecimal to Rate" do
          type = Rate::Type.new
          result = type.deserialize(BigDecimal("0.1000"))
          expect(result).to be_a(Rate)
          expect(result.value).to eq(BigDecimal("0.1000"))
        end
      end
    end
    ```

- [ ] **テスト実行**

  ```bash
  bundle exec rspec app/packages/invoice/spec/models/rate_spec.rb
  ```

- [ ] **コミット:** `feat(pack-invoice): Rate値オブジェクトを追加`

---

### フェーズ3: マイグレーション作成・実行

- [ ] **マイグレーション生成**
  ```bash
  bin/rails generate migration CreateInvoices
  ```

- [ ] **マイグレーションファイル編集**
  - ファイル: `db/migrate/YYYYMMDDHHMMSS_create_invoices.rb`
  - 内容:
    ```ruby
    class CreateInvoices < ActiveRecord::Migration[7.2]
      def change
        create_table :invoices do |t|
          t.bigint :user_id, null: false
          t.date :issue_date, null: false
          t.decimal :payment_amount, precision: 15, scale: 2, null: false
          t.decimal :fee, precision: 15, scale: 2, null: false
          t.decimal :fee_rate, precision: 5, scale: 4, null: false
          t.decimal :tax_amount, precision: 15, scale: 2, null: false
          t.decimal :tax_rate, precision: 5, scale: 4, null: false
          t.decimal :total_amount, precision: 15, scale: 2, null: false
          t.date :payment_due_date, null: false
          t.timestamps
        end

        add_index :invoices, :user_id
        add_index :invoices, :payment_due_date
        add_foreign_key :invoices, :accounts, column: :user_id, on_delete: :cascade

        # PostgreSQLのCHECK制約（payment_amount > 0）
        reversible do |dir|
          dir.up do
            execute <<-SQL
              ALTER TABLE invoices ADD CONSTRAINT invoices_payment_amount_positive CHECK (payment_amount > 0);
            SQL
          end

          dir.down do
            execute <<-SQL
              ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_payment_amount_positive;
            SQL
          end
        end
      end
    end
    ```

- [ ] **マイグレーション実行**
  ```bash
  # 開発環境
  bin/rails db:migrate

  # テスト環境
  RAILS_ENV=test bin/rails db:migrate
  ```

- [ ] **検証コマンド:**

  ```bash
  # テーブルが作成されたか確認
  bin/rails runner "puts ActiveRecord::Base.connection.tables.include?('invoices')"

  # スキーマ確認
  grep -A 20 "create_table \"invoices\"" db/schema.rb
  ```

- [ ] **コミット:** `chore(migration): invoicesテーブルを追加`
- [ ] **コミット:** `chore(schema): schema.rbを更新`

---

### フェーズ4: Invoiceモデル実装

- [ ] **Invoiceモデル作成**
  - ファイル: `app/packages/invoice/app/models/invoice.rb`
  - 内容:

    ```ruby
    # frozen_string_literal: true

    # 請求書モデル
    # 責務: 請求書データの永続化・バリデーション、手数料・税額・合計金額の自動計算
    class Invoice < ApplicationRecord
      # ActiveRecord Attributes（値オブジェクト）
      attribute :payment_amount, Money::Type.new
      attribute :fee, Money::Type.new
      attribute :fee_rate, Rate::Type.new
      attribute :tax_amount, Money::Type.new
      attribute :tax_rate, Rate::Type.new
      attribute :total_amount, Money::Type.new

      # バリデーション
      validates :user_id, presence: true
      validates :issue_date, presence: true
      validates :payment_amount, presence: true
      validates :payment_due_date, presence: true
      validate :payment_due_date_after_issue_date
      validate :payment_amount_positive

      # コールバック
      before_validation :calculate_fees_and_taxes, if: :payment_amount_changed?

      # スコープ
      scope :between_payment_due_dates, ->(start_date, end_date) {
        where(payment_due_date: start_date..end_date)
      }

      private

      # 手数料・税額・合計金額を自動計算
      def calculate_fees_and_taxes
        self.fee_rate ||= Rate.new(AppConfig.invoice_fee_rate)
        self.tax_rate ||= Rate.new(AppConfig.invoice_tax_rate)

        self.fee = payment_amount * fee_rate.value
        self.tax_amount = fee * tax_rate.value
        self.total_amount = payment_amount + fee + tax_amount
      end

      def payment_due_date_after_issue_date
        return unless issue_date && payment_due_date

        if payment_due_date < issue_date
          errors.add(:payment_due_date, "must be on or after issue_date")
        end
      end

      def payment_amount_positive
        return unless payment_amount

        if payment_amount.value <= 0
          errors.add(:payment_amount, "must be greater than 0")
        end
      end
    end
    ```

- [ ] **Invoiceユニットテスト作成**
  - ファイル: `app/packages/invoice/spec/models/invoice_spec.rb`
  - 内容:

    ```ruby
    require "rails_helper"

    RSpec.describe Invoice, type: :model do
      # テスト用のアカウント作成
      let(:account) { Account.create!(email: "test@example.com", status: "verified") }

      describe "validations" do
        subject {
          Invoice.new(
            user_id: account.id,
            issue_date: Date.today,
            payment_amount: Money.new(100000),
            payment_due_date: Date.today + 30.days
          )
        }

        it { should validate_presence_of(:user_id) }
        it { should validate_presence_of(:issue_date) }
        it { should validate_presence_of(:payment_amount) }
        it { should validate_presence_of(:payment_due_date) }

        context "payment_due_date validation" do
          it "accepts payment_due_date on or after issue_date" do
            invoice = Invoice.new(
              user_id: account.id,
              issue_date: Date.today,
              payment_amount: Money.new(100000),
              payment_due_date: Date.today
            )
            expect(invoice.valid?).to be(true)
          end

          it "rejects payment_due_date before issue_date" do
            invoice = Invoice.new(
              user_id: account.id,
              issue_date: Date.today,
              payment_amount: Money.new(100000),
              payment_due_date: Date.today - 1.day
            )
            expect(invoice.valid?).to be(false)
            expect(invoice.errors[:payment_due_date]).to include("must be on or after issue_date")
          end
        end

        context "payment_amount validation" do
          it "accepts positive payment_amount" do
            invoice = Invoice.new(
              user_id: account.id,
              issue_date: Date.today,
              payment_amount: Money.new(1),
              payment_due_date: Date.today + 30.days
            )
            expect(invoice.valid?).to be(true)
          end

          it "rejects zero payment_amount" do
            invoice = Invoice.new(
              user_id: account.id,
              issue_date: Date.today,
              payment_amount: Money.new(0),
              payment_due_date: Date.today + 30.days
            )
            expect(invoice.valid?).to be(false)
            expect(invoice.errors[:payment_amount]).to include("must be greater than 0")
          end

          it "rejects negative payment_amount" do
            invoice = Invoice.new(
              user_id: account.id,
              issue_date: Date.today,
              payment_amount: Money.new(-100),
              payment_due_date: Date.today + 30.days
            )
            expect(invoice.valid?).to be(false)
          end
        end
      end

      describe "#calculate_fees_and_taxes" do
        it "calculates fees with default rates" do
          invoice = Invoice.create!(
            user_id: account.id,
            issue_date: Date.today,
            payment_amount: Money.new(100000),
            payment_due_date: Date.today + 30.days
          )

          # fee = 100000 × 0.04 = 4000
          expect(invoice.fee.value).to eq(BigDecimal("4000.00"))
          # tax_amount = 4000 × 0.10 = 400
          expect(invoice.tax_amount.value).to eq(BigDecimal("400.00"))
          # total_amount = 100000 + 4000 + 400 = 104400
          expect(invoice.total_amount.value).to eq(BigDecimal("104400.00"))

          # 料率も保存される
          expect(invoice.fee_rate.value).to eq(BigDecimal("0.0400"))
          expect(invoice.tax_rate.value).to eq(BigDecimal("0.1000"))
        end

        it "calculates fees with custom rates" do
          original_fee_rate = ENV["INVOICE_FEE_RATE"]
          original_tax_rate = ENV["INVOICE_TAX_RATE"]

          begin
            # 環境変数を一時的に上書き
            ENV["INVOICE_FEE_RATE"] = "0.05"
            ENV["INVOICE_TAX_RATE"] = "0.08"

            invoice = Invoice.create!(
              user_id: account.id,
              issue_date: Date.today,
              payment_amount: Money.new(100000),
              payment_due_date: Date.today + 30.days
            )

            # fee = 100000 × 0.05 = 5000
            expect(invoice.fee.value).to eq(BigDecimal("5000.00"))
            # tax_amount = 5000 × 0.08 = 400
            expect(invoice.tax_amount.value).to eq(BigDecimal("400.00"))
            # total_amount = 100000 + 5000 + 400 = 105400
            expect(invoice.total_amount.value).to eq(BigDecimal("105400.00"))
          ensure
            # 環境変数を元の値に復元
            ENV["INVOICE_FEE_RATE"] = original_fee_rate
            ENV["INVOICE_TAX_RATE"] = original_tax_rate
          end
        end

        it "handles rounding correctly" do
          invoice = Invoice.create!(
            user_id: account.id,
            issue_date: Date.today,
            payment_amount: Money.new("100000.33"),
            payment_due_date: Date.today + 30.days
          )

          # fee = 100000.33 × 0.04 = 4000.0132 → 4000.01
          expect(invoice.fee.value).to eq(BigDecimal("4000.01"))
          # tax_amount = 4000.01 × 0.10 = 400.001 → 400.00
          expect(invoice.tax_amount.value).to eq(BigDecimal("400.00"))
          # total_amount = 100000.33 + 4000.01 + 400.00 = 104400.34
          expect(invoice.total_amount.value).to eq(BigDecimal("104400.34"))
        end
      end

      describe ".between_payment_due_dates" do
        before do
          # テストデータ作成
          Invoice.create!(
            user_id: account.id,
            issue_date: Date.today,
            payment_amount: Money.new(100000),
            payment_due_date: Date.new(2025, 1, 15)
          )
          Invoice.create!(
            user_id: account.id,
            issue_date: Date.today,
            payment_amount: Money.new(200000),
            payment_due_date: Date.new(2025, 1, 31)
          )
          Invoice.create!(
            user_id: account.id,
            issue_date: Date.today,
            payment_amount: Money.new(300000),
            payment_due_date: Date.new(2025, 2, 15)
          )
        end

        it "returns invoices within date range" do
          invoices = Invoice.between_payment_due_dates(Date.new(2025, 1, 1), Date.new(2025, 1, 31))
          expect(invoices.count).to eq(2)
        end

        it "includes boundary dates" do
          invoices = Invoice.between_payment_due_dates(Date.new(2025, 1, 15), Date.new(2025, 1, 15))
          expect(invoices.count).to eq(1)
        end

        it "returns empty array when no matches" do
          invoices = Invoice.between_payment_due_dates(Date.new(2025, 3, 1), Date.new(2025, 3, 31))
          expect(invoices.count).to eq(0)
        end
      end
    end
    ```

- [ ] **テスト実行**

  ```bash
  bundle exec rspec app/packages/invoice/spec/models/invoice_spec.rb
  ```

- [ ] **コミット:** `feat(pack-invoice): Invoiceモデルを追加`
- [ ] **コミット:** `test(pack-invoice): Invoiceモデルのユニットテストを追加`

---

### フェーズ5: Controller実装

- [ ] **InvoicesController作成**
  - ファイル: `app/packages/invoice/app/controllers/api/v1/invoices_controller.rb`
  - 内容:

    ```ruby
    # frozen_string_literal: true

    # 請求書管理API
    # 責務: JWT認証、パラメータ受け取り、エラーハンドリング、レスポンス整形
    module Api
      module V1
        class InvoicesController < ApplicationController
          before_action :authenticate_account!

          # POST /api/v1/invoices
          def create
            invoice = Invoice.new(invoice_params.merge(user_id: current_account.id))

            if invoice.save
              render json: invoice_json(invoice), status: :created
            else
              render json: {
                error: {
                  code: "INVOICE_CREATION_FAILED",
                  message: invoice.errors.full_messages.join(", "),
                  trace_id: trace_id
                }
              }, status: :unprocessable_entity
            end
          end

          # GET /api/v1/invoices
          def index
            invoices = Invoice.where(user_id: current_account.id)

            # 支払期限での期間検索
            if params[:start_date] && params[:end_date]
              invoices = invoices.between_payment_due_dates(
                Date.parse(params[:start_date]),
                Date.parse(params[:end_date])
              )
            end

            render json: { invoices: invoices.map { |i| invoice_json(i) } }
          rescue Date::Error
            render json: {
              error: {
                code: "INVALID_DATE_FORMAT",
                message: "Invalid date format. Use YYYY-MM-DD.",
                trace_id: trace_id
              }
            }, status: :bad_request
          end

          private

          def invoice_params
            params.permit(:issue_date, :payment_amount, :payment_due_date)
          end

          def invoice_json(invoice)
            {
              id: invoice.id,
              user_id: invoice.user_id,
              issue_date: invoice.issue_date.to_s,
              payment_amount: invoice.payment_amount.to_s,
              fee: invoice.fee.to_s,
              fee_rate: invoice.fee_rate.to_s,
              tax_amount: invoice.tax_amount.to_s,
              tax_rate: invoice.tax_rate.to_s,
              total_amount: invoice.total_amount.to_s,
              payment_due_date: invoice.payment_due_date.to_s,
              created_at: invoice.created_at.iso8601,
              updated_at: invoice.updated_at.iso8601
            }
          end

          def trace_id
            SemanticLogger.named_tags[:trace_id]
          end
        end
      end
    end
    ```

- [ ] **ApplicationControllerに認証concernを追加**
  - ファイル: `app/controllers/application_controller.rb`
  - 追加内容:
    ```ruby
    class ApplicationController < ActionController::API
      include ErrorHandling
      include Authentication::Authenticatable  # 追加

      attr_reader :current_account  # 追加
    end
    ```

- [ ] **ルーティング追加**
  - ファイル: `config/routes.rb`
  - 追加内容:

    ```ruby
    namespace :api do
      namespace :v1 do
        resources :invoices, only: [:create, :index]
      end
    end
    ```

- [ ] **検証コマンド:**

  ```bash
  # ルート確認
  bin/rails routes | grep invoices
  # => POST /api/v1/invoices api/v1/invoices#create
  # => GET  /api/v1/invoices api/v1/invoices#index

  # Railsが起動できるか確認
  RAILS_ENV=test bin/rails runner "puts 'Rails loaded successfully'"
  ```

- [ ] **コミット:** `feat(pack-invoice): InvoicesControllerを追加`
- [ ] **コミット:** `chore(routes): 請求書APIルーティングを追加`
- [ ] **コミット:** `refactor(app): ApplicationControllerに認証concernを追加`

---

### フェーズ6: リクエストスペック実装

- [ ] **テストディレクトリ作成**
  ```bash
  mkdir -p app/packages/invoice/spec/requests/api/v1
  ```

- [ ] **InvoicesController リクエストスペック**
  - ファイル: `app/packages/invoice/spec/requests/api/v1/invoices_spec.rb`
  - 内容:
    ```ruby
    require "rails_helper"
    require "swagger_helper"

    RSpec.describe "POST /api/v1/invoices", type: :request do
      let(:account) { Account.create!(email: "test@example.com", status: "verified") }
      let(:jwt) { Authentication::JwtService.generate(account) }
      let(:headers) { { "Authorization" => "Bearer #{jwt}" } }

      describe "正常系" do
        it "creates invoice and returns calculated fees" do
          post "/api/v1/invoices", params: {
            issue_date: "2025-01-15",
            payment_amount: "100000",
            payment_due_date: "2025-02-28"
          }, headers: headers

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)

          expect(json["user_id"]).to eq(account.id)
          expect(json["payment_amount"]).to eq("100000.00")
          expect(json["fee"]).to eq("4000.00")
          expect(json["fee_rate"]).to eq("0.0400")
          expect(json["tax_amount"]).to eq("400.00")
          expect(json["tax_rate"]).to eq("0.1000")
          expect(json["total_amount"]).to eq("104400.00")
          expect(json["issue_date"]).to eq("2025-01-15")
          expect(json["payment_due_date"]).to eq("2025-02-28")
        end

        it "calculates fees with custom rates" do
          original_fee_rate = ENV["INVOICE_FEE_RATE"]
          original_tax_rate = ENV["INVOICE_TAX_RATE"]

          begin
            ENV["INVOICE_FEE_RATE"] = "0.05"
            ENV["INVOICE_TAX_RATE"] = "0.08"

            post "/api/v1/invoices", params: {
              issue_date: "2025-01-15",
              payment_amount: "100000",
              payment_due_date: "2025-02-28"
            }, headers: headers

            json = JSON.parse(response.body)
            expect(json["fee"]).to eq("5000.00")
            expect(json["tax_amount"]).to eq("400.00")
            expect(json["total_amount"]).to eq("105400.00")
          ensure
            ENV["INVOICE_FEE_RATE"] = original_fee_rate
            ENV["INVOICE_TAX_RATE"] = original_tax_rate
          end
        end
      end

      describe "異常系" do
        it "returns 401 without JWT" do
          post "/api/v1/invoices", params: {
            issue_date: "2025-01-15",
            payment_amount: "100000",
            payment_due_date: "2025-02-28"
          }

          expect(response).to have_http_status(:unauthorized)
          json = JSON.parse(response.body)
          expect(json["error"]["code"]).to eq("UNAUTHORIZED")
        end

        it "returns 401 with invalid JWT" do
          post "/api/v1/invoices", params: {
            issue_date: "2025-01-15",
            payment_amount: "100000",
            payment_due_date: "2025-02-28"
          }, headers: { "Authorization" => "Bearer invalid_token" }

          expect(response).to have_http_status(:unauthorized)
        end

        it "returns error for missing payment_amount" do
          post "/api/v1/invoices", params: {
            issue_date: "2025-01-15",
            payment_due_date: "2025-02-28"
          }, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json["error"]["code"]).to eq("INVOICE_CREATION_FAILED")
        end

        it "returns error for negative payment_amount" do
          post "/api/v1/invoices", params: {
            issue_date: "2025-01-15",
            payment_amount: "-100",
            payment_due_date: "2025-02-28"
          }, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json["error"]["message"]).to include("must be greater than 0")
        end

        it "returns error when payment_due_date is before issue_date" do
          post "/api/v1/invoices", params: {
            issue_date: "2025-02-28",
            payment_amount: "100000",
            payment_due_date: "2025-01-15"
          }, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json["error"]["message"]).to include("must be on or after issue_date")
        end
      end
    end

    RSpec.describe "GET /api/v1/invoices", type: :request do
      let(:account) { Account.create!(email: "test@example.com", status: "verified") }
      let(:other_account) { Account.create!(email: "other@example.com", status: "verified") }
      let(:jwt) { Authentication::JwtService.generate(account) }
      let(:headers) { { "Authorization" => "Bearer #{jwt}" } }

      before do
        # テストデータ作成
        Invoice.create!(
          user_id: account.id,
          issue_date: Date.today,
          payment_amount: Money.new(100000),
          payment_due_date: Date.new(2025, 1, 15)
        )
        Invoice.create!(
          user_id: account.id,
          issue_date: Date.today,
          payment_amount: Money.new(200000),
          payment_due_date: Date.new(2025, 1, 31)
        )
        # 他ユーザーの請求書
        Invoice.create!(
          user_id: other_account.id,
          issue_date: Date.today,
          payment_amount: Money.new(300000),
          payment_due_date: Date.new(2025, 1, 15)
        )
      end

      describe "正常系" do
        it "returns all invoices for current user" do
          get "/api/v1/invoices", headers: headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["invoices"].count).to eq(2)
          expect(json["invoices"].all? { |i| i["user_id"] == account.id }).to be(true)
        end

        it "filters by payment_due_date range" do
          get "/api/v1/invoices", params: {
            start_date: "2025-01-01",
            end_date: "2025-01-31"
          }, headers: headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["invoices"].count).to eq(2)
        end

        it "returns empty array when no invoices match" do
          get "/api/v1/invoices", params: {
            start_date: "2025-03-01",
            end_date: "2025-03-31"
          }, headers: headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["invoices"]).to eq([])
        end
      end

      describe "異常系" do
        it "returns 401 without JWT" do
          get "/api/v1/invoices"

          expect(response).to have_http_status(:unauthorized)
        end

        it "returns error for invalid date format" do
          get "/api/v1/invoices", params: {
            start_date: "invalid-date",
            end_date: "2025-01-31"
          }, headers: headers

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json["error"]["code"]).to eq("INVALID_DATE_FORMAT")
        end
      end

      describe "アクセス制御" do
        it "does not return other users' invoices" do
          get "/api/v1/invoices", headers: headers

          json = JSON.parse(response.body)
          user_ids = json["invoices"].map { |i| i["user_id"] }.uniq
          expect(user_ids).to eq([account.id])
        end
      end
    end
    ```

- [ ] **テスト実行**

  ```bash
  bundle exec rspec app/packages/invoice/spec/requests/api/v1/invoices_spec.rb
  ```

- [ ] **コミット:** `test(pack-invoice): InvoicesController リクエストスペックを追加`

---

### フェーズ7: RSwag統合

- [ ] **RSwag統合スペック作成**
  - ファイル: `app/packages/invoice/spec/integration/invoices_spec.rb`
  - 内容:

    ```ruby
    # frozen_string_literal: true

    require "swagger_helper"

    # rubocop:disable RSpec/LetSetup
    RSpec.describe "Invoices API", type: :request do
      path "/api/v1/invoices" do
        post "請求書を登録する" do
          tags "Invoices"
          consumes "application/json"
          produces "application/json"
          description "請求書を登録し、手数料・税額を自動計算します"
          security [ bearer: [] ]

          parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer <JWT>"
          parameter name: :invoice, in: :body, schema: {
            type: :object,
            properties: {
              issue_date: {
                type: :string,
                format: :date,
                description: "請求書発行日",
                example: "2025-01-15"
              },
              payment_amount: {
                type: :string,
                description: "支払金額（請求元への支払額）",
                example: "100000"
              },
              payment_due_date: {
                type: :string,
                format: :date,
                description: "支払期限",
                example: "2025-02-28"
              }
            },
            required: %w[issue_date payment_amount payment_due_date]
          }

          response "201", "請求書登録成功" do
            schema type: :object,
                   properties: {
                     id: { type: :integer, example: 1 },
                     user_id: { type: :integer, example: 123 },
                     issue_date: { type: :string, example: "2025-01-15" },
                     payment_amount: { type: :string, example: "100000.00" },
                     fee: { type: :string, example: "4000.00" },
                     fee_rate: { type: :string, example: "0.0400" },
                     tax_amount: { type: :string, example: "400.00" },
                     tax_rate: { type: :string, example: "0.1000" },
                     total_amount: { type: :string, example: "104400.00" },
                     payment_due_date: { type: :string, example: "2025-02-28" },
                     created_at: { type: :string, format: :datetime },
                     updated_at: { type: :string, format: :datetime }
                   },
                   required: %w[id user_id issue_date payment_amount fee fee_rate tax_amount tax_rate total_amount payment_due_date]

            let!(:account) { Account.create!(email: "test@example.com", status: "verified") }
            let(:valid_token) { Authentication::JwtService.generate(account) }
            let(:Authorization) { "Bearer #{valid_token}" }
            let(:invoice) do
              {
                issue_date: "2025-01-15",
                payment_amount: "100000",
                payment_due_date: "2025-02-28"
              }
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data["user_id"]).to eq(account.id)
              expect(data["payment_amount"]).to eq("100000.00")
              expect(data["fee"]).to eq("4000.00")
              expect(data["total_amount"]).to eq("104400.00")
            end
          end

          response "401", "JWT認証失敗" do
            schema "$ref" => "#/components/schemas/ErrorResponse"

            let(:Authorization) { "Bearer invalid_token" }
            let(:invoice) do
              {
                issue_date: "2025-01-15",
                payment_amount: "100000",
                payment_due_date: "2025-02-28"
              }
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data["error"]["code"]).to eq("UNAUTHORIZED")
            end
          end

          response "422", "バリデーションエラー" do
            schema "$ref" => "#/components/schemas/ErrorResponse"

            let!(:account) { Account.create!(email: "test@example.com", status: "verified") }
            let(:valid_token) { Authentication::JwtService.generate(account) }
            let(:Authorization) { "Bearer #{valid_token}" }
            let(:invoice) do
              {
                issue_date: "2025-01-15",
                payment_amount: "-100"  # 負の金額
              }
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data["error"]["code"]).to be_present
            end
          end
        end

        get "請求書一覧を取得する" do
          tags "Invoices"
          produces "application/json"
          description "支払期限での期間検索が可能です"
          security [ bearer: [] ]

          parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer <JWT>"
          parameter name: :start_date, in: :query, type: :string, required: false, description: "支払期限の開始日（YYYY-MM-DD）"
          parameter name: :end_date, in: :query, type: :string, required: false, description: "支払期限の終了日（YYYY-MM-DD）"

          response "200", "請求書一覧取得成功" do
            schema type: :object,
                   properties: {
                     invoices: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           id: { type: :integer },
                           user_id: { type: :integer },
                           issue_date: { type: :string },
                           payment_amount: { type: :string },
                           fee: { type: :string },
                           fee_rate: { type: :string },
                           tax_amount: { type: :string },
                           tax_rate: { type: :string },
                           total_amount: { type: :string },
                           payment_due_date: { type: :string },
                           created_at: { type: :string },
                           updated_at: { type: :string }
                         }
                       }
                     }
                   }

            let!(:account) { Account.create!(email: "test@example.com", status: "verified") }
            let(:valid_token) { Authentication::JwtService.generate(account) }
            let(:Authorization) { "Bearer #{valid_token}" }
            let!(:invoice1) do
              Invoice.create!(
                user_id: account.id,
                issue_date: "2025-01-15",
                payment_amount: Money.new(100000),
                payment_due_date: "2025-02-28"
              )
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data["invoices"]).to be_an(Array)
              expect(data["invoices"].size).to eq(1)
            end
          end

          response "401", "JWT認証失敗" do
            schema "$ref" => "#/components/schemas/ErrorResponse"

            let(:Authorization) { "Bearer invalid_token" }

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data["error"]["code"]).to eq("UNAUTHORIZED")
            end
          end
        end
      end
    end
    # rubocop:enable RSpec/LetSetup
    ```

- [ ] **Swagger YAML生成**

  ```bash
  RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
  ```

- [ ] **検証コマンド:**

  ```bash
  # Swagger UIで確認
  bin/rails s
  # ブラウザで http://localhost:3000/api-docs を開く
  ```

- [ ] **コミット:** `chore(swagger): 請求書API仕様を生成`

---

### フェーズ8: 統合テスト・品質チェック

- [ ] **全テスト実行**
  ```bash
  bundle exec rspec
  ```

- [ ] **RuboCop実行**
  ```bash
  bundle exec rubocop -a app/packages/invoice/
  ```

- [ ] **Packwerkチェック**
  ```bash
  bundle exec packwerk validate
  bundle exec packwerk check app/packages/invoice/
  ```

- [ ] **セキュリティスキャン**
  ```bash
  bundle exec brakeman -q
  bundle exec bundler-audit check --update
  ```

- [ ] **手動テスト（curl）**

  **ユーザー登録 & ログイン（JWT取得）:**
  ```bash
  # ユーザー登録
  curl -X POST http://localhost:3000/api/v1/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"invoice-test@example.com","password":"password123"}'

  # レスポンスからJWTを取得
  JWT="<上記で取得したJWT>"
  ```

  **請求書登録:**
  ```bash
  curl -X POST http://localhost:3000/api/v1/invoices \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JWT" \
    -d '{
      "issue_date": "2025-01-15",
      "payment_amount": "100000",
      "payment_due_date": "2025-02-28"
    }'
  ```

  **請求書一覧取得:**
  ```bash
  curl -X GET http://localhost:3000/api/v1/invoices \
    -H "Authorization: Bearer $JWT"
  ```

  **期間検索:**

  ```bash
  curl -X GET "http://localhost:3000/api/v1/invoices?start_date=2025-01-01&end_date=2025-12-31" \
    -H "Authorization: Bearer $JWT"
  ```

- [ ] **検証項目チェックリスト:**

  - [ ] 全テストがパス（緑色）
  - [ ] RuboCop違反なし
  - [ ] Packwerk依存関係違反なし
  - [ ] Brakemanで重大な脆弱性なし
  - [ ] curlで請求書登録成功
  - [ ] curlで一覧取得成功
  - [ ] 手数料が正しく計算される（100000 → fee 4000, tax 400, total 104400）
  - [ ] JWT未提供時に401エラー
  - [ ] 他ユーザーの請求書が取得できない

- [ ] **コミット（必要に応じて）:** `chore(rubocop): コードスタイルを修正`

---

## テスト観点まとめ

### ユニットテスト（Model）

- [x] Money値オブジェクト: 初期化、演算、比較、ActiveRecord統合
- [x] Rate値オブジェクト: 初期化、比較、to_percent、ActiveRecord統合
- [ ] Invoiceモデル: バリデーション（必須項目、日付順序、正の値）
- [ ] Invoiceモデル: 手数料計算（デフォルト料率、カスタム料率、丸め処理）
- [ ] Invoiceモデル: スコープ（between_payment_due_dates）

### リクエストテスト（API）

- [ ] 登録: 正常系（手数料自動計算）
- [ ] 登録: カスタム料率での計算
- [ ] 登録: JWT未提供エラー
- [ ] 登録: 無効なJWTエラー
- [ ] 登録: payment_amount未入力エラー
- [ ] 登録: payment_amount負の値エラー
- [ ] 登録: payment_due_date が issue_date より前エラー
- [ ] 一覧: 全件取得
- [ ] 一覧: 期間検索
- [ ] 一覧: 空配列（該当なし）
- [ ] 一覧: JWT未提供エラー
- [ ] 一覧: アクセス制御（他ユーザーの請求書が含まれない）

### セキュリティテスト

- [ ] JWT認証が全APIで機能
- [ ] user_id をパラメータで偽装できない
- [ ] 他ユーザーの請求書にアクセスできない
- [ ] SQLインジェクション対策

---

## 想定リードタイム

| フェーズ | 想定時間 | 備考 |
|---------|---------|------|
| フェーズ1: 基盤準備 | 30分 | ディレクトリ作成、package.yml、環境変数 |
| フェーズ2: 値オブジェクト実装 | 3〜4時間 | Money, Rate実装とテスト |
| フェーズ3: マイグレーション | 30分 | テーブル作成 |
| フェーズ4: Invoiceモデル実装 | 3〜4時間 | モデル実装とユニットテスト |
| フェーズ5: Controller実装 | 2〜3時間 | Controller実装とルーティング |
| フェーズ6: リクエストスペック | 3〜4時間 | API統合テスト |
| フェーズ7: RSwag統合 | 1時間 | OpenAPI仕様生成 |
| フェーズ8: 品質チェック | 1〜2時間 | RuboCop, Packwerk, 手動テスト |
| **合計** | **14〜19時間** | 約2〜3日 |

---

## 実装完了後の引き継ぎ事項

### 次のステップ（将来対応）
1. 請求書詳細取得API（`GET /api/v1/invoices/:id`）
2. 請求書更新・削除API
3. ステータス管理（未払い・支払済み等）
4. PDF生成・アップロード機能（ActiveStorage統合）
5. 支払い実行機能（`payment` パッケージ）との連携
6. ページネーション（kaminari/pagy）
7. 複合検索（金額範囲、発行日範囲等）

### ドキュメント更新
- [ ] `README.md` に請求書管理機能の説明を追加
- [ ] `CLAUDE.md` に環境変数セクション追加（`INVOICE_FEE_RATE`, `INVOICE_TAX_RATE`）

### 他パッケージへの影響
- `authentication` パッケージ: `Authenticatable` concernを `ApplicationController` に追加（フェーズ5で実施）
- 将来の `payment` パッケージ: `invoice` パッケージへの依存が必要

---

**実装者へ:** 不明点があれば `specs/invoice-management/` 配下のドキュメントを参照してください。設計判断の背景は `design.md`、要件の詳細は `requirements.md` に記載されています。

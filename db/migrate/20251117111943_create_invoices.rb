# frozen_string_literal: true

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

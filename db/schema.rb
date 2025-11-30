# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_11_17_111943) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_password_hashes", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "password_hash", null: false
    t.index ["account_id"], name: "index_account_password_hashes_on_account_id", unique: true
  end

  create_table "accounts", force: :cascade do |t|
    t.string "email", null: false
    t.string "status", default: "verified", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "issue_date", null: false
    t.decimal "payment_amount", precision: 15, scale: 2, null: false
    t.decimal "fee", precision: 15, scale: 2, null: false
    t.decimal "fee_rate", precision: 5, scale: 4, null: false
    t.decimal "tax_amount", precision: 15, scale: 2, null: false
    t.decimal "tax_rate", precision: 5, scale: 4, null: false
    t.decimal "total_amount", precision: 15, scale: 2, null: false
    t.date "payment_due_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_due_date"], name: "index_invoices_on_payment_due_date"
    t.index ["user_id"], name: "index_invoices_on_user_id"
    t.check_constraint "payment_amount > 0::numeric", name: "invoices_payment_amount_positive"
  end

  add_foreign_key "account_password_hashes", "accounts", on_delete: :cascade
  add_foreign_key "invoices", "accounts", column: "user_id", on_delete: :cascade
end

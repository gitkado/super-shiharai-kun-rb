# frozen_string_literal: true

class CreateAuthenticationTables < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :email, null: false
      t.string :status, null: false, default: "verified"
      t.timestamps
    end
    add_index :accounts, :email, unique: true

    create_table :account_password_hashes do |t|
      t.bigint :account_id, null: false
      t.string :password_hash, null: false
    end
    add_index :account_password_hashes, :account_id, unique: true
    add_foreign_key :account_password_hashes, :accounts, on_delete: :cascade
  end
end

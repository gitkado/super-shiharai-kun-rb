# frozen_string_literal: true

class RodauthApp < Rodauth::Rails::App
  configure do
    enable :login, :create_account, :jwt

    # Use ActiveRecord connection via sequel-activerecord_connection
    db ::Sequel::DATABASES.first || ::Sequel.connect("mock://postgres")

    jwt_secret ENV.fetch("JWT_SECRET_KEY")

    # Set table configuration (tables will be created in migration phase)
    accounts_table :accounts
    account_password_hash_column :password_hash
    account_status_column :status

    skip_status_checks? true  # メール確認スキップ
  end
end

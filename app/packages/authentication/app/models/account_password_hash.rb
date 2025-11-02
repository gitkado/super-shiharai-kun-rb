# frozen_string_literal: true

# Rodauth用のパスワードハッシュモデル
# 責務: アカウントのパスワードハッシュを管理（Rodauthが使用）
class AccountPasswordHash < ApplicationRecord
  belongs_to :account
end

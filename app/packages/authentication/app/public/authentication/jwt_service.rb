# frozen_string_literal: true

# JWT生成・検証サービス（公開API）
# 責務: 他パッケージから利用可能なJWT操作インターフェース
# 実装: JWT gemを直接使用
module Authentication
  module JwtService
    class << self
      # JWT生成
      # @param account [Account] JWTを発行するアカウント
      # @param expires_in [Integer] 有効期限（秒）デフォルト: 1時間
      # @return [String] JWT文字列
      def generate(account, expires_in: 3600)
        payload = {
          account_id: account.id,
          email: account.email,
          exp: Time.current.to_i + expires_in
        }

        JWT.encode(payload, jwt_secret, "HS256")
      end

      # JWTデコード
      # @param token [String] JWT文字列
      # @return [Hash, nil] ペイロード（失敗時はnil）
      def decode(token)
        decoded = JWT.decode(token, jwt_secret, true, algorithm: "HS256")
        decoded.first
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end

      private

      # JWT秘密鍵を取得
      def jwt_secret
        AppConfig.jwt_secret
      end
    end
  end
end

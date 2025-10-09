# frozen_string_literal: true

# RuboCop-Packsの設定とPacksモジュールの拡張

# packs gemに for_file メソッドを追加して rubocop-packs との互換性を確保
module Packs
  class << self
    def for_file(relative_path)
      ParsePackwerk.package_from_path(relative_path)
    end

    def all
      ParsePackwerk.all
    end
  end
end

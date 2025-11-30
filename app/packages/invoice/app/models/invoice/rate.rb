# frozen_string_literal: true

require "bigdecimal"

# 料率（割合）を表す値オブジェクト
# 責務: BigDecimalによる精度保証（小数点4桁）、ActiveRecord統合
# 名前空間: Invoice::Rate（他gemとの衝突を防ぐため）
class Invoice::Rate
  include Comparable

  attr_reader :value

  def initialize(value)
    @value = BigDecimal(value.to_s).round(4)
  end

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
      when Invoice::Rate
        value
      when Numeric, String
        Invoice::Rate.new(value)
      else
        nil
      end
    end

    def serialize(value)
      value&.value
    end

    def deserialize(value)
      value ? Invoice::Rate.new(value) : nil
    end
  end
end

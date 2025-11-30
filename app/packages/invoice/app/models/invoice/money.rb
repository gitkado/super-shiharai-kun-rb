# frozen_string_literal: true

require "bigdecimal"

# 金額を表す値オブジェクト
# 責務: BigDecimalによる精度保証、演算メソッド提供、ActiveRecord統合
# 名前空間: Invoice::Money（他gemとの衝突を防ぐため）
class Invoice::Money
  include Comparable

  attr_reader :value

  def initialize(value)
    @value = BigDecimal(value.to_s).round(2)
  end

  def +(other)
    Invoice::Money.new(@value + other.value)
  end

  def -(other)
    Invoice::Money.new(@value - other.value)
  end

  def *(rate)
    case rate
    when Invoice::Rate
      Invoice::Money.new(@value * rate.value)
    when Numeric
      Invoice::Money.new(@value * rate)
    else
      raise ArgumentError, "Cannot multiply Money by #{rate.class}"
    end
  end

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
      when Invoice::Money
        value
      when Numeric, String
        Invoice::Money.new(value)
      else
        nil
      end
    end

    def serialize(value)
      value&.value
    end

    def deserialize(value)
      value ? Invoice::Money.new(value) : nil
    end
  end
end

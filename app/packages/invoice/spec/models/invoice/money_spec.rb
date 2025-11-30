# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invoice::Money, type: :model do
  describe "#initialize" do
    it "整数からMoneyを生成すること" do
      money = described_class.new(100)
      expect(money.value).to eq(BigDecimal("100.00"))
    end

    it "文字列からMoneyを生成すること" do
      money = described_class.new("100.50")
      expect(money.value).to eq(BigDecimal("100.50"))
    end

    it "小数点以下2桁に丸めること" do
      money = described_class.new("100.999")
      expect(money.value).to eq(BigDecimal("101.00"))
    end
  end

  describe "算術演算" do
    let(:money1) { described_class.new(100) }
    let(:money2) { described_class.new(50) }

    it "2つのMoneyオブジェクトを加算すること" do
      result = money1 + money2
      expect(result.value).to eq(BigDecimal("150.00"))
    end

    it "2つのMoneyオブジェクトを減算すること" do
      result = money1 - money2
      expect(result.value).to eq(BigDecimal("50.00"))
    end

    it "MoneyをRateで乗算すること" do
      rate = Invoice::Rate.new(0.04)
      result = money1 * rate
      expect(result.value).to eq(BigDecimal("4.00"))
    end

    it "MoneyをNumericで乗算すること" do
      result = money1 * 2
      expect(result.value).to eq(BigDecimal("200.00"))
    end
  end

  describe "比較" do
    it "Moneyオブジェクトを比較すること" do
      expect(described_class.new(100)).to be > described_class.new(50)
      expect(described_class.new(50)).to be < described_class.new(100)
      expect(described_class.new(100)).to eq(described_class.new(100))
    end
  end

  describe "#to_s" do
    it "小数点以下2桁の文字列表現を返すこと" do
      money = described_class.new("100.50")
      expect(money.to_s).to eq("100.50")
    end

    it "末尾のゼロを含む文字列を返すこと" do
      money = described_class.new("100")
      expect(money.to_s).to eq("100.00")
    end
  end

  describe "ActiveRecord Type" do
    it "文字列をMoneyにキャストすること" do
      type = Invoice::Money::Type.new
      result = type.cast("100.50")
      expect(result).to be_a(described_class)
      expect(result.value).to eq(BigDecimal("100.50"))
    end

    it "MoneyをBigDecimalにシリアライズすること" do
      type = Invoice::Money::Type.new
      money = described_class.new(100)
      result = type.serialize(money)
      expect(result).to eq(BigDecimal("100.00"))
    end

    it "BigDecimalをMoneyにデシリアライズすること" do
      type = Invoice::Money::Type.new
      result = type.deserialize(BigDecimal("100.50"))
      expect(result).to be_a(described_class)
      expect(result.value).to eq(BigDecimal("100.50"))
    end
  end
end

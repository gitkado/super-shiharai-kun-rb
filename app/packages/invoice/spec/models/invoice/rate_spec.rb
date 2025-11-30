# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invoice::Rate, type: :model do
  describe "#initialize" do
    it "浮動小数点数からRateを生成すること" do
      rate = described_class.new(0.04)
      expect(rate.value).to eq(BigDecimal("0.0400"))
    end

    it "文字列からRateを生成すること" do
      rate = described_class.new("0.1234")
      expect(rate.value).to eq(BigDecimal("0.1234"))
    end

    it "小数点以下4桁に丸めること" do
      rate = described_class.new("0.12345")
      expect(rate.value).to eq(BigDecimal("0.1235"))
    end
  end

  describe "比較" do
    it "Rateオブジェクトを比較すること" do
      expect(described_class.new(0.1)).to be > described_class.new(0.05)
      expect(described_class.new(0.05)).to be < described_class.new(0.1)
      expect(described_class.new(0.1)).to eq(described_class.new(0.1))
    end
  end

  describe "#to_s" do
    it "小数点以下4桁の文字列表現を返すこと" do
      rate = described_class.new(0.04)
      expect(rate.to_s).to eq("0.0400")
    end

    it "末尾のゼロを含む文字列を返すこと" do
      rate = described_class.new(0.1)
      expect(rate.to_s).to eq("0.1000")
    end
  end

  describe "#to_percent" do
    it "小数点以下2桁のパーセント表現を返すこと" do
      rate = described_class.new(0.04)
      expect(rate.to_percent).to eq("4.00")
    end

    it "末尾のゼロを含むパーセント表現を返すこと" do
      rate = described_class.new(0.1)
      expect(rate.to_percent).to eq("10.00")
    end
  end

  describe "ActiveRecord Type" do
    it "文字列をRateにキャストすること" do
      type = Invoice::Rate::Type.new
      result = type.cast("0.04")
      expect(result).to be_a(described_class)
      expect(result.value).to eq(BigDecimal("0.0400"))
    end

    it "RateをBigDecimalにシリアライズすること" do
      type = Invoice::Rate::Type.new
      rate = described_class.new(0.04)
      result = type.serialize(rate)
      expect(result).to eq(BigDecimal("0.0400"))
    end

    it "BigDecimalをRateにデシリアライズすること" do
      type = Invoice::Rate::Type.new
      result = type.deserialize(BigDecimal("0.1000"))
      expect(result).to be_a(described_class)
      expect(result.value).to eq(BigDecimal("0.1000"))
    end
  end
end

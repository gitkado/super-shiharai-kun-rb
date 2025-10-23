# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/NestedGroups
RSpec.describe Account, type: :model do
  describe "validations" do
    subject { described_class.new(email: "test@example.com") }

    describe "email" do
      it "requires email to be present" do
        account = described_class.new(email: nil)
        expect(account).not_to be_valid
        expect(account.errors[:email]).to include("can't be blank")
      end

      context "with valid email formats" do
        it "accepts valid email addresses" do
          valid_emails = [
            "user@example.com",
            "user.name@example.co.jp",
            "user+tag@example.com",
            "user_name@example.com",
            "123@example.com"
          ]

          valid_emails.each do |email|
            account = described_class.new(email: email)
            expect(account).to be_valid, "Expected #{email} to be valid, but got errors: #{account.errors.full_messages}"
          end
        end
      end

      context "with invalid email formats" do
        it "rejects invalid email addresses" do
          invalid_emails = [
            "invalid",
            "@example.com",
            "user@",
            "user @example.com",
            ""
          ]

          invalid_emails.each do |email|
            account = described_class.new(email: email)
            expect(account).not_to be_valid, "Expected #{email.inspect} to be invalid"
            expect(account.errors[:email]).to be_present
          end
        end
      end

      context "with uniqueness validation" do
        it "prevents duplicate emails (case-insensitive)" do
          described_class.create!(email: "user@example.com")
          duplicate = described_class.new(email: "USER@EXAMPLE.COM")

          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:email]).to include("has already been taken")
        end

        it "allows different emails" do
          described_class.create!(email: "user1@example.com")
          different = described_class.new(email: "user2@example.com")

          expect(different).to be_valid
        end
      end
    end
  end

  describe "#normalize_email" do
    it "converts email to lowercase before validation" do
      account = described_class.create!(email: "USER@EXAMPLE.COM")
      expect(account.email).to eq("user@example.com")
    end

    it "strips leading and trailing whitespace" do
      account = described_class.create!(email: "  user@example.com  ")
      expect(account.email).to eq("user@example.com")
    end

    it "handles both uppercase and whitespace together" do
      account = described_class.create!(email: "  USER@EXAMPLE.COM  ")
      expect(account.email).to eq("user@example.com")
    end

    it "handles nil email gracefully" do
      account = described_class.new(email: nil)
      expect { account.valid? }.not_to raise_error
      expect(account.email).to be_nil
    end

    it "handles empty string email" do
      account = described_class.new(email: "")
      expect { account.valid? }.not_to raise_error
      expect(account.email).to eq("")
    end
  end

  describe "status enum" do
    let(:account) { described_class.create!(email: "user@example.com") }

    it "has default status of 'verified'" do
      new_account = described_class.create!(email: "new@example.com")
      expect(new_account.status).to eq("verified")
      expect(new_account.status_verified?).to be(true)
    end

    it "can be set to unverified" do
      account.status_unverified!
      expect(account.status).to eq("unverified")
      expect(account.status_unverified?).to be(true)
    end

    it "can be set to locked" do
      account.status_locked!
      expect(account.status).to eq("locked")
      expect(account.status_locked?).to be(true)
    end

    it "can be set to closed" do
      account.status_closed!
      expect(account.status).to eq("closed")
      expect(account.status_closed?).to be(true)
    end

    it "provides scope methods for each status" do
      verified = described_class.create!(email: "verified@example.com", status: "verified")
      locked = described_class.create!(email: "locked@example.com", status: "locked")
      unverified = described_class.create!(email: "unverified@example.com", status: "unverified")

      expect(described_class.status_verified).to include(verified)
      expect(described_class.status_locked).to include(locked)
      expect(described_class.status_unverified).to include(unverified)
    end

    it "uses string values for Rodauth compatibility" do
      account.status = "locked"
      account.save!

      # データベースに文字列として保存されることを確認
      reloaded = described_class.find(account.id)
      expect(reloaded.read_attribute(:status)).to eq("locked")
      expect(reloaded.status).to eq("locked")
    end
  end

  describe "database constraints" do
    it "has timestamps" do
      account = described_class.create!(email: "user@example.com")
      expect(account.created_at).to be_present
      expect(account.updated_at).to be_present
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/NestedGroups

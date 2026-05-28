# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompareImage, type: :model do
  describe ".find_or_create_for_share" do
    let!(:carrack) { create_model_with_slug("anvil-carrack") }
    let!(:cutlass) { create_model_with_slug("drake-cutlass-black") }

    def create_model_with_slug(slug, legacy_slug: nil)
      model = create(:model)
      model.update_columns(slug: slug, legacy_slug: legacy_slug)
      model
    end

    it "creates a record with share_key, short_code, and slug_set" do
      record = described_class.find_or_create_for_share([carrack.slug, cutlass.slug])

      expect(record).to be_persisted
      expect(record.share_key).to eq("anvil-carrack,drake-cutlass-black")
      expect(record.short_code).to match(/\A[A-Za-z0-9]{8}\z/)
      expect(record.slug_set).to eq("anvil-carrack,drake-cutlass-black")
    end

    it "is idempotent for the same slugs in any order" do
      first = described_class.find_or_create_for_share([carrack.slug, cutlass.slug])
      second = described_class.find_or_create_for_share([cutlass.slug, carrack.slug])

      expect(first.id).to eq(second.id)
      expect(first.short_code).to eq(second.short_code)
    end

    it "resolves legacy slugs to canonical slugs" do
      carrack.update_columns(legacy_slug: "anvil-aerospace-carrack")
      record = described_class.find_or_create_for_share(["anvil-aerospace-carrack", cutlass.slug])

      expect(record.share_key).to eq("anvil-carrack,drake-cutlass-black")
    end

    it "returns nil for an empty slug list" do
      expect(described_class.find_or_create_for_share([])).to be_nil
    end

    it "returns nil when no slug matches a known model" do
      expect(described_class.find_or_create_for_share(["unknown-slug"])).to be_nil
    end

    it "returns nil when more than MAX_SHARE_MODELS slugs are supplied" do
      slugs = (1..(CompareImage::MAX_SHARE_MODELS + 1)).map do |i|
        create_model_with_slug("extra-#{i}").slug
      end

      expect(described_class.find_or_create_for_share(slugs)).to be_nil
    end

    it "upgrades an existing OG-only row by adding share_key and short_code" do
      og_row = described_class.create!(slug_set: "v2-anvil-carrack-drake-cutlass-black")

      record = described_class.find_or_create_for_share([carrack.slug, cutlass.slug])

      expect(record.id).to eq(og_row.id)
      expect(record.reload.share_key).to eq("anvil-carrack,drake-cutlass-black")
      expect(record.short_code).to match(/\A[A-Za-z0-9]{8}\z/)
    end

    it "retries the short_code generator on collision" do
      taken = "AAAAAAAA"
      described_class.create!(slug_set: "decoy", share_key: "decoy", short_code: taken)
      attempts = [taken, "BBBBBBBB"]
      allow(SecureRandom).to receive(:alphanumeric).with(CompareImage::SHORT_CODE_LENGTH) { attempts.shift }

      record = described_class.find_or_create_for_share([carrack.slug, cutlass.slug])

      expect(record.short_code).to eq("BBBBBBBB")
    end
  end
end

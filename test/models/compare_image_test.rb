# frozen_string_literal: true

# == Schema Information
#
# Table name: compare_images
#
#  id         :uuid             not null, primary key
#  share_key  :string
#  short_code :string
#  slug_set   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_compare_images_on_share_key   (share_key) UNIQUE WHERE (share_key IS NOT NULL)
#  index_compare_images_on_short_code  (short_code) UNIQUE WHERE (short_code IS NOT NULL)
#  index_compare_images_on_slug_set    (slug_set) UNIQUE
#
require "test_helper"

class CompareImageTest < ActiveSupport::TestCase
  setup do
    @carrack = create_model_with_slug("anvil-carrack")
    @cutlass = create_model_with_slug("drake-cutlass-black")
  end

  test "creates a record with share_key, short_code, and slug_set" do
    record = CompareImage.find_or_create_for_share([@carrack.slug, @cutlass.slug])

    assert record.persisted?
    assert_equal "anvil-carrack,drake-cutlass-black", record.share_key
    assert_match(/\A[A-Za-z0-9]{8}\z/, record.short_code)
    assert_equal "anvil-carrack,drake-cutlass-black", record.slug_set
  end

  test "is idempotent for the same slugs in any order" do
    first = CompareImage.find_or_create_for_share([@carrack.slug, @cutlass.slug])
    second = CompareImage.find_or_create_for_share([@cutlass.slug, @carrack.slug])

    assert_equal first.id, second.id
    assert_equal first.short_code, second.short_code
  end

  test "resolves legacy slugs to canonical slugs" do
    @carrack.update_columns(legacy_slug: "anvil-aerospace-carrack")
    record = CompareImage.find_or_create_for_share(["anvil-aerospace-carrack", @cutlass.slug])

    assert_equal "anvil-carrack,drake-cutlass-black", record.share_key
  end

  test "returns nil for an empty slug list" do
    assert_nil CompareImage.find_or_create_for_share([])
  end

  test "returns nil when no slug matches a known model" do
    assert_nil CompareImage.find_or_create_for_share(["unknown-slug"])
  end

  test "returns nil when more than MAX_SHARE_MODELS slugs are supplied" do
    slugs = (1..(CompareImage::MAX_SHARE_MODELS + 1)).map { |i| create_model_with_slug("extra-#{i}").slug }

    assert_nil CompareImage.find_or_create_for_share(slugs)
  end

  test "upgrades an existing OG-only row by adding share_key and short_code" do
    og_row = CompareImage.create!(slug_set: "v2-anvil-carrack-drake-cutlass-black")

    record = CompareImage.find_or_create_for_share([@carrack.slug, @cutlass.slug])

    assert_equal og_row.id, record.id
    assert_equal "anvil-carrack,drake-cutlass-black", record.reload.share_key
    assert_match(/\A[A-Za-z0-9]{8}\z/, record.short_code)
  end

  test "retries the short_code generator on collision" do
    taken = "AAAAAAAA"
    CompareImage.create!(slug_set: "decoy", share_key: "decoy", short_code: taken)
    attempts = [taken, "BBBBBBBB"]
    SecureRandom.stubs(:alphanumeric).with(CompareImage::SHORT_CODE_LENGTH).returns(*attempts)

    record = CompareImage.find_or_create_for_share([@carrack.slug, @cutlass.slug])

    assert_equal "BBBBBBBB", record.short_code
  end

  private

  def create_model_with_slug(slug, legacy_slug: nil)
    model = create(:model)
    model.update_columns(slug: slug, legacy_slug: legacy_slug)
    model
  end
end

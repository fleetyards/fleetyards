# frozen_string_literal: true

require "test_helper"

class ValidationErrorTest < ActiveSupport::TestCase
  test "renders attribute names in camelCase so clients can map them to their fields" do
    item_price = build(:item_price, location_url: "javascript:alert(1)")
    item_price.validate

    payload = ValidationError.new("item_price.create", message: "nope", errors: item_price.errors).as_json

    assert_equal ["locationUrl"], payload[:errors].map { |field_error| field_error[:attribute] }
  end

  test "leaves single word attributes untouched" do
    item_price = build(:item_price)
    item_price.errors.add(:base, :invalid)

    payload = ValidationError.new("item_price.create", message: "nope", errors: item_price.errors).as_json

    assert_equal ["base"], payload[:errors].map { |field_error| field_error[:attribute] }
  end

  test "omits errors when there are none" do
    payload = ValidationError.new("item_price.create", message: "nope").as_json

    assert_equal %i[code message], payload.keys
  end

  # Every code falls back to `I18n.t("validation_error.#{code}")`, and a missing
  # key does not fail loudly: production renders the literal
  # "translation missing: ..." string into the payload, and only development
  # raises. 71 of 138 codes had no translation at all before this was checked.
  CODES = Dir[Rails.root.join("app/**/*.rb")]
    .flat_map { |file| File.read(file).scan(/ValidationError\.new\("([a-z0-9_.]+)"/) }
    .flatten
    .uniq
    .sort
    .freeze

  test "every code in the app is a code we can scan for" do
    # A regexp that silently matches nothing would make the check below vacuous.
    assert_operator CODES.size, :>, 100
    assert_includes CODES, "vehicle.bulk_create"
  end

  I18n.available_locales.each do |locale|
    test "every validation error code is translated in #{locale}" do
      # `fallback: false` is what makes this check mean anything: with
      # `config.i18n.fallbacks = [:en]` a plain lookup returns the English
      # string for every locale, and `I18n.exists?` walks the fallbacks too --
      # both report a translation that is not there.
      untranslated = CODES.reject do |code|
        I18n.t(:"validation_error.#{code}", locale:, default: nil, fallback: false)
      end

      assert_empty untranslated,
        "#{untranslated.size} of #{CODES.size} codes have no #{locale} translation: #{untranslated.join(", ")}"
    end
  end
end

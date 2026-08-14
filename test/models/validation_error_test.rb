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
end

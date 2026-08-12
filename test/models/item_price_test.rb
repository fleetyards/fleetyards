# frozen_string_literal: true

require "test_helper"

class ItemPriceTest < ActiveSupport::TestCase
  test "accepts a web location url" do
    assert build(:item_price, location_url: "https://example.test/shop").valid?
    assert build(:item_price, location_url: "http://example.test/shop").valid?
  end

  test "accepts no location url at all" do
    assert build(:item_price, location_url: nil).valid?
    assert build(:item_price, location_url: "").valid?
  end

  # The url is rendered as an href, so a scheme that executes rather than
  # navigates must not reach the database.
  test "rejects a location url that is not a web link" do
    ["javascript:alert(1)", "JaVaScript:alert(1)", "data:text/html,<script>", "example.test"].each do |url|
      item_price = build(:item_price, location_url: url)

      assert_not item_price.valid?, "#{url} should be rejected"
      assert_includes item_price.errors.attribute_names, :location_url
    end
  end
end

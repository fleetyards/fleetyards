# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: item_prices
#
#  id           :uuid             not null, primary key
#  item_type    :string           not null
#  location     :string
#  location_url :string
#  price        :decimal(15, 2)
#  price_type   :integer
#  time_range   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  item_id      :uuid             not null
#
# Indexes
#
#  index_item_prices_on_item  (item_type,item_id)
#
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

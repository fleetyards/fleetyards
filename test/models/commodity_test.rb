# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: commodities
#
#  id             :uuid             not null, primary key
#  commodity_type :string
#  description    :text
#  icon           :string
#  name           :string           not null
#  sc_key         :string
#  sc_ref         :string
#  slug           :string           not null
#  uex_code       :string
#  version        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  uex_id         :integer
#
# Indexes
#
#  index_commodities_on_commodity_type  (commodity_type)
#  index_commodities_on_sc_key          (sc_key) UNIQUE
#  index_commodities_on_slug            (slug) UNIQUE
#  index_commodities_on_uex_code        (uex_code)
#
class CommodityTest < ActiveSupport::TestCase
  test "generates a slug from the name" do
    commodity = create(:commodity, name: "Agricium (Ore)")

    assert_equal "agricium-ore", commodity.slug
  end

  test "requires a name" do
    commodity = build(:commodity, name: nil)

    assert_not commodity.valid?
    assert_includes commodity.errors.attribute_names, :name
  end

  test "rejects a duplicate sc_key" do
    create(:commodity, sc_key: "items_commodities_gold")
    duplicate = build(:commodity, sc_key: "items_commodities_gold")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :sc_key
  end

  test "allows commodities without an sc_key" do
    commodity = build(:commodity, sc_key: nil)

    assert_predicate commodity, :valid?
  end

  test "can be referenced by a fleet inventory item" do
    commodity = create(:commodity, name: "Gold")
    item = create(:fleet_inventory_item, item: commodity, name: nil)

    assert_equal "Gold", item.name
    assert_equal commodity, item.item
    assert_includes commodity.fleet_inventory_items, item
  end
end

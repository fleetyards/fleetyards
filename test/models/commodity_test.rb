# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: commodities
#
#  id             :uuid             not null, primary key
#  commodity_type :string
#  description    :text
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

  test "can be referenced by an inventory ledger entry" do
    commodity = create(:commodity, name: "Gold")
    item = create(:fleet_inventory_item, item: commodity, name: nil, category: :commodity, unit: :scu)

    assert_equal "Gold", item.name
    assert_equal commodity, item.item
  end

  test "lists the types present in the table" do
    create(:commodity, commodity_type: "metal")
    create(:commodity, commodity_type: "metal")
    create(:commodity, commodity_type: "gas")
    create(:commodity, commodity_type: nil)

    assert_equal %w[gas metal], Commodity.commodity_types
  end

  # A type nothing in the current build carries is a filter that returns
  # nothing, so the options follow the same scope the list does.
  test "leaves a type only past builds carry out of the filter options" do
    create(:commodity, commodity_type: "metal")
    create(:commodity, commodity_type: "vice", version: "0.0.1-live.1")

    assert_equal %w[metal], Commodity.commodity_types
  end

  test "narrows to the build the game currently ships" do
    current = create(:commodity)
    dropped = create(:commodity, version: "0.0.1-live.1")

    assert_includes Commodity.current_version, current
    assert_not_includes Commodity.current_version, dropped
    assert_includes Commodity.current_version(false), dropped
  end

  # ItemPriceConcern, exercised here because a commodity is priced at every
  # terminal that trades it and so has the most rows of the three catalogues.
  test "reports the cheapest price of each direction" do
    commodity = create(:commodity)
    create(:item_price, item: commodity, price_type: :buy, price: 30)
    create(:item_price, item: commodity, price_type: :buy, price: 12)
    create(:item_price, item: commodity, price_type: :sell, price: 44)

    assert_equal 12, commodity.buy_price
    assert_equal 44, commodity.sell_price
  end

  test "has no price for a direction nothing quotes" do
    commodity = create(:commodity)
    create(:item_price, item: commodity, price_type: :sell, price: 44)

    assert_nil commodity.buy_price
    assert_equal 44, commodity.sell_price
  end

  test "filters on the same cheapest price it reports" do
    cheap = create(:commodity, name: "Scrap")
    create(:item_price, item: cheap, price_type: :buy, price: 5)
    create(:item_price, item: cheap, price_type: :buy, price: 90)
    dear = create(:commodity, name: "Quantanium")
    create(:item_price, item: dear, price_type: :buy, price: 88)

    # Scrap is held out by its cheapest row, not admitted by its dearest.
    assert_equal ["Quantanium"], Commodity.ransack(buy_price_gteq: "50").result.map(&:name)
    assert_equal ["Scrap"], Commodity.ransack(buy_price_lteq: "50").result.map(&:name)
  end

  # A joined filter would return the commodity once per matching price row.
  test "returns a commodity once however many of its prices match" do
    commodity = create(:commodity)
    create_list(:item_price, 3, item: commodity, price_type: :sell, price: 60)

    assert_equal 1, Commodity.ransack(sell_price_gteq: "10").result.count
  end

  test "keys the cached payload on the prices as well as the commodity" do
    commodity = create(:commodity)
    price = create(:item_price, item: commodity, price_type: :buy, price: 10)
    before = commodity.reload.item_prices_cache_key

    price.update!(price: 20)

    assert_not_equal before, commodity.reload.item_prices_cache_key
  end

  test "keys the cached payload on the price count, so a removal shows" do
    commodity = create(:commodity)
    create(:item_price, item: commodity, price_type: :buy, price: 10)
    price = create(:item_price, item: commodity, price_type: :buy, price: 20)
    before = commodity.reload.item_prices_cache_key

    price.destroy!

    assert_not_equal before, commodity.reload.item_prices_cache_key
  end

  test "destroys its prices with it" do
    commodity = create(:commodity)
    create(:item_price, item: commodity, price_type: :buy, price: 10)

    assert_difference -> { ItemPrice.count }, -1 do
      commodity.destroy!
    end
  end

  # Every test below makes the build **disagree** with the column. While both are
  # written they are identical, so a passing test would prove nothing about which
  # side answered.
  test "a commodity in the current build reads that build, and is not retired" do
    commodity = create(:commodity, name: "Column Name", commodity_type: "metal")
    commodity.build.update!(name: "Build Name", commodity_type: "gas")

    assert_not commodity.reload.retired?
    assert_equal "Build Name", commodity.name
    assert_equal "gas", commodity.commodity_type
  end

  # A dropped commodity still has to resolve to something: an inventory item can
  # point at one, and a hard delegation would leave it nameless.
  test "a retired commodity reads the last build that described it, and is marked" do
    commodity = create(:commodity, :without_build, name: "Column Name")
    create(:commodity_build, commodity:, version: "0.0.1-live.1", name: "Old Build Name")

    assert_predicate commodity.reload, :retired?
    assert_equal "Old Build Name", commodity.name
  end

  test "the current build wins over an earlier one" do
    commodity = create(:commodity, name: "Column Name")
    create(:commodity_build, commodity:, version: "0.0.1-live.1", name: "Old Build Name")
    commodity.build.update!(name: "Current Build Name")

    assert_equal "Current Build Name", commodity.reload.name
  end

  # The UEX importer creates commodities the export has never named, and an admin
  # can create one by hand. Neither has a build, and both have to read.
  test "a commodity with no build at all falls back to its own columns" do
    commodity = create(:commodity, :without_build, name: "Column Name", commodity_type: "metal", version: nil)

    assert_nil commodity.build
    assert_equal "Column Name", commodity.name
    assert_equal "metal", commodity.commodity_type
  end

  test "#update_with_facts writes the correction to the build as well" do
    commodity = create(:commodity, name: "Wrong Name")

    assert commodity.update_with_facts(name: "Corrected Name", commodity_type: "gas")

    assert_equal "Corrected Name", commodity.build.reload.name
    assert_equal "gas", commodity.build.commodity_type
    assert_equal "Corrected Name", commodity.reload.name
  end

  test "#update_with_facts leaves a retired commodity's build alone" do
    commodity = create(:commodity, :without_build, name: "Wrong Name")
    old = create(:commodity_build, commodity:, version: "0.0.1-live.1", name: "Old Build Name")

    assert commodity.update_with_facts(name: "Corrected Name")

    assert_equal "Old Build Name", old.reload.name
  end

  test "filters on the name the build carries, not the column" do
    commodity = create(:commodity, name: "Column Name")
    commodity.build.update!(name: "Quantanium")

    assert_includes Commodity.with_facts.ransack(name_cont: "Quantanium").result, commodity
    assert_not_includes Commodity.with_facts.ransack(name_cont: "Column").result, commodity
  end

  test "filters on the type the build carries, not the column" do
    commodity = create(:commodity, commodity_type: "metal")
    commodity.build.update!(commodity_type: "gas")

    assert_includes Commodity.with_facts.ransack(commodity_type_eq: "gas").result, commodity
    assert_not_includes Commodity.with_facts.ransack(commodity_type_eq: "metal").result, commodity
  end

  test "sorts by the name the build carries, not the column" do
    first = create(:commodity, name: "Zzz Column")
    second = create(:commodity, name: "Aaa Column")
    first.build.update!(name: "Aaa Build")
    second.build.update!(name: "Zzz Build")

    result = Commodity.with_facts.ransack(sorts: "name asc").result

    assert_equal [first, second], result.to_a
  end

  # The fallback path, which is `currentVersion=false` and the admin list: a
  # commodity no build describes has to be findable by what its column says.
  test "the fallback join finds a commodity by its column when no build describes it" do
    commodity = create(:commodity, :without_build, name: "Column Only", version: nil)

    assert_includes Commodity.with_facts(false).ransack(name_cont: "Column Only").result, commodity
  end

  test "the facet lists the type the build carries, not the column" do
    commodity = create(:commodity, commodity_type: "metal")
    commodity.build.update!(commodity_type: "gas")

    assert_equal %w[gas], Commodity.commodity_types
  end
end

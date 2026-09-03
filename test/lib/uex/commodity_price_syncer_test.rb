# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class CommodityPriceSyncerTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      Commodity.delete_all
      ItemPrice.where(item_type: "Commodity").delete_all
      @commodities = create_uex_priced_commodities
    end

    def sync(overrides = {})
      Uex::CommodityPriceSyncer.new(client: uex_client_stub(overrides)).run
    end

    def prices_for(commodity)
      ItemPrice.where(item_type: "Commodity", item_id: commodity.id)
    end

    test "#run stores what the shop charges as a sell price" do
      sync

      price = prices_for(@commodities[:agricium_ore]).find_by(price_type: "buy")

      assert_equal "Admin - ARC-L1", price.location
      assert_equal 2245, price.price
    end

    # UEX writes from the player's side, so their price_buy is the shop selling.
    test "#run swaps the UEX price directions onto our shop perspective" do
      sync

      gold = prices_for(@commodities[:gold])

      assert_equal 26_000, gold.find_by(price_type: "sell").price
      assert_equal 29_000, gold.find_by(price_type: "buy").price
    end

    test "#run keeps the cheaper of two terminals sharing a location for a sell price" do
      sync

      assert_equal 26_000, prices_for(@commodities[:gold]).find_by(price_type: "sell").price
    end

    # The mirror of the rule above: of two shops buying the same cargo the
    # player wants the better paid, so the higher figure is the one to keep.
    test "#run keeps the better paid of two terminals sharing a location for a buy price" do
      sync

      assert_equal 29_000, prices_for(@commodities[:gold]).find_by(price_type: "buy").price
    end

    test "#run skips a price of zero rather than storing it" do
      sync

      assert_nil prices_for(@commodities[:agricium_ore]).find_by(price_type: "sell")
    end

    test "#run ignores prices at terminals that do not trade commodities" do
      sync

      assert_empty ItemPrice.where(item_type: "Commodity", location: "Astro Armada - Area 18")
    end

    test "#run carries the terminal contact url" do
      sync

      assert_equal "https://example.test/tdd", prices_for(@commodities[:gold]).first.location_url
    end

    test "#run reports priced commodities that resolve to nothing of ours" do
      result = sync

      assert_equal ["Aslarite"], result.unknown.map { |row| row["commodity_name"] }
    end

    test "#run prices nothing for a commodity that was never mapped" do
      sync

      assert_empty prices_for(@commodities[:unmapped])
    end

    test "#run updates a changed price instead of duplicating the row" do
      sync
      result = sync(commodity_prices: uex_fixture("commodities_prices_all").map { |row|
        (row["id"] == 2) ? row.merge("price_buy" => 25_000) : row
      })

      assert_equal 1, result.updated
      assert_equal 25_000, prices_for(@commodities[:gold]).find_by(price_type: "sell").price
      assert_equal 3, ItemPrice.where(item_type: "Commodity").count
    end

    test "#run is idempotent when nothing changed" do
      sync
      result = sync

      assert_equal 0, result.created
      assert_equal 0, result.updated
    end

    test "#run removes rows for a location UEX no longer lists" do
      sync

      remaining = uex_fixture("terminals").reject { |terminal| terminal["id"] == 102 }
      result = sync(terminals: remaining)

      assert_equal 1, result.removed
      assert_empty ItemPrice.where(item_type: "Commodity", location: "Admin - ARC-L1")
    end

    test "#run leaves prices for other item types alone" do
      model_price = create(:item_price, item: create(:model), price_type: "sell", location: "Admin - ARC-L1")

      sync

      assert ItemPrice.exists?(model_price.id)
    end

    test "#run refuses to sync when the price feed is empty" do
      sync

      error = assert_raises(Uex::Error) { sync(commodity_prices: []) }

      assert_match(/refusing to sync/, error.message)
      assert_equal 3, ItemPrice.where(item_type: "Commodity").count
    end

    test "#run refuses to sync when no terminal trades commodities" do
      vehicles_only = uex_fixture("terminals").reject { |terminal| terminal["type"] == "commodity" }

      assert_raises(Uex::Error) { sync(terminals: vehicles_only) }
    end

    test ".github_issue_body lists the unknown commodities without volatile counts" do
      body = Uex::CommodityPriceSyncer.github_issue_body(sync)

      assert_match(/Priced UEX Commodities We Do Not Carry \(1\)/, body)
      assert_match(/\*\*Aslarite\*\* — UEX id `999`/, body)
      assert_no_match(/created=/, body)
    end

    test "#run records the day's prices as history" do
      sync

      held = ItemPrice.where(item_type: "Commodity")
      recorded = ItemPriceSnapshot.where(item_type: "Commodity", recorded_on: Date.current)

      assert_operator held.count, :>, 0
      assert_equal held.count, recorded.count
      assert_equal held.pluck(:price).sort, recorded.pluck(:price).sort
      assert_equal held.pluck(:location).sort, recorded.pluck(:location).sort
    end

    # A second run the same day is a correction, not a second day.
    test "#run replaces the day it already recorded" do
      sync
      first = ItemPriceSnapshot.where(item_type: "Commodity").count

      sync

      assert_equal first, ItemPriceSnapshot.where(item_type: "Commodity").count
    end

    test "#run leaves earlier days alone" do
      commodity = @commodities[:gold]
      ItemPriceSnapshot.create!(
        item: commodity, location: "Old Terminal", price_type: "sell",
        price: 1, recorded_on: 30.days.ago.to_date
      )

      sync

      assert ItemPriceSnapshot.exists?(location: "Old Terminal", recorded_on: 30.days.ago.to_date)
    end

    # Ships are synced by the other syncer on its own schedule, so one must not
    # clear the other's day.
    test "#run leaves another item type's history alone" do
      model = create(:model)
      ItemPriceSnapshot.create!(
        item: model, location: "Astro Armada", price_type: "sell",
        price: 100, recorded_on: Date.current
      )

      sync

      assert_equal 1, ItemPriceSnapshot.where(item_type: "Model").count
    end
  end
end

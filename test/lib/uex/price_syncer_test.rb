# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class PriceSyncerTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      ItemPrice.delete_all
      @models = create_uex_fixture_models
    end

    test "#run creates a price row per matched vehicle and vehicle terminal" do
      result = sync

      assert_equal 6, result.created
      assert_equal 0, result.updated
      assert_equal 0, result.removed
      assert_equal 6, ItemPrice.count
    end

    test "#run maps a UEX purchase price to a sell price, not a buy price" do
      sync

      titan = @models[:name_match].reload

      assert_equal ["Astro Armada - Area 18"], titan.sold_at.map(&:location)
      assert_equal [1_290_370], titan.sold_at.map { |price| price.price.to_i }
      assert_empty titan.bought_at
    end

    test "#run stores rentals as 1-day and carries the terminal contact url" do
      sync

      rental = @models[:name_match].reload.rental_at.first

      assert_equal "Vantage Rentals - Lorville", rental.location
      assert_equal "1-day", rental.time_range
      assert_equal 27_165, rental.price.to_i
      assert_equal "https://example.test/vantage", rental.location_url
    end

    test "#run leaves location_url nil when the terminal has no contact url" do
      sync

      assert_nil @models[:slug_match].reload.sold_at.first.location_url
    end

    test "#run resolves a vehicle that only the explicit mapping covers" do
      sync

      assert_equal 40_000_000, @models[:mapping_match].reload.sold_at.first.price.to_i
    end

    test "#run ignores prices at terminals that do not sell or rent vehicles" do
      sync

      locations = ItemPrice.where(item_type: "Model").pluck(:location).uniq

      assert_equal ["Astro Armada - Area 18", "Vantage Rentals - Lorville"], locations.sort
    end

    test "#run reports vehicles that resolve to no model" do
      result = sync

      assert_equal ["vanduul-scythe"], result.unmatched.map { |vehicle| vehicle["slug"] }
    end

    test "#run reports each unmatched vehicle once even when it has several prices" do
      rentals = uex_fixture("vehicles_rentals_prices_all") +
        [{"id" => 99, "id_vehicle" => 5, "id_terminal" => 101, "price_rent" => 12_500}]

      result = sync(vehicle_rental_prices: rentals)

      assert_equal ["vanduul-scythe"], result.unmatched.map { |vehicle| vehicle["slug"] }
    end

    test "#run updates a changed price instead of duplicating the row" do
      sync

      purchases = uex_fixture("vehicles_purchases_prices_all")
      purchases.find { |row| row["id_vehicle"] == 2 }["price_buy"] = 1_500_000

      result = sync(vehicle_purchase_prices: purchases)

      assert_equal 0, result.created
      assert_equal 1, result.updated
      assert_equal 0, result.removed
      assert_equal 6, ItemPrice.count
      assert_equal 1_500_000, @models[:name_match].reload.sold_at.first.price.to_i
    end

    test "#run is idempotent when nothing changed" do
      sync
      result = sync

      assert_equal 0, result.created
      assert_equal 0, result.updated
      assert_equal 0, result.removed
      assert_equal 6, ItemPrice.count
    end

    test "#run removes rows for a location UEX no longer lists" do
      sync

      purchases = uex_fixture("vehicles_purchases_prices_all").reject { |row| row["id_vehicle"] == 2 }

      result = sync(vehicle_purchase_prices: purchases)

      assert_equal 1, result.removed
      assert_empty @models[:name_match].reload.sold_at
      assert_equal 1, @models[:name_match].reload.rental_at.size
    end

    test "#run leaves prices for other item types alone" do
      component = create(:component)
      hand_entered = create(:item_price, item: component, price_type: :sell, time_range: nil)

      sync

      assert ItemPrice.exists?(hand_entered.id)
    end

    private def sync(overrides = {})
      Uex::PriceSyncer.new(client: uex_client_stub(overrides)).run
    end
  end
end

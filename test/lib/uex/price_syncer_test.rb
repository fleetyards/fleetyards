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

      assert_equal 7, result.created
      assert_equal 0, result.updated
      assert_equal 0, result.removed
      assert_equal 7, ItemPrice.count
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

    test "#run drops a contact url that is not a web link rather than storing it" do
      terminals = uex_fixture("terminals").map do |terminal|
        (terminal["id"] == 101) ? terminal.merge("contact_url" => "javascript:alert(1)") : terminal
      end

      result = sync(terminals:)

      assert_equal 7, result.created, "one odd url must not fail the whole snapshot"
      assert_nil @models[:name_match].reload.rental_at.first.location_url
    end

    test "#run resolves a vehicle that only the explicit mapping covers" do
      sync

      assert_equal 40_000_000, @models[:mapping_match].reload.sold_at.first.price.to_i
    end

    test "#run ignores prices at terminals that do not sell or rent vehicles" do
      sync

      locations = ItemPrice.where(item_type: "Model").pluck(:location).uniq

      assert_equal [
        "Astro Armada - Area 18",
        "New Deal - Teasa Spaceport - Lorville",
        "Vantage Rentals - Lorville"
      ], locations.sort
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
      assert_equal 7, ItemPrice.count
      assert_equal 1_500_000, @models[:name_match].reload.sold_at.first.price.to_i
    end

    test "#run is idempotent when nothing changed" do
      sync
      result = sync

      assert_equal 0, result.created
      assert_equal 0, result.updated
      assert_equal 0, result.removed
      assert_equal 7, ItemPrice.count
    end

    test "#run removes rows for a location UEX no longer lists" do
      sync

      purchases = uex_fixture("vehicles_purchases_prices_all").reject { |row| row["id_vehicle"] == 2 }

      result = sync(vehicle_purchase_prices: purchases)

      assert_equal 1, result.removed
      assert_empty @models[:name_match].reload.sold_at
      assert_equal 1, @models[:name_match].reload.rental_at.size
    end

    test "#run repoints models.price at the cheapest shop that sells the ship" do
      titan = @models[:name_match]
      titan.update!(price: 999)

      result = sync

      assert_equal 4, result.repriced
      assert_equal 1_290_370, titan.reload.price.to_i
    end

    test "#run reprices from the cheapest of several shops" do
      purchases = uex_fixture("vehicles_purchases_prices_all") +
        [{"id" => 98, "id_vehicle" => 2, "id_terminal" => 103, "price_buy" => 1_100_000}]

      sync(vehicle_purchase_prices: purchases)

      assert_equal 1_100_000, @models[:name_match].reload.price.to_i
    end

    test "#run leaves the price of a model UEX sells nowhere alone" do
      rental_only = @models[:name_match]
      rental_only.update!(price: 999)

      purchases = uex_fixture("vehicles_purchases_prices_all").reject { |row| row["id_vehicle"] == 2 }

      sync(vehicle_purchase_prices: purchases)

      assert_equal 999, rental_only.reload.price.to_i
    end

    test "#run reprices nothing on a second run that changed no price" do
      sync
      result = sync

      assert_equal 0, result.repriced
    end

    test "#run records the repricing as a version so a hand-entered figure is told apart" do
      titan = @models[:name_match]
      titan.update!(price: 999)

      sync

      assert_equal "uex_price_sync", titan.versions.last.reason
    end

    test "#run leaves prices for other item types alone" do
      component = create(:component)
      hand_entered = create(:item_price, item: component, price_type: :sell, time_range: nil)

      sync

      assert ItemPrice.exists?(hand_entered.id)
    end

    # A feed that comes back empty still arrives as HTTP 200 / status "ok", and
    # taking it at face value would wipe every price we hold.
    [:vehicles, :terminals, :vehicle_purchase_prices, :vehicle_rental_prices].each do |feed|
      test "#run refuses to sync when the #{feed} feed is empty" do
        sync

        error = assert_raises(Uex::Error) { sync(feed => []) }

        assert_match feed.to_s, error.message
        assert_equal 7, ItemPrice.count, "an empty #{feed} feed must not delete anything"
      end
    end

    test "#run refuses to sync when no terminal sells or rents vehicles" do
      sync

      commodity_only = uex_fixture("terminals").map { |terminal| terminal.merge("type" => "commodity") }

      assert_raises(Uex::Error) { sync(terminals: commodity_only) }
      assert_equal 7, ItemPrice.count
    end

    test "#run keeps prices and reports when a snapshot would remove most of them" do
      sync

      truncated = {
        vehicle_purchase_prices: [uex_fixture("vehicles_purchases_prices_all").first],
        vehicle_rental_prices: [uex_fixture("vehicles_rentals_prices_all").first]
      }

      result = sync(truncated)

      # 4 of the 5 omissions are held back: the two terminals that came back well
      # short keep their rows. The rental terminal listing 1 of the 2 we hold sits
      # exactly on the retention floor, which is ordinary churn at that size.
      assert_equal 4, result.skipped_removals
      assert_equal 1, result.removed
      assert_equal 6, ItemPrice.count
    end

    test "#run still removes a minority of stale rows" do
      sync

      purchases = uex_fixture("vehicles_purchases_prices_all").reject { |row| row["id_vehicle"] == 2 }

      result = sync(vehicle_purchase_prices: purchases)

      assert_equal 0, result.skipped_removals
      assert_equal 1, result.removed
    end

    test "#run keeps rows at a terminal that priced nothing this run" do
      sync

      purchases = uex_fixture("vehicles_purchases_prices_all").reject { |row| row["id_terminal"] == 103 }

      result = sync(vehicle_purchase_prices: purchases)

      assert_equal 0, result.removed
      assert_equal 1, result.skipped_removals
      assert_equal 7, ItemPrice.count
      assert_includes ItemPrice.pluck(:location), "New Deal - Teasa Spaceport - Lorville"
    end

    # The residual case a "did it report at all?" rule cannot judge: the terminal
    # does report, but comes back with a fraction of its stock.
    test "#run keeps rows at a terminal that reported far less than it holds" do
      sync

      short = uex_fixture("vehicles_purchases_prices_all")
        .reject { |row| row["id_terminal"] == 100 && [2, 3, 4].include?(row["id_vehicle"]) }

      result = sync(vehicle_purchase_prices: short)

      assert_equal 0, result.removed, "a terminal listing 1 of the 4 we hold looks truncated, not emptied"
      assert_equal 3, result.skipped_removals
      assert_equal 7, ItemPrice.count
    end

    test "#run removes those rows once the terminal is gone from the terminals feed" do
      sync

      closed = {
        vehicle_purchase_prices: uex_fixture("vehicles_purchases_prices_all").reject { |row| row["id_terminal"] == 103 },
        terminals: uex_fixture("terminals").reject { |terminal| terminal["id"] == 103 }
      }

      result = sync(closed)

      assert_equal 1, result.removed
      assert_equal 0, result.skipped_removals
      assert_not_includes ItemPrice.pluck(:location), "New Deal - Teasa Spaceport - Lorville"
    end

    test "#run removes a row when the terminal swaps one vehicle for another" do
      sync

      swapped = uex_fixture("vehicles_purchases_prices_all").map do |row|
        (row["id_terminal"] == 103) ? row.merge("id_vehicle" => 2) : row
      end

      result = sync(vehicle_purchase_prices: swapped)

      assert_equal 1, result.created
      assert_equal 1, result.removed, "steady listing volume means the omission is real"
      assert_equal 0, result.skipped_removals
    end

    private def sync(overrides = {})
      Uex::PriceSyncer.new(client: uex_client_stub(overrides)).run
    end
  end
end

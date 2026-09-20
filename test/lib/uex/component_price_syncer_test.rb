# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class ComponentPriceSyncerTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      Component.delete_all
      ItemPrice.where(item_type: "Component").delete_all
      @components = create_uex_priced_components
    end

    def sync(overrides = {})
      Uex::ComponentPriceSyncer.new(client: uex_client_stub(overrides)).run
    end

    def prices_for(component)
      ItemPrice.where(item_type: "Component", item_id: component.id)
    end

    # `sc_ref` is the game file's own id and UEX carries it as `item_uuid`. This
    # component is named "Omnisky III" and UEX calls it "Omnisky III Cannon", so
    # only the uuid can have resolved it.
    test "#run resolves a component by sc_ref rather than by name" do
      sync

      assert_equal 15_000, prices_for(@components[:ref_match]).find_by(price_type: "sell", location: "Dumper's Depot - Area 18").price
    end

    test "#run resolves a component by a name nothing else answers to" do
      sync

      price = prices_for(@components[:name_match]).sole

      assert_equal "CenterMass - Area 18", price.location
      assert_equal 4200, price.price
    end

    # UEX writes from the player's side, so their price_buy is the shop selling.
    test "#run swaps the UEX price directions onto our shop perspective" do
      sync

      prices = prices_for(@components[:ref_match])

      assert_equal 15_000, prices.where(price_type: "sell").minimum(:price)
      assert_equal 9000, prices.where(price_type: "buy").maximum(:price)
    end

    test "#run keeps the cheaper of two terminals sharing a location for a sell price" do
      sync

      depot = prices_for(@components[:ref_match]).where(location: "Dumper's Depot - Area 18")

      assert_equal 15_000, depot.find_by(price_type: "sell").price
    end

    # The mirror of the rule above: of two shops buying the same part the player
    # wants the better paid, so the higher figure is the one to keep.
    test "#run keeps the better paid of two terminals sharing a location for a buy price" do
      sync

      depot = prices_for(@components[:ref_match]).where(location: "Dumper's Depot - Area 18")

      assert_equal 9000, depot.find_by(price_type: "buy").price
    end

    test "#run skips a price of zero rather than storing it" do
      sync

      assert_empty prices_for(@components[:free])
    end

    test "#run ignores prices at terminals that do not sell items" do
      sync

      assert_empty ItemPrice.where(item_type: "Component", location: "Admin - ARC-L1")
    end

    test "#run carries the terminal contact url" do
      sync

      assert_equal "https://example.test/centermass",
        prices_for(@components[:name_match]).sole.location_url
    end

    # The game files carry a row per mount, so three components answer to this
    # name. Pricing any of them would put a shop price on a mount welded to one
    # ship, so the row is left alone and reported instead.
    test "#run leaves a name several components answer to unpriced" do
      result = sync

      @components[:ambiguous].each { |component| assert_empty prices_for(component) }
      assert_equal ["VariPuck S3 Gimbal Mount"], result.ambiguous.map { |row, _| row["item_name"] }
    end

    test "#run reports which components an ambiguous name reached" do
      result = sync

      _row, sc_keys = result.ambiguous.sole

      assert_equal %w[mount_gimbal_s3 mount_gimbal_s3_perseus mount_gimbal_s3_polaris], sc_keys.sort
    end

    # MAPPINGS is an override, so it settles a name that would otherwise be
    # ambiguous -- and settles it on the component it names, not the other one.
    test "#run prices the component a mapping names" do
      sync

      assert_equal 7700, prices_for(@components[:mapping_match]).sole.price
      assert_empty prices_for(@components[:mapping_loser])
    end

    test "#run reports a priced item no component is named by" do
      result = sync

      assert_equal ["Lillo Pants Violet"], result.unknown.map { |row| row["item_name"] }
    end

    test "#run counts what it wrote" do
      result = sync

      assert_equal ItemPrice.where(item_type: "Component").count, result.created
      assert_equal 0, result.updated
    end

    test "#run updates a price that moved rather than adding a second row" do
      sync

      ItemPrice.where(item_type: "Component", item_id: @components[:name_match].id).update_all(price: 1)
      result = sync

      assert_equal 4200, prices_for(@components[:name_match]).sole.price
      assert_equal 1, result.updated
    end

    test "#run removes a price the feed no longer lists" do
      sync
      stale = ItemPrice.create!(
        item: @components[:name_match], price_type: "sell",
        location: "Astro Armada - Area 18", price: 99
      )

      sync

      assert_not ItemPrice.exists?(stale.id)
    end

    # An empty feed arrives as HTTP 200 with status "ok", and taking it at face
    # value would read as "every shop closed" and delete every price we hold.
    test "#run refuses an empty price feed rather than deleting what we hold" do
      sync

      assert_raises(Uex::Error) { sync(item_prices: []) }
      assert_predicate ItemPrice.where(item_type: "Component"), :any?
    end

    test "#run records the day's prices as snapshots" do
      sync

      assert_equal ItemPrice.where(item_type: "Component").count,
        ItemPriceSnapshot.where(item_type: "Component", recorded_on: Date.current).count
    end

    test "#run replaces the day's snapshots on a second run rather than doubling them" do
      sync
      before = ItemPriceSnapshot.where(item_type: "Component", recorded_on: Date.current).count

      sync

      assert_equal before, ItemPriceSnapshot.where(item_type: "Component", recorded_on: Date.current).count
    end

    test ".github_issue_body names both the unknown and the ambiguous" do
      body = Uex::ComponentPriceSyncer.github_issue_body(sync)

      assert_includes body, "Lillo Pants Violet"
      assert_includes body, "VariPuck S3 Gimbal Mount"
      assert_includes body, "mount_gimbal_s3_polaris"
    end

    # GithubIssueCreator dedupes on a digest of the body and prices move every
    # day, so a count in here would open a fresh issue on every run.
    test ".github_issue_body carries nothing that moves with the prices" do
      body = Uex::ComponentPriceSyncer.github_issue_body(sync)

      assert_not_includes body, "created="
      assert_not_includes body, "15000"
    end
  end
end

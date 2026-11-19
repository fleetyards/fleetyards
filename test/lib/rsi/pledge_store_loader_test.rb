# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Rsi
  class PledgeStoreLoaderTest < ActiveSupport::TestCase
    URL = "https://robertsspaceindustries.com/graphql"

    def store_body(upgrades, skus: [])
      [{data: {store: {search: {resources: [
        {id: "56", slug: "cutlass-black", msrp: 11000, purchasable: true, upgrades:, skus:}
      ]}}}}].to_json
    end

    def skus_body(resources)
      [{data: {store: {search: {resources:}}}}].to_json
    end

    def stub_store(ship_body, skus_body = nil)
      stub_request(:post, URL).with { |request| request.body.include?("GetShip") }.to_return(status: 200, body: ship_body)
      stub_request(:post, URL).with { |request| request.body.include?("GetSkus") }.to_return(status: 200, body: skus_body) if skus_body
    end

    setup do
      @model = create(:model, name: "Cutlass Black", rsi_id: 56, rsi_chassis_id: 6)
    end

    test "an upgrade the store sells into the ship marks it on sale and seen" do
      stub_request(:post, URL).to_return(status: 200, body: store_body([{id: 1, title: "Cutlass Black"}]))

      PledgeStoreLoader.new.run(@model)

      assert @model.reload.ccu_on_sale
      assert_not_nil @model.ccu_target_seen_at
    end

    test "a ship the store sells no upgrade into today keeps having been seen" do
      seen = Time.zone.parse("2026-05-01 12:00")
      @model.update!(ccu_on_sale: true, ccu_target_seen_at: seen)
      stub_request(:post, URL).to_return(status: 200, body: store_body([]))

      PledgeStoreLoader.new.run(@model)

      assert_not @model.reload.ccu_on_sale
      assert_equal seen, @model.ccu_target_seen_at
    end

    test "names the columns a run moved" do
      @model.update!(rsi_pledge_slug: "cutlass-black", rsi_pledge_value: 11000, pledge_price: 110, on_sale: false)
      stub_request(:post, URL).to_return(status: 200, body: store_body([{id: 1, title: "Cutlass Black"}]))

      loader = PledgeStoreLoader.new
      loader.run(@model)

      assert_equal %w[ccu_on_sale on_sale], loader.changed_fields[@model.id]
    end

    test "names nothing for a run that moved nothing" do
      @model.update!(rsi_pledge_slug: "cutlass-black", rsi_pledge_value: 11000, pledge_price: 110, on_sale: true)
      stub_request(:post, URL).to_return(status: 200, body: store_body([]))

      loader = PledgeStoreLoader.new
      loader.run(@model)

      assert_empty loader.changed_fields
    end

    test "keeps the upgrade SKU and the regular standalone SKU" do
      skus = [{id: "1", slug: "upgrade"}, {id: "2", slug: "warbond"}, {id: "3", slug: "standalone"}, {id: "4", slug: "pack"}]
      stub_store(
        store_body([{id: 1, title: "Cutlass Black"}], skus:),
        skus_body([
          {id: "1", subtitle: "Ship Upgrade", isWarbond: false},
          {id: "2", subtitle: "Standalone Ships", isWarbond: true},
          {id: "3", subtitle: "Standalone Ships", isWarbond: false},
          {id: "4", subtitle: "Packs", isWarbond: false}
        ])
      )

      PledgeStoreLoader.new.run(@model)

      assert_equal 3, @model.reload.rsi_standalone_sku_id
      assert_equal 1, @model.rsi_upgrade_sku_id
    end

    test "takes a warbond standalone SKU when it is the only one" do
      stub_store(
        store_body([], skus: [{id: "2", slug: "warbond"}]),
        skus_body([{id: "2", subtitle: "Standalone Ships", isWarbond: true}])
      )

      PledgeStoreLoader.new.run(@model)

      assert_equal 2, @model.reload.rsi_standalone_sku_id
    end

    test "keeps the upgrade SKU through a sale's end, and drops a standalone SKU only packs sell now" do
      @model.update!(rsi_standalone_sku_id: 3, rsi_upgrade_sku_id: 1)
      stub_store(store_body([], skus: [{id: "4", slug: "pack"}]), skus_body([{id: "4", subtitle: "Packs", isWarbond: false}]))

      PledgeStoreLoader.new.run(@model)

      assert_nil @model.reload.rsi_standalone_sku_id
      assert_equal 1, @model.rsi_upgrade_sku_id
    end

    test "keeps the standalone SKU when RSI gives no usable answer" do
      @model.update!(rsi_standalone_sku_id: 3)
      stub_store(store_body([], skus: [{id: "3", slug: "standalone"}]), {errors: [{message: "boom"}]}.to_json)

      PledgeStoreLoader.new.run(@model)

      assert_equal 3, @model.reload.rsi_standalone_sku_id
    end

    test "names a ship on sale that only a pack sells" do
      stub_store(store_body([], skus: [{id: "4", slug: "pack"}]), skus_body([{id: "4", subtitle: "Packs", isWarbond: false}]))

      loader = PledgeStoreLoader.new
      loader.run(@model)

      assert_equal [@model], loader.without_standalone
    end
  end
end

# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Rsi
  class PledgeStoreLoaderTest < ActiveSupport::TestCase
    URL = "https://robertsspaceindustries.com/graphql"

    def store_body(upgrades)
      [{data: {store: {search: {resources: [
        {id: "56", slug: "cutlass-black", msrp: 11000, purchasable: true, upgrades:}
      ]}}}}].to_json
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
  end
end

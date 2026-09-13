# frozen_string_literal: true

require "test_helper"

module Inventories
  class TransferRepeatTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @officer = create(:user)
      create(:fleet_membership, :accepted, :as_officer, fleet: @fleet, user: @officer)
      [@officer, @fleet].each do |actor|
        Flipper.enable_actor(:inventory_transfers, actor)
      end
      Flipper.enable_actor(:hangar_inventories, @officer)
      Flipper.enable_actor(:fleet_logistics, @fleet)

      @depot = create(:fleet_inventory, fleet: @fleet)
      @entry = create(:fleet_inventory_item, fleet_inventory: @depot, name: "Agricium",
        category: :commodity, unit: :scu, quantity: 12)
      @locker = create(:inventory, holder: @officer)
    end

    test "each send takes its quantity out of the fleet, and runs out" do
      2.times do |round|
        assert send_five, "round #{round} was refused"
      end

      assert_equal 2, @depot.reload.stock_positions.sole.net_quantity
      assert_equal 10, @locker.reload.stock_positions.sole.net_quantity

      # 2 SCU left, so a third 5 SCU send cannot happen.
      refute send_five, "a third send drew from stock that was not there"
      assert_equal 2, @depot.reload.stock_positions.sole.net_quantity
    end

    # Every attribute an error is reported on has to be readable, or
    # `ValidationError` raises while rendering the refusal and a 400 becomes a
    # 500 -- which is how a refused transfer came back as nothing at all.
    test "every refusal renders" do
      cases = {
        over_stock: {position_id: @entry.position.id, quantity: 999},
        zero: {position_id: @entry.position.id, quantity: 0},
        unknown_position: {position_id: SecureRandom.uuid, quantity: 1}
      }

      cases.each_value do |line|
        builder = TransferBuilder.new(
          source: @depot.reload, actor: @officer, destination: @locker, lines: [line]
        )

        refute builder.call

        assert_nothing_raised do
          ValidationError.new("inventory_transfers.create", errors: builder.errors).as_json
        end
      end
    end

    private def send_five
      builder = TransferBuilder.new(
        source: @depot.reload, actor: @officer, destination: @locker,
        lines: [{position_id: @entry.reload.position.id, quantity: 5}]
      )
      builder.call
    end
  end
end

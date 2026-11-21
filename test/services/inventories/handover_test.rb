# frozen_string_literal: true

require "test_helper"

module Inventories
  class HandoverTest < ActiveSupport::TestCase
    setup do
      @alice = create(:user)
      @bob = create(:user)
      @fleet = create(:fleet, members: [@alice, @bob])
      @inventory = create(:fleet_inventory, fleet: @fleet)
      @entry = create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", quantity: 100,
        quality: 600, holder: @alice)
      @stock_item = @inventory.stock_item(@entry.position.slug)
    end

    def handover(**attributes)
      Handover.new(inventory: @inventory, stock_item: @stock_item, actor: @alice, quality: 600, **attributes)
    end

    def shares
      InventoryHolderBalances.new(@inventory.fleet_inventory_items).for_position(@entry.position.id)
        .to_h { |share| [share.holder&.id, share.net_quantity.to_f] }
    end

    test "moves part of a lot from one holder to another" do
      assert handover(from_holder_id: @alice.id, to_holder_id: @bob.id, quantity: 40).call

      assert_equal({@alice.id => 60.0, @bob.id => 40.0}, shares)
      assert_equal 100, @inventory.stock_item(@entry.position.slug).net_quantity
    end

    test "keeps the lot's grade" do
      handover(from_holder_id: @alice.id, to_holder_id: @bob.id, quantity: 40).call

      assert_equal [600], @inventory.fleet_inventory_items.where(holder: @bob).pluck(:quality)
    end

    test "refuses a grade the giver does not hold" do
      result = Handover.new(inventory: @inventory, stock_item: @stock_item, actor: @alice, quality: 300,
        from_holder_id: @alice.id, to_holder_id: @bob.id, quantity: 10)

      assert_no_difference "FleetInventoryItem.count" do
        assert_not result.call
      end
      assert_includes result.errors[:quantity].join, "holds at this grade (0"
    end

    test "hands over into the unassigned share" do
      assert handover(from_holder_id: @alice.id, to_holder_id: nil, quantity: 100).call

      assert_equal({nil => 100.0}, shares)
    end

    test "writes nothing when the giver does not hold enough" do
      result = handover(from_holder_id: @bob.id, to_holder_id: @alice.id, quantity: 1)

      assert_no_difference "FleetInventoryItem.count" do
        assert_not result.call
      end
      assert_includes result.errors[:quantity].join, "exceeds what #{@bob.username} holds"
    end

    test "writes nothing when the taker is not a member" do
      result = handover(from_holder_id: @alice.id, to_holder_id: create(:user).id, quantity: 10)

      assert_no_difference "FleetInventoryItem.count" do
        assert_not result.call
      end
    end

    test "refuses a hand-over without an amount" do
      result = handover(from_holder_id: @alice.id, to_holder_id: @bob.id)

      assert_not result.call
      assert_includes result.errors.details[:quantity].pluck(:error), :greater_than
    end

    test "refuses handing a share to the one already holding it" do
      result = handover(from_holder_id: @alice.id, to_holder_id: @alice.id, quantity: 10)

      assert_not result.call
      assert_includes result.errors.details[:to_holder_id].pluck(:error), :same_holder
    end
  end
end

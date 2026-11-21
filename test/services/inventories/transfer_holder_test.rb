# frozen_string_literal: true

require "test_helper"

module Inventories
  class TransferHolderTest < ActiveSupport::TestCase
    setup do
      @officer = create(:user)
      @alice = create(:user)
      @fleet = create(:fleet, officers: [@officer], members: [@alice])
      @user = create(:user)
      @hangar = create(:inventory, holder: @user)
      @depot = create(:fleet_inventory, fleet: @fleet)
      @other_depot = create(:fleet_inventory, fleet: @fleet)

      Flipper.enable_actor(:fleet_logistics, @fleet)

      @entry = create(:fleet_inventory_item, fleet_inventory: @depot, name: "Medpen", category: :consumable,
        unit: :units, quantity: 20, holder: @alice)
      create(:fleet_inventory_item, fleet_inventory: @depot, name: "Medpen", category: :consumable,
        unit: :units, quantity: 5)
    end

    def send_to_user(quantity, **options)
      TransferBuilder.new(source: @depot, actor: @officer, recipient: @user,
        lines: [{position_id: @entry.position.id, quantity:}], **options)
    end

    test "a shipment leaves from the named holder's share" do
      builder = send_to_user(15, source_holder_id: @alice.id)

      assert builder.call, builder.errors.full_messages.to_sentence
      assert_equal [@alice.id], builder.transfer.dispatched_entries.pluck(:holder_id)
    end

    test "a shipment without a holder leaves from the unassigned share" do
      assert_not send_to_user(6).call

      builder = send_to_user(5)

      assert builder.call, builder.errors.full_messages.to_sentence
      assert_equal [nil], builder.transfer.dispatched_entries.pluck(:holder_id)
    end

    test "a refused shipment goes back to the holder it left" do
      builder = send_to_user(15, source_holder_id: @alice.id)
      builder.call

      resolver = TransferResolver.new(builder.transfer, actor: @user)

      assert resolver.decline, resolver.errors.full_messages.to_sentence

      returned = @depot.fleet_inventory_items.deposit.from_transfers.sole

      assert_equal @alice.id, returned.holder_id
    end

    test "goods arriving in a fleet inventory are unassigned" do
      builder = TransferBuilder.new(source: @depot, actor: @officer, destination: @other_depot,
        source_holder_id: @alice.id, lines: [{position_id: @entry.position.id, quantity: 10}])

      assert builder.call, builder.errors.full_messages.to_sentence
      assert_equal [nil], @other_depot.fleet_inventory_items.pluck(:holder_id)
    end
  end
end

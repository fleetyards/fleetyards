# frozen_string_literal: true

require "test_helper"

module Inventories
  # Nothing may destroy the withdrawal that represents goods in flight.
  class TransferGuardsTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @recipient = create(:user)
      [@user, @recipient].each do |actor|
        Flipper.enable_actor(:inventory_transfers, actor)
        Flipper.enable_actor(:hangar_inventories, actor)
      end

      @source = create(:inventory, holder: @user)
      @entry = create(:inventory_item, inventory: @source, name: "Titanium",
        category: :commodity, unit: :scu, quantity: 96)

      @builder = TransferBuilder.new(source: @source, actor: @user, recipient: @recipient,
        lines: [{position_id: @entry.position.id, quantity: 40}])
      @builder.call
    end

    test "an inventory with goods in transit cannot be destroyed" do
      refute @source.destroy
      assert Inventory.exists?(@source.id)
      assert_includes @source.errors.full_messages.join(" "), "still waiting to be answered"
    end

    test "the position the goods came from cannot be destroyed either" do
      stock_item = @source.stock_item(@entry.position.slug)

      refute @source.destroy_stock_item(stock_item)
      assert InventoryPosition.exists?(@entry.position.id)
    end

    test "once the transfer is answered both destroys are free again" do
      TransferResolver.new(@builder.transfer, actor: @recipient).decline

      stock_item = @source.reload.stock_item(@entry.position.slug)

      assert @source.destroy_stock_item(stock_item)
      assert @source.reload.destroy
    end

    test "an unrelated inventory is unaffected" do
      other = create(:inventory, holder: @user)
      create(:inventory_item, inventory: other, quantity: 5)

      assert other.destroy
    end

    test "a fleet inventory is guarded the same way" do
      fleet = create(:fleet)
      officer = create(:user)
      create(:fleet_membership, :accepted, :as_officer, fleet:, user: officer)
      Flipper.enable_actor(:inventory_transfers, officer)
      Flipper.enable_actor(:hangar_inventories, officer)

      depot = create(:fleet_inventory, fleet:)
      entry = create(:fleet_inventory_item, fleet_inventory: depot, quantity: 20)

      builder = TransferBuilder.new(source: depot, actor: officer, recipient: @recipient,
        lines: [{position_id: entry.position.id, quantity: 5}])

      assert builder.call, builder.errors.full_messages.to_sentence
      refute depot.destroy
      assert FleetInventory.exists?(depot.id)
    end
  end
end

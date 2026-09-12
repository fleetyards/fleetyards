# frozen_string_literal: true

require "test_helper"

module Inventories
  # The two movements that cross `inventory_items` and `fleet_inventory_items`.
  # Nothing else in the app writes to both.
  class TransferAcrossSchemasTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @fleet = create(:fleet)
      @officer = create(:user)
      create(:fleet_membership, :accepted, :as_officer, fleet: @fleet, user: @officer)

      @hangar = create(:inventory, holder: @user)
      @depot = create(:fleet_inventory, fleet: @fleet)

      [@user, @officer].each { |actor| enable_transfers(actor) }
      Flipper.enable_actor(:inventory_transfers, @fleet)
      Flipper.enable_actor(:fleet_logistics, @fleet)
    end

    test "a user donates to a fleet, and the fleet entry gets its added_by" do
      entry = create(:inventory_item, inventory: @hangar, name: "Titanium",
        category: :commodity, unit: :scu, quantity: 96)

      builder = TransferBuilder.new(
        source: @hangar, actor: @user, recipient: @fleet,
        lines: [{position_id: entry.position.id, quantity: 30}]
      )

      assert builder.call, builder.errors.full_messages.to_sentence
      assert builder.transfer.pending?

      resolver = TransferResolver.new(builder.transfer, actor: @officer)

      assert resolver.accept(@depot), resolver.errors.full_messages.to_sentence

      deposit = @depot.fleet_inventory_items.sole

      assert_equal "Titanium", deposit.name
      assert_equal 30, deposit.quantity
      assert deposit.deposit?
      assert_equal @officer.id, deposit.added_by,
        "ledger_attributes_for must supply the column the user schema does not have"
      assert_nil deposit.member_id, "a transfer cannot know whose goods these are"
    end

    test "a fleet issues to a user, and the user entry gains no columns it has no place for" do
      entry = create(:fleet_inventory_item, fleet_inventory: @depot, name: "Medpen",
        category: :consumable, unit: :units, quantity: 20)

      builder = TransferBuilder.new(
        source: @depot, actor: @officer, recipient: @user,
        lines: [{position_id: entry.position.id, quantity: 5}]
      )

      assert builder.call, builder.errors.full_messages.to_sentence

      resolver = TransferResolver.new(builder.transfer, actor: @user)

      assert resolver.accept(@hangar), resolver.errors.full_messages.to_sentence

      deposit = @hangar.inventory_items.sole

      assert_equal "Medpen", deposit.name
      assert_equal 5, deposit.quantity
      assert_equal 15, @depot.reload.stock_positions.first.net_quantity
    end

    test "the catalogue reference survives the crossing" do
      component = create(:component)
      entry = create(:inventory_item, inventory: @hangar, item: component,
        name: component.name, category: :component, unit: :units, quantity: 4)

      builder = TransferBuilder.new(
        source: @hangar, actor: @user, recipient: @fleet,
        lines: [{position_id: entry.position.id, quantity: 4}]
      )
      builder.call
      TransferResolver.new(builder.transfer, actor: @officer).accept(@depot)

      deposit = @depot.fleet_inventory_items.sole

      assert_equal "Component", deposit.item_type
      assert_equal component.id, deposit.item_id
    end

    test "quality is carried only when the position holds one grade" do
      entry = create(:inventory_item, inventory: @hangar, name: "Quantanium",
        category: :commodity, unit: :scu, quantity: 10, quality: 700)

      builder = TransferBuilder.new(source: @hangar, actor: @user, recipient: @fleet,
        lines: [{position_id: entry.position.id, quantity: 5}])
      builder.call
      TransferResolver.new(builder.transfer, actor: @officer).accept(@depot)

      assert_equal 700, @depot.fleet_inventory_items.sole.quality

      # A second grade in the same position makes "which five" unanswerable.
      create(:inventory_item, inventory: @hangar, name: "Quantanium",
        category: :commodity, unit: :scu, quantity: 10, quality: 300)

      second = TransferBuilder.new(source: @hangar, actor: @user, recipient: @fleet,
        lines: [{position_id: entry.reload.position.id, quantity: 5}])
      second.call
      TransferResolver.new(second.transfer, actor: @officer).accept(@depot)

      assert_nil @depot.fleet_inventory_items.order(:created_at).last.quality
    end

    test "accepting a shipment into a fleet announces it once, not once per line" do
      %w[Titanium Medpen Tungsten].each do |name|
        create(:inventory_item, inventory: @hangar, name:, category: :commodity,
          unit: :scu, quantity: 10)
      end

      builder = TransferBuilder.new(
        source: @hangar, actor: @user, recipient: @fleet,
        lines: @hangar.positions.map { |position| {position_id: position.id, quantity: 2} }
      )
      builder.call

      assert_difference -> { Notification.where(notification_type: :fleet_inventory_item_added).count }, 0 do
        TransferResolver.new(builder.transfer, actor: @officer).accept(@depot)
      end
    end

    test "a member without the privilege cannot accept for the fleet" do
      plain = create(:user)
      create(:fleet_membership, :accepted, fleet: @fleet, user: plain)
      entry = create(:inventory_item, inventory: @hangar, quantity: 10)

      builder = TransferBuilder.new(source: @hangar, actor: @user, recipient: @fleet,
        lines: [{position_id: entry.position.id, quantity: 5}])
      builder.call

      resolver = TransferResolver.new(builder.transfer, actor: plain)

      refute resolver.accept(@depot)
      assert builder.transfer.reload.pending?
    end

    test "an accept naming an inventory the acceptor does not hold is refused" do
      stranger_inventory = create(:inventory, holder: create(:user))
      entry = create(:inventory_item, inventory: @hangar, quantity: 10)

      builder = TransferBuilder.new(source: @hangar, actor: @user, recipient: @fleet,
        lines: [{position_id: entry.position.id, quantity: 5}])
      builder.call

      resolver = TransferResolver.new(builder.transfer, actor: @officer)

      refute resolver.accept(stranger_inventory)
      assert builder.transfer.reload.pending?
    end

    test "moving into a fleet you are privileged in needs no handshake" do
      entry = create(:inventory_item, inventory: @hangar, quantity: 10)
      create(:fleet_membership, :accepted, :as_officer, fleet: @fleet, user: @user)

      builder = TransferBuilder.new(source: @hangar, actor: @user, destination: @depot,
        lines: [{position_id: entry.position.id, quantity: 5}])

      assert builder.call, builder.errors.full_messages.to_sentence
      assert builder.transfer.completed?, "an initiator who could deposit by hand is not made to ask"
      assert_equal 5, @depot.reload.stock_positions.sole.net_quantity
    end

    private def enable_transfers(actor)
      Flipper.enable_actor(:inventory_transfers, actor)
      Flipper.enable_actor(:hangar_inventories, actor)
    end
  end
end

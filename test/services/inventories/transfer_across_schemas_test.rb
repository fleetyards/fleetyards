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

    # A position holding several grades is spent across them, lowest first, and
    # the deposits carry the grades they came from. Leaving the grade unset put
    # the withdrawal in a quality group no deposit occupied, which
    # `current_stock` then hid -- so the list never moved and the same stock
    # could be sent over and over.
    test "a line is spent across the grades the position holds" do
      create(:inventory_item, inventory: @hangar, name: "Quantanium",
        category: :commodity, unit: :scu, quantity: 4, quality: 700)
      entry = create(:inventory_item, inventory: @hangar, name: "Quantanium",
        category: :commodity, unit: :scu, quantity: 10, quality: 300)

      # 12 of the 14 held: the whole 300 grade, then the rest out of the 700.
      builder = TransferBuilder.new(source: @hangar, actor: @user, recipient: @fleet,
        lines: [{position_id: entry.position.id, quantity: 12}])

      assert builder.call, builder.errors.full_messages.to_sentence

      assert_equal [[300, 10], [700, 2]],
        builder.transfer.dispatched_entries.map { |e| [e.quality, e.quantity.to_i] }.sort

      TransferResolver.new(builder.transfer, actor: @officer).accept(@depot)

      assert_equal [[300, 10], [700, 2]],
        @depot.fleet_inventory_items.map { |e| [e.quality, e.quantity.to_i] }.sort
    end

    # The whole point: what the list shows has to fall by what was sent.
    test "the per-quality rollup the list renders depletes" do
      create(:inventory_item, inventory: @hangar, name: "Agricium",
        category: :commodity, unit: :scu, quantity: 100, quality: 600)
      entry = create(:inventory_item, inventory: @hangar, name: "Agricium",
        category: :commodity, unit: :scu, quantity: 5, quality: 0)

      assert_equal 105, visible_stock

      3.times do
        builder = TransferBuilder.new(source: @hangar.reload, actor: @user, recipient: @fleet,
          lines: [{position_id: entry.reload.position.id, quantity: 5}])

        assert builder.call, builder.errors.full_messages.to_sentence
      end

      assert_equal 90, visible_stock
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

    # What `current_stock` adds up to -- the rollup the stock list renders,
    # grouped per quality and dropping any group that is not positive.
    private def visible_stock
      @hangar.reload.current_stock.sum { |row| row.net_quantity.to_i }
    end

    private def enable_transfers(actor)
      Flipper.enable_actor(:inventory_transfers, actor)
      Flipper.enable_actor(:hangar_inventories, actor)
    end
  end
end

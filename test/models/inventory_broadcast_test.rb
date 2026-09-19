# frozen_string_literal: true

require "test_helper"

# Who is told when stock moves. The audience is the same pair of questions the
# endpoints ask -- the read privileges, and `visible_to?` -- so a member who
# cannot read an officers-only store is not told that it changed either.
class InventoryBroadcastTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @officer = create(:user)
    @member = create(:user)
    @manager = create(:user)
    @fleet = create(:fleet, officers: [@officer], members: [@member, @manager])
  end

  def fleet_broadcasts_to(user)
    broadcasts(FleetInventoryChannel.broadcasting_for(user)).size
  end

  def hangar_broadcasts_to(user)
    broadcasts(HangarInventoryChannel.broadcasting_for(user)).size
  end

  test "a members-only store tells everyone who can read it" do
    depot = create(:fleet_inventory, fleet: @fleet)

    [@officer, @member, @manager].each do |user|
      assert_difference -> { fleet_broadcasts_to(user) }, 1,
        "#{user.username} was not told about a members-only store" do
        create(:fleet_inventory_item, fleet_inventory: depot)
      end
    end
  end

  test "an officers-only store tells the officers and its manager, and nobody else" do
    closed = create(:fleet_inventory, :officers_only, fleet: @fleet, manager: @manager)

    [@officer, @manager].each do |user|
      assert_difference -> { fleet_broadcasts_to(user) }, 1,
        "#{user.username} should hear about an officers-only store" do
        create(:fleet_inventory_item, fleet_inventory: closed)
      end
    end

    assert_no_difference -> { fleet_broadcasts_to(@member) },
      "a plain member was told about a store they cannot read" do
      create(:fleet_inventory_item, fleet_inventory: closed)
    end
  end

  test "somebody outside the fleet is never told" do
    outsider = create(:user)
    depot = create(:fleet_inventory, fleet: @fleet)

    assert_no_difference -> { fleet_broadcasts_to(outsider) } do
      create(:fleet_inventory_item, fleet_inventory: depot)
    end
  end

  test "a hangar inventory tells its holder and only its holder" do
    holder = create(:user)
    other = create(:user)
    inventory = create(:inventory, holder: holder)

    assert_difference -> { hangar_broadcasts_to(holder) }, 1 do
      assert_no_difference -> { hangar_broadcasts_to(other) } do
        create(:inventory_item, inventory: inventory)
      end
    end
  end

  # A ship's inventory is the holder's too -- it is reached through `vehicle`
  # rather than through a holder of its own, so it rides the same channel.
  test "a ship inventory tells the holder as a hand-made one does" do
    holder = create(:user)
    vehicle = create(:vehicle, user: holder)
    inventory = Inventory.provision_for(vehicle, holder: holder)

    assert_difference -> { hangar_broadcasts_to(holder) }, 1 do
      create(:inventory_item, inventory: inventory)
    end
  end

  # A channel's `broadcast_to` is inherited, so overriding it on the class and
  # removing the override again puts the real one back -- minitest 6 dropped
  # `stub`, and the suite pulls in no mocking library.
  def with_broadcast_failing(channel, recorder = [])
    channel.define_singleton_method(:broadcast_to) do |recipient, _payload|
      recorder << recipient
      raise "pubsub is down"
    end

    yield recorder
  ensure
    channel.singleton_class.send(:remove_method, :broadcast_to)
  end

  # The ping runs after the write it reports has already committed, so a
  # pubsub backend that is down must not turn a deposit that landed into a
  # deposit that raised -- and one recipient failing must not cost the rest
  # of the roster their notification.
  test "a failing broadcast neither raises nor stops the fan-out" do
    depot = create(:fleet_inventory, fleet: @fleet)

    with_broadcast_failing(FleetInventoryChannel) do |attempted|
      assert_nothing_raised do
        create(:fleet_inventory_item, fleet_inventory: depot)
      end

      assert_equal 3, attempted.count,
        "the fan-out stopped at the first recipient that raised"
    end
  end

  test "a failing hangar broadcast does not fail the write" do
    holder = create(:user)
    inventory = create(:inventory, holder: holder)

    with_broadcast_failing(HangarInventoryChannel) do
      assert_nothing_raised do
        create(:inventory_item, inventory: inventory)
      end
    end
  end
end

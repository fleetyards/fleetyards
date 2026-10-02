# frozen_string_literal: true

require "test_helper"

class Fleets::PurgedFleetRestorerTest < ActiveSupport::TestCase
  setup do
    @creator = create(:user)
    @officer = create(:user)
  end

  test "rebuilds a hard-deleted fleet with its roles, memberships and inventories" do
    fleet = create(:fleet, created_by: @creator.id, officers: [@officer])
    inventory = fleet.fleet_inventories.create!(name: "Main Hangar", visibility: :members_only)
    inventory.fleet_inventory_items.create!(name: "Quantum Fuel", quantity: 5)
    fleet_id = fleet.id

    # Load fresh before destroying so no membership is cached in memory with a
    # stale fleet_role_id: this mirrors production, where the role-nullify on
    # destroy leaves every membership's destroy snapshot with a nil role.
    Fleet.find(fleet_id).destroy
    assert_not Fleet.exists?(fleet_id)

    restored = Fleets::PurgedFleetRestorer.new(fleet_id).call

    assert_equal fleet_id, restored.id
    assert_equal %w[Admin Member Officer], restored.fleet_roles.pluck(:name).sort
    assert_equal 2, restored.fleet_memberships.count

    # The fleet owner is reliably restored as admin; other members are restored
    # but their role assignment is best effort (see PurgedFleetRestorer).
    assert_equal "Admin", restored.fleet_memberships.find_by(user_id: @creator.id).fleet_role.name
    assert restored.fleet_memberships.exists?(user_id: @officer.id)

    assert_equal ["Main Hangar"], restored.fleet_inventories.pluck(:name)
    assert_equal ["Quantum Fuel"], restored.fleet_inventories.first.fleet_inventory_items.pluck(:name)

    # The reified attributes carry no position -- the one the entry pointed at
    # was destroyed with the fleet -- so it is resolved again from the identity
    # the entry still holds.
    restored_item = restored.fleet_inventories.first.fleet_inventory_items.first
    assert_equal "Quantum Fuel", restored_item.position.name
    assert_equal restored.fleet_inventories.first, restored_item.position.inventory
  end

  test "brings back what the fleet called its squadron ranks" do
    fleet = create(:fleet, name: "Rank Fleet", fid: "RANKFLEET")
    fleet.fleet_squadron_roles.find_by!(key: "leader").update!(name: "Wing Commander")
    fleet_id = fleet.id

    Fleet.find(fleet_id).destroy!

    restored = Fleets::PurgedFleetRestorer.new(fleet_id).call

    assert_equal "Wing Commander", restored.fleet_squadron_roles.find_by!(key: "leader").name
    assert_equal "Member", restored.fleet_squadron_roles.find_by!(key: "member").name
  end

  test "preserves discarded memberships instead of reactivating ex-members" do
    fleet = create(:fleet, created_by: @creator.id, officers: [@officer])
    fleet.fleet_memberships.find_by(user_id: @officer.id).discard
    fleet_id = fleet.id

    fleet.destroy

    restored = Fleets::PurgedFleetRestorer.new(fleet_id).call

    assert_not restored.fleet_memberships.find_by(user_id: @officer.id).kept?
    assert restored.fleet_memberships.find_by(user_id: @creator.id).kept?
  end

  test "raises FleetStillExists when the fleet has not been purged" do
    fleet = create(:fleet, created_by: @creator.id)

    assert_raises(Fleets::PurgedFleetRestorer::FleetStillExists) do
      Fleets::PurgedFleetRestorer.new(fleet.id).call
    end
  end

  test "raises FidTaken when an open FID claim reserves the fleet's FID" do
    fleet = create(:fleet, fid: "MARU", created_by: @creator.id)
    fleet_id = fleet.id
    claimant = create(:fleet, :rsi_verified, fid: "MARU-1", rsi_sid: "MARU", created_by: create(:user).id)
    FleetFidClaim.open_for!(claimant, user: @creator)
    Fleet.find(fleet_id).destroy

    assert_raises(Fleets::PurgedFleetRestorer::FidTaken) do
      Fleets::PurgedFleetRestorer.new(fleet_id).call
    end
  end

  test "raises NothingToRestore when there is no destroy version" do
    assert_raises(Fleets::PurgedFleetRestorer::NothingToRestore) do
      Fleets::PurgedFleetRestorer.new(SecureRandom.uuid).call
    end
  end
end

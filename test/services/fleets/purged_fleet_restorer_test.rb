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

    fleet.destroy
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
  end

  test "raises FleetStillExists when the fleet has not been purged" do
    fleet = create(:fleet, created_by: @creator.id)

    assert_raises(Fleets::PurgedFleetRestorer::FleetStillExists) do
      Fleets::PurgedFleetRestorer.new(fleet.id).call
    end
  end

  test "raises NothingToRestore when there is no destroy version" do
    assert_raises(Fleets::PurgedFleetRestorer::NothingToRestore) do
      Fleets::PurgedFleetRestorer.new(SecureRandom.uuid).call
    end
  end
end

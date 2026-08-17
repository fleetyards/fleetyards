# frozen_string_literal: true

require "test_helper"

class FleetDiscardTest < ActiveSupport::TestCase
  setup do
    @creator = create(:user)
  end

  test "discarding a fleet does not destroy its memberships, roles or inventories" do
    member = create(:user)
    fleet = create(:fleet, created_by: @creator.id, officers: [member])
    inventory = fleet.fleet_inventories.create!(name: "Main Hangar", visibility: :members_only)

    fleet.discard

    assert fleet.discarded?
    assert_equal 2, fleet.fleet_memberships.count
    assert_equal 3, fleet.fleet_roles.count
    assert FleetInventory.exists?(inventory.id)
  end

  test "undiscarding restores the fleet" do
    fleet = create(:fleet, created_by: @creator.id)
    fleet.discard
    assert_not Fleet.kept.exists?(fleet.id)

    fleet.undiscard

    assert Fleet.kept.exists?(fleet.id)
  end

  test "a new fleet can reuse a discarded fleet's fid" do
    fleet = create(:fleet, created_by: @creator.id, fid: "REUSE")
    fleet.discard

    other = build(:fleet, created_by: @creator.id, fid: "REUSE")

    assert other.valid?, other.errors.full_messages.to_sentence
    assert other.save
  end
end

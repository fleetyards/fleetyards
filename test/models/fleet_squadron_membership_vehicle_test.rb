# frozen_string_literal: true

require "test_helper"

class FleetSquadronMembershipVehicleTest < ActiveSupport::TestCase
  setup do
    @member = create(:user)
    @fleet = create(:fleet, members: [@member])
    @row = create(:fleet_squadron_membership, fleet_squadron: create(:fleet_squadron, fleet: @fleet),
      fleet_membership: @fleet.fleet_memberships.find_by!(user: @member))
  end

  test "takes the member's own ship" do
    assert @row.fleet_squadron_membership_vehicles.new(vehicle: create(:vehicle, user: @member)).valid?
  end

  test "refuses somebody else's ship" do
    picked = @row.fleet_squadron_membership_vehicles.new(vehicle: create(:vehicle))

    assert_not picked.valid?
    assert_includes picked.errors.details[:vehicle], {error: :not_owned}
  end
end

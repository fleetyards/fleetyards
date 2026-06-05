# frozen_string_literal: true

require "test_helper"

module Updater
  class FleetMembershipVehiclesUpdateJobTest < ActiveJob::TestCase
    test "#perform calls update_fleet_vehicles on the fleet membership" do
      user = create(:user)
      fleet = create(:fleet, members: [user])
      fleet_membership = fleet.fleet_memberships.first

      fleet_membership.expects(:update_fleet_vehicles)
      FleetMembership.stubs(:find_by).with(id: fleet_membership.id).returns(fleet_membership)

      ::Updater::FleetMembershipVehiclesUpdateJob.new.perform(fleet_membership.id)
    end

    test "#perform does nothing when fleet membership is not found" do
      assert_nothing_raised do
        ::Updater::FleetMembershipVehiclesUpdateJob.new.perform(SecureRandom.uuid)
      end
    end
  end
end

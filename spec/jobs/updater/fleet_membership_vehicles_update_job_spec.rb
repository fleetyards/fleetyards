# frozen_string_literal: true

require "rails_helper"

RSpec.describe Updater::FleetMembershipVehiclesUpdateJob do
  describe "#perform" do
    it "calls update_fleet_vehicles on the fleet membership" do
      user = create(:user)
      fleet = create(:fleet, members: [user])
      fleet_membership = fleet.fleet_memberships.first

      allow(fleet_membership).to receive(:update_fleet_vehicles)
      allow(FleetMembership).to receive(:find_by).with(id: fleet_membership.id).and_return(fleet_membership)

      described_class.new.perform(fleet_membership.id)

      expect(fleet_membership).to have_received(:update_fleet_vehicles)
    end

    it "does nothing when fleet membership is not found" do
      expect { described_class.new.perform(SecureRandom.uuid) }.not_to raise_error
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Updater::FleetVehicleUpdateJob do
  describe "#perform" do
    it "calls update_fleet_vehicle on the vehicle" do
      vehicle = double("Vehicle")
      allow(Vehicle).to receive(:find_by).with(id: "some-uuid").and_return(vehicle)
      allow(vehicle).to receive(:update_fleet_vehicle)

      described_class.new.perform("some-uuid")

      expect(vehicle).to have_received(:update_fleet_vehicle)
    end

    it "does nothing when vehicle is not found" do
      allow(Vehicle).to receive(:find_by).with(id: "missing-uuid").and_return(nil)

      expect { described_class.new.perform("missing-uuid") }.not_to raise_error
    end
  end
end

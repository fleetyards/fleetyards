# frozen_string_literal: true

require "test_helper"

module Updater
  class FleetVehicleUpdateJobTest < ActiveJob::TestCase
    test "#perform calls update_fleet_vehicle on the vehicle" do
      vehicle = mock("Vehicle")
      vehicle.expects(:update_fleet_vehicle)
      Vehicle.stubs(:find_by).with(id: "some-uuid").returns(vehicle)

      ::Updater::FleetVehicleUpdateJob.new.perform("some-uuid")
    end

    test "#perform does nothing when vehicle is not found" do
      Vehicle.stubs(:find_by).with(id: "missing-uuid").returns(nil)

      assert_nothing_raised do
        ::Updater::FleetVehicleUpdateJob.new.perform("missing-uuid")
      end
    end
  end
end

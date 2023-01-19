# frozen_string_literal: true

require 'test_helper'

class VehicleTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:model)
  should belong_to(:model_paint).optional(true)
  should belong_to(:module_package).optional(true)

  let(:raven) { vehicles :raven }
  let(:hangargroup) { hangar_groups :hangargroupone }

  describe '#schedule_fleet_vehicle_update' do
    it 'enqueues update job on purchase change' do
      raven.update(purchased: !raven.purchased)

      assert_equal 1, Updater::FleetVehicleUpdateJob.jobs.size
    end

    it 'does not enqueues update job if vehicle is hidden' do
      raven.update(hidden: true)

      raven.update(purchased: !raven.purchased)

      assert_equal 0, Updater::FleetVehicleUpdateJob.jobs.size
    end
  end
end

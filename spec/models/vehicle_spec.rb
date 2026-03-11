# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vehicle, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:model) }
  it { is_expected.to belong_to(:model_paint).optional(true) }
  it { is_expected.to belong_to(:module_package).optional(true) }

  describe "#schedule_fleet_vehicle_update" do
    let(:vehicle) { create(:vehicle) }

    before do
      vehicle
      Sidekiq::Worker.clear_all
    end

    it "enqueues update job on purchase change" do
      vehicle.update!(wanted: !vehicle.wanted)

      expect(Updater::FleetVehicleUpdateJob.jobs.size).to be >= 1
    end

    it "does not enqueue update job if vehicle is hidden" do
      vehicle.update!(hidden: true)
      Sidekiq::Worker.clear_all

      vehicle.update!(wanted: !vehicle.wanted)

      expect(Updater::FleetVehicleUpdateJob.jobs.size).to eq(0)
    end
  end
end

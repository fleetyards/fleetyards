# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskForce, type: :model do
  it { is_expected.to belong_to(:vehicle) }
  it { is_expected.to belong_to(:hangar_group) }

  describe "#schedule_fleet_vehicle_update" do
    let(:vehicle) { create(:vehicle) }
    let(:hangar_group) { create(:hangar_group, user: vehicle.user) }

    before do
      vehicle
      hangar_group
      Sidekiq::Worker.clear_all
    end

    it "enqueues update job on task_force create" do
      TaskForce.create(vehicle: vehicle, hangar_group: hangar_group)

      expect(Updater::FleetVehicleUpdateJob.jobs.size).to eq(1)
    end

    it "enqueues update job on task_force destroy" do
      taskforce = TaskForce.create(vehicle: vehicle, hangar_group: hangar_group)
      Sidekiq::Worker.clear_all

      Updater::FleetVehicleUpdateJob.drain

      expect(Updater::FleetVehicleUpdateJob.jobs.size).to eq(0)

      taskforce.destroy

      expect(Updater::FleetVehicleUpdateJob.jobs.size).to eq(1)
    end
  end
end

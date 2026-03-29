# frozen_string_literal: true

# == Schema Information
#
# Table name: task_forces
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  hangar_group_id :uuid
#  vehicle_id      :uuid
#
# Indexes
#
#  index_task_forces_on_hangar_group_id  (hangar_group_id)
#  index_task_forces_on_vehicle_id       (vehicle_id)
#
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

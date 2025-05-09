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
require "test_helper"

class TaskForceTest < ActiveSupport::TestCase
  fixtures :vehicles, :hangar_groups

  should belong_to(:vehicle)
  should belong_to(:hangar_group)

  let(:enterprise) { vehicles :enterprise }
  let(:hangargroup) { hangar_groups :hangargroupone }

  describe "#schedule_fleet_vehicle_update" do
    it "enqueues update job on task_force create" do
      TaskForce.create(vehicle_id: enterprise.id, hangar_group_id: hangargroup.id)

      assert_equal 1, Updater::FleetVehicleUpdateJob.jobs.size
    end

    it "enqueues update job on task_force destroy" do
      taskforce = TaskForce.create(vehicle_id: enterprise.id, hangar_group_id: hangargroup.id)

      assert_equal 1, Updater::FleetVehicleUpdateJob.jobs.size

      Updater::FleetVehicleUpdateJob.drain

      assert_equal 0, Updater::FleetVehicleUpdateJob.jobs.size

      taskforce.destroy

      assert_equal 1, Updater::FleetVehicleUpdateJob.jobs.size
    end
  end
end

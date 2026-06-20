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
  should belong_to(:vehicle)
  should belong_to(:hangar_group)

  setup do
    @vehicle = create(:vehicle)
    @hangar_group = create(:hangar_group, user: @vehicle.user)
    Sidekiq::Worker.clear_all
  end

  test "#schedule_fleet_vehicle_update enqueues update job on task_force create" do
    TaskForce.create(vehicle: @vehicle, hangar_group: @hangar_group)

    assert_equal 1, Updater::FleetVehicleUpdateJob.jobs.size
  end

  test "#schedule_fleet_vehicle_update enqueues update job on task_force destroy" do
    taskforce = TaskForce.create(vehicle: @vehicle, hangar_group: @hangar_group)
    Sidekiq::Worker.clear_all

    Updater::FleetVehicleUpdateJob.drain

    assert_equal 0, Updater::FleetVehicleUpdateJob.jobs.size

    taskforce.destroy

    assert_equal 1, Updater::FleetVehicleUpdateJob.jobs.size
  end
end

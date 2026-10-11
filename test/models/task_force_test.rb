# frozen_string_literal: true

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

  test "refreshes the fleet entries of the vehicle's visible loaners" do
    loaner_model = create(:model)
    parent_model = create(:model).tap { |model| model.loaners << loaner_model }
    parent = create(:vehicle, model: parent_model, user: @vehicle.user, wanted: false)
    loaner = Vehicle.find_by!(loaner: true, vehicle_id: parent.id)
    Sidekiq::Worker.clear_all

    task_force = TaskForce.create!(vehicle: parent, hangar_group: @hangar_group)

    assert_includes Updater::FleetVehicleUpdateJob.jobs.map { |job| job["args"].first }, loaner.id

    Sidekiq::Worker.clear_all
    task_force.destroy!

    assert_includes Updater::FleetVehicleUpdateJob.jobs.map { |job| job["args"].first }, loaner.id
  end

  test "leaves a hidden loaner's fleet entry alone" do
    loaner_model = create(:model)
    parent_model = create(:model).tap { |model| model.loaners << loaner_model }
    parent = create(:vehicle, model: parent_model, user: @vehicle.user, wanted: false)
    loaner = Vehicle.find_by!(loaner: true, vehicle_id: parent.id)
    loaner.update_columns(hidden: true)
    Sidekiq::Worker.clear_all

    TaskForce.create!(vehicle: parent, hangar_group: @hangar_group)

    assert_not_includes Updater::FleetVehicleUpdateJob.jobs.map { |job| job["args"].first }, loaner.id
  end
end

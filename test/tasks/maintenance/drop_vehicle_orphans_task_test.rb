# frozen_string_literal: true

require "test_helper"

module Maintenance
  class DropVehicleOrphansTaskTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @kept = create(:vehicle, user: @user)
    end

    # An accidental run has to report rather than destroy, so the safe mode is
    # the one you get by not choosing.
    test "dry_run is on unless it is turned off" do
      assert_predicate ::Maintenance::DropVehicleOrphansTask.new, :dry_run
    end

    test "#process leaves every row in place on a dry run" do
      orphan_vehicle
      orphan_fleet_vehicle
      orphan_task_force

      assert_no_difference [-> { Vehicle.count }, -> { FleetVehicle.count }, -> { TaskForce.count }] do
        run_task(dry_run: true)
      end
    end

    test "#process reports what it would do on a dry run" do
      orphan = orphan_vehicle
      FleetVehicle.create!(fleet: create(:fleet), vehicle: orphan)
      orphan_fleet_vehicle
      orphan_task_force

      output = run_task(dry_run: true)

      assert_includes output, "vehicles: 1 orphaned of #{Vehicle.count}, 1 visible, across 1 users"
      assert_includes output, "fleet_vehicles: 1 orphaned of #{FleetVehicle.count}, plus 1 carried by those vehicles"
      assert_includes output, "task_forces: 1 orphaned of #{TaskForce.count}, plus 0 carried by those vehicles"
      assert_includes output, "dry run"
    end

    test "#process drops a vehicle whose parent is gone" do
      orphan = orphan_vehicle

      run_task(dry_run: false)

      assert_nil Vehicle.find_by(id: orphan.id)
      assert Vehicle.exists?(@kept.id)
    end

    test "#process drops the rows an orphaned vehicle carries" do
      orphan = orphan_vehicle
      carried = FleetVehicle.create!(fleet: create(:fleet), vehicle: orphan)
      loadout = create(:vehicle_loadout, vehicle: orphan)

      run_task(dry_run: false)

      assert_nil FleetVehicle.find_by(id: carried.id)
      assert_nil VehicleLoadout.find_by(id: loadout.id)
    end

    test "#process drops join rows pointing at a vehicle that is gone" do
      fleet_vehicle = orphan_fleet_vehicle
      task_force = orphan_task_force

      run_task(dry_run: false)

      assert_nil FleetVehicle.find_by(id: fleet_vehicle.id)
      assert_nil TaskForce.find_by(id: task_force.id)
    end

    test "#process keeps the rows of a vehicle that still has its parent" do
      loaner_model = create(:model)
      parent_model = create(:model).tap { |model| model.loaners << loaner_model }
      parent = create(:vehicle, user: @user, model: parent_model)
      loaner = Vehicle.find_by!(loaner: true, vehicle_id: parent.id)
      fleet_vehicle = FleetVehicle.create!(fleet: create(:fleet), vehicle: loaner)
      task_force = TaskForce.create!(vehicle: @kept, hangar_group: create(:hangar_group, user: @user))

      run_task(dry_run: false)

      assert Vehicle.exists?(loaner.id)
      assert FleetVehicle.exists?(fleet_vehicle.id)
      assert TaskForce.exists?(task_force.id)
    end

    test "#process drops every orphan, not just the first batch" do
      3.times { orphan_vehicle }
      3.times { orphan_fleet_vehicle }

      run_task(dry_run: false)

      assert_empty ::Maintenance::DropVehicleOrphansTask.orphaned_vehicles
      assert_empty ::Maintenance::DropVehicleOrphansTask.orphaned_fleet_vehicles
    end

    # A loaner left standing by a bulk delete: the row is intact, the parent it
    # names is not.
    private def orphan_vehicle
      parent = create(:vehicle, user: @user)
      orphan = create(:vehicle, :loaner, user: @user, vehicle_id: parent.id)
      Vehicle.where(id: parent.id).delete_all

      orphan
    end

    private def orphan_fleet_vehicle
      vehicle = create(:vehicle, user: @user)
      fleet_vehicle = FleetVehicle.create!(fleet: create(:fleet), vehicle: vehicle)
      Vehicle.where(id: vehicle.id).delete_all

      fleet_vehicle
    end

    private def orphan_task_force
      vehicle = create(:vehicle, user: @user)
      task_force = TaskForce.create!(vehicle: vehicle, hangar_group: create(:hangar_group, user: @user))
      Vehicle.where(id: vehicle.id).delete_all

      task_force
    end

    private def run_task(dry_run:)
      task = ::Maintenance::DropVehicleOrphansTask.new
      task.dry_run = dry_run

      capture_io { task.process }.first
    end
  end
end

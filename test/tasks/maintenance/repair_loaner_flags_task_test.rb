# frozen_string_literal: true

require "test_helper"

module Maintenance
  class RepairLoanerFlagsTaskTest < ActiveSupport::TestCase
    setup do
      @task = ::Maintenance::RepairLoanerFlagsTask.new
      @user = create(:user)
      @loaner_model = create(:model)
      @parent_model = create(:model).tap { |m| m.loaners << @loaner_model }
    end

    test "#collection is the users owning a loaner and nobody else" do
      create(:vehicle, user: @user, model: @parent_model, wanted: false)
      without_loaners = create(:user)

      ids = @task.collection.pluck(:id)

      assert_includes ids, @user.id
      assert_not_includes ids, without_loaners.id
    end

    # The stranded row the old lookup left behind: it claims the hangar while the
    # ship it hangs off is wishlisted, which is what let it reach a fleet.
    test "#process realigns a loaner whose wanted disagrees with its parent" do
      parent = create(:vehicle, user: @user, model: @parent_model, wanted: true)
      loaner = Vehicle.find_by(loaner: true, vehicle_id: parent.id)
      loaner.update_columns(wanted: false)

      @task.process(@user)

      assert_equal true, loaner.reload.wanted
    end

    test "#process leaves an orphaned loaner alone" do
      orphan = create(:vehicle, :loaner, user: @user, model: @loaner_model, wanted: false)
      orphan.update_columns(vehicle_id: nil)

      @task.process(@user)

      assert_nil orphan.reload.vehicle_id
      assert_equal false, orphan.wanted
    end

    # The self-hit: a sole loaner answered "a visible loaner already exists"
    # about itself and hid itself.
    test "#process unhides a sole loaner" do
      parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)
      loaner = Vehicle.find_by(loaner: true, vehicle_id: parent.id)
      loaner.update_columns(hidden: true)

      @task.process(@user)

      assert_equal false, loaner.reload.hidden
    end

    test "#process leaves exactly one loaner of a model visible" do
      other_parent_model = create(:model).tap { |m| m.loaners << @loaner_model }
      create(:vehicle, user: @user, model: @parent_model, wanted: false)
      create(:vehicle, user: @user, model: other_parent_model, wanted: false)
      Vehicle.where(loaner: true, user_id: @user.id).update_all(hidden: false)

      @task.process(@user)

      loaners = Vehicle.where(loaner: true, user_id: @user.id, model_id: @loaner_model.id)
      assert_equal 2, loaners.count
      assert_equal 1, loaners.where(hidden: false).count
    end

    # Hangar and wishlist are separate lists, so one of each stays visible.
    test "#process keeps a visible loaner per wanted state" do
      other_parent_model = create(:model).tap { |m| m.loaners << @loaner_model }
      create(:vehicle, user: @user, model: @parent_model, wanted: false)
      create(:vehicle, user: @user, model: other_parent_model, wanted: true)

      @task.process(@user)

      loaners = Vehicle.where(loaner: true, user_id: @user.id, model_id: @loaner_model.id)
      assert_equal 1, loaners.where(hidden: false, wanted: false).count
      assert_equal 1, loaners.where(hidden: false, wanted: true).count
    end

    test "#process does not move which loaner is visible when the group is already correct" do
      other_parent_model = create(:model).tap { |m| m.loaners << @loaner_model }
      create(:vehicle, user: @user, model: @parent_model, wanted: false)
      create(:vehicle, user: @user, model: other_parent_model, wanted: false)
      visible_before = Vehicle.find_by(loaner: true, user_id: @user.id, hidden: false)

      @task.process(@user)

      assert_equal visible_before.id, Vehicle.find_by(loaner: true, user_id: @user.id, hidden: false).id
    end

    test "#process is idempotent" do
      parent = create(:vehicle, user: @user, model: @parent_model, wanted: true)
      Vehicle.find_by(loaner: true, vehicle_id: parent.id).update_columns(wanted: false, hidden: true)

      @task.process(@user)
      first_pass = Vehicle.where(loaner: true, user_id: @user.id).pluck(:id, :wanted, :hidden).sort

      @task.process(@user)

      assert_equal first_pass, Vehicle.where(loaner: true, user_id: @user.id).pluck(:id, :wanted, :hidden).sort
    end

    test "#process schedules a fleet update for every row it touches" do
      parent = create(:vehicle, user: @user, model: @parent_model, wanted: true)
      loaner = Vehicle.find_by(loaner: true, vehicle_id: parent.id)
      loaner.update_columns(wanted: false)

      Updater::FleetVehicleUpdateJob.jobs.clear
      @task.process(@user)

      assert_includes Updater::FleetVehicleUpdateJob.jobs.map { |job| job["args"].first }, loaner.id
    end

    test "#process schedules nothing when there is nothing to repair" do
      create(:vehicle, user: @user, model: @parent_model, wanted: false)

      Updater::FleetVehicleUpdateJob.jobs.clear
      @task.process(@user)

      assert_empty Updater::FleetVehicleUpdateJob.jobs
    end
  end
end

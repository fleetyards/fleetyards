# frozen_string_literal: true

require "test_helper"

class FleetMembershipTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:fleet)

  setup do
    @admin_user = create(:user)
    @member_user = create(:user)
    @fleet = create(:fleet, admins: [@admin_user], members: [@member_user])
    @admin_membership = @fleet.fleet_memberships.find_by(user: @admin_user)
    @member_membership = @fleet.fleet_memberships.find_by(user: @member_user)
  end

  test "#has_access? delegates to fleet_role when present" do
    assert @admin_membership.has_access?(["fleet:manage"])
  end

  test "#has_access? returns false when fleet_role is nil" do
    @admin_membership.update_columns(fleet_role_id: nil)
    refute @admin_membership.reload.has_access?(["fleet:manage"])
  end

  test "#schedule_setup_fleet_vehicles enqueues setup job on accept_request" do
    Sidekiq::Worker.clear_all
    other_user = create(:user)
    membership = FleetMembership.create(fleet_id: @fleet.id, user_id: other_user.id, aasm_state: :requested)
    Sidekiq::Worker.clear_all

    membership.accept_request!

    assert_equal 1, Updater::FleetMembershipVehiclesUpdateJob.jobs.size
  end

  test "#schedule_setup_fleet_vehicles enqueues setup job on accept_invitation" do
    Sidekiq::Worker.clear_all
    other_user = create(:user)
    membership = FleetMembership.create(fleet_id: @fleet.id, user_id: other_user.id, aasm_state: :invited)
    Sidekiq::Worker.clear_all

    membership.accept_invitation!

    assert_equal 1, Updater::FleetMembershipVehiclesUpdateJob.jobs.size
  end

  test "#schedule_update_fleet_vehicles enqueues update job" do
    Sidekiq::Worker.clear_all
    @admin_membership.update(ships_filter: :hide)
    assert_equal 1, Updater::FleetMembershipVehiclesUpdateJob.jobs.size
  end

  test "#schedule_update_fleet_vehicles does not enqueue setup job when ships_filter did not change" do
    Sidekiq::Worker.clear_all
    @admin_membership.update(primary: !@admin_membership.primary)
    assert_equal 0, Updater::FleetMembershipVehiclesSetupJob.jobs.size
  end

  test "#remove_fleet_vehicles removes all relevant fleet_vehicles" do
    other_user = create(:user)
    other_user.vehicles.create(model: create(:model), wanted: false)
    new_membership = FleetMembership.create!(fleet_id: @fleet.id, user_id: other_user.id, aasm_state: :accepted)

    Updater::FleetMembershipVehiclesSetupJob.drain

    assert_operator new_membership.fleet.fleet_vehicles.count, :>=, 1

    assert_difference -> { new_membership.fleet.fleet_vehicles.count }, -1 do
      new_membership.destroy
    end
  end
end

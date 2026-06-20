# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_memberships
#
#  id                :uuid             not null, primary key
#  aasm_state        :string
#  accepted_at       :datetime
#  declined_at       :datetime
#  hide_ships        :boolean          default(FALSE)
#  invited_at        :datetime
#  invited_by        :uuid
#  primary           :boolean          default(FALSE)
#  requested_at      :datetime
#  ships_filter      :integer          default("all")
#  used_invite_token :string
#  verified          :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_id          :uuid
#  fleet_role_id     :uuid
#  hangar_group_id   :uuid
#  user_id           :uuid
#
# Indexes
#
#  index_fleet_memberships_on_fleet_role_id         (fleet_role_id)
#  index_fleet_memberships_on_user_id_and_fleet_id  (user_id,fleet_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_role_id => fleet_roles.id)
#
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

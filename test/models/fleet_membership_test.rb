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
#  role              :integer
#  ships_filter      :integer          default("all")
#  used_invite_token :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_id          :uuid
#  hangar_group_id   :uuid
#  user_id           :uuid
#
# Indexes
#
#  index_fleet_memberships_on_user_id_and_fleet_id  (user_id,fleet_id) UNIQUE
#
require "test_helper"

class FleetMembershipTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:fleet)

  let(:fleet) { fleets :starfleet }
  let(:membership) { fleet_memberships :starfleet_picard }
  let(:user) { users :troi }

  describe "#schedule_setup_fleet_vehicles" do
    it "enqueues update setup_fleet_vehicles job on on_accept_request" do
      membership = FleetMembership.create(fleet_id: fleet.id, user_id: user.id, aasm_state: :requested)

      membership.accept_request!

      assert_equal 1, Updater::FleetMembershipVehiclesUpdateJob.jobs.size
    end

    it "enqueues update setup_fleet_vehicles job on on_accept_invitation" do
      membership = FleetMembership.create(fleet_id: fleet.id, user_id: user.id, aasm_state: :invited)

      membership.accept_invitation!

      assert_equal 1, Updater::FleetMembershipVehiclesUpdateJob.jobs.size
    end
  end

  describe "#schedule_update_fleet_vehicles" do
    it "enqueues update update_fleet_vehicles job" do
      membership.update(ships_filter: :hide)

      assert_equal 1, Updater::FleetMembershipVehiclesUpdateJob.jobs.size
    end

    it "does not enqueue setup_fleet_vehicles job when ships_filter did not change" do
      membership.update(primary: !membership.primary)

      assert_equal 0, Updater::FleetMembershipVehiclesSetupJob.jobs.size
    end
  end

  describe "#remove_fleet_vehicles" do
    it "removes all relevant fleet_vehicles" do
      user.vehicles.create(model_id: Model.first.id, wanted: false)
      new_fleet_membership = FleetMembership.create!(fleet_id: fleet.id, user_id: user.id, aasm_state: :accepted)

      assert_equal 1, Updater::FleetMembershipVehiclesSetupJob.jobs.size

      Updater::FleetMembershipVehiclesSetupJob.drain

      assert_difference -> { new_fleet_membership.fleet.fleet_vehicles.count }, -4 do
        new_fleet_membership.destroy
      end
    end
  end
end

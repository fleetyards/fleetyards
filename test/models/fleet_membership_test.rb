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
#  ships_filter      :integer          default("purchased")
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
require 'test_helper'

class FleetMembershipTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  should belong_to(:user)
  should belong_to(:fleet)

  let(:fleet) { fleets :starfleet }
  let(:membership) { fleet_memberships :starfleet_picard }
  let(:user) { users :troi }

  describe '#schedule_setup_fleet_vehicles' do
    it 'enqueues update setup_fleet_vehicles job on on_accept_request' do
      membership = FleetMembership.create(fleet_id: fleet.id, user_id: user.id, aasm_state: :requested)
      assert_enqueued_with(job: Updater::FleetMembershipVehiclesUpdateJob) do
        membership.accept_request!
      end
    end

    it 'enqueues update setup_fleet_vehicles job on on_accept_invitation' do
      membership = FleetMembership.create(fleet_id: fleet.id, user_id: user.id, aasm_state: :invited)
      assert_enqueued_with(job: Updater::FleetMembershipVehiclesUpdateJob) do
        membership.accept_invitation!
      end
    end
  end

  describe '#schedule_update_fleet_vehicles' do
    it 'enqueues update update_fleet_vehicles job' do
      assert_enqueued_with(job: Updater::FleetMembershipVehiclesUpdateJob) do
        membership.update(ships_filter: :hide)
      end
    end

    it 'does not enqueue setup_fleet_vehicles job when ships_filter did not change' do
      assert_no_enqueued_jobs(only: Updater::FleetMembershipVehiclesSetupJob) do
        membership.update(primary: !membership.primary)
      end
    end
  end

  describe '#remove_fleet_vehicles' do
    it 'removes all relevant fleet_vehicles' do
      user.vehicles.create(model_id: Model.first.id, purchased: true)
      new_fleet_membership = FleetMembership.create!(fleet_id: fleet.id, user_id: user.id, aasm_state: :accepted)

      perform_enqueued_jobs

      assert_difference -> { new_fleet_membership.fleet.fleet_vehicles.count }, -1 do
        new_fleet_membership.destroy
      end
    end
  end
end

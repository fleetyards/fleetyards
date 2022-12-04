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
    it 'enqueues update setup_fleet_vehicles job' do
      assert_enqueued_with(job: Updater::FleetMembershipVehiclesSetupJob) do
        FleetMembership.create(fleet_id: fleet.id, user_id: user.id)
      end
    end

    it 'does not enqueue setup_fleet_vehicles job when ships_filter is hide' do
      assert_no_enqueued_jobs(only: Updater::FleetMembershipVehiclesSetupJob) do
        FleetMembership.create(fleet_id: fleet.id, user_id: user.id, ships_filter: :hide)
      end
    end
  end

  describe '#schedule_update_fleet_vehicles' do
    it 'enqueues update update_fleet_vehicles job' do
      assert_enqueued_with(job: Updater::FleetMembershipVehiclesUpdateJob) do
        membership.update(ships_filter: :hide)
      end
    end
  end

  describe '#schedule_remove_fleet_vehicles' do
    it 'enqueues update remove_fleet_vehicles job' do
      new_fleet_membership = FleetMembership.create(fleet_id: fleet.id, user_id: user.id)

      assert_enqueued_with(job: Updater::FleetMembershipVehiclesRemoveJob) do
        new_fleet_membership.destroy
      end
    end
  end
end

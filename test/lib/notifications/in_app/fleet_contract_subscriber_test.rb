# frozen_string_literal: true

require "test_helper"

module Notifications
  module InApp
    class FleetContractSubscriberTest < ActiveSupport::TestCase
      setup do
        @officer = create(:user)
        @insider = create(:user)
        @outsider = create(:user)
        @fleet = create(:fleet, admins: [@officer], members: [@insider, @outsider])
        @squadron = create(:fleet_squadron, fleet: @fleet)
        create(:fleet_squadron_membership, fleet_squadron: @squadron,
          fleet_membership: @fleet.fleet_memberships.find_by!(user: @insider))
      end

      def deliver(event_name, payload)
        ::Notifications::InApp::FleetContractSubscriber.new(event_name, payload).call
      end

      # The announcement names the job, so a squadron's work is announced to
      # that squadron -- and to whoever runs the board, who reaches it anyway.
      test "announces a squadron contract to its squadron and to those who run the board" do
        contract = create(:fleet_contract, :published, fleet: @fleet,
          visibility: :squadron_only, fleet_squadrons: [@squadron])

        deliver("fleet_contract.published", contract:)

        notified = Notification.where(notification_type: "fleet_contract_published").pluck(:user_id)
        assert_includes notified, @insider.id
        assert_includes notified, @officer.id
        refute_includes notified, @outsider.id
      end

      test "announces a contract for the whole fleet to everyone who reads the board" do
        contract = create(:fleet_contract, :published, fleet: @fleet)

        deliver("fleet_contract.published", contract:)

        notified = Notification.where(notification_type: "fleet_contract_published").pluck(:user_id)
        assert_includes notified, @outsider.id
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Notifications
  module InApp
    class FleetEventSubscriberTest < ActiveSupport::TestCase
      setup do
        @admin = create(:user)
        @member = create(:user)
        @fleet = create(:fleet, admins: [@admin], members: [@member])
        @event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
        @team = create(:fleet_event_team, fleet_event: @event)
        @slot = create(:fleet_event_slot, slottable: @team)
        @other_slot = create(:fleet_event_slot, slottable: @team)
        @membership = @fleet.fleet_memberships.find_by(user: @member)
        @signup = create(:fleet_event_signup,
          fleet_event: @event,
          fleet_event_slot: @slot,
          fleet_membership: @membership,
          status: "confirmed")
      end

      def deliver(event_name, payload)
        ::Notifications::InApp::FleetEventSubscriber.new(event_name, payload).call
      end

      class StatusChangedTest < FleetEventSubscriberTest
        test "notifies the member when an admin approves a pending signup" do
          @signup.update!(status: "confirmed")
          assert_difference -> { Notification.where(user: @member, notification_type: "fleet_event_signup_confirmed").count }, 1 do
            deliver("fleet_event_signup.status_changed",
              signup: @signup, previous_status: "pending", by_admin: true)
          end
        end

        test "ignores member-side status changes" do
          assert_no_difference -> { Notification.count } do
            deliver("fleet_event_signup.status_changed",
              signup: @signup, previous_status: "tentative", by_admin: false)
          end
        end
      end

      class AssignedTest < FleetEventSubscriberTest
        test "notifies the member that they were moved" do
          @signup.update!(fleet_event_slot_id: @other_slot.id)
          assert_difference -> { Notification.where(user: @member, notification_type: "fleet_event_signup_assigned").count }, 1 do
            deliver("fleet_event_signup.assigned",
              signup: @signup, previous_slot_id: @slot.id)
          end
        end
      end

      class WithdrawnTest < FleetEventSubscriberTest
        test "notifies the kicked member as well as the event creator" do
          @signup.withdraw!
          assert_difference -> { Notification.where(user: @member, notification_type: "fleet_event_signup_kicked").count }, 1 do
            assert_difference -> { Notification.where(user: @admin, notification_type: "fleet_event_signup_withdrawn").count }, 1 do
              deliver("fleet_event_signup.withdrawn", signup: @signup, kicked: true)
            end
          end
        end

        test "only notifies the creator on a self-withdraw" do
          @signup.withdraw!
          assert_difference -> { Notification.where(user: @admin, notification_type: "fleet_event_signup_withdrawn").count }, 1 do
            deliver("fleet_event_signup.withdrawn", signup: @signup)
          end
          assert_empty Notification.where(user: @member, notification_type: "fleet_event_signup_kicked")
        end
      end
    end
  end
end

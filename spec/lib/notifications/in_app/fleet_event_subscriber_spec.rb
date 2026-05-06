# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::InApp::FleetEventSubscriber do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }
  let(:team) { create(:fleet_event_team, fleet_event: event) }
  let(:slot) { create(:fleet_event_slot, slottable: team) }
  let(:other_slot) { create(:fleet_event_slot, slottable: team) }
  let(:membership) { fleet.fleet_memberships.find_by(user: member) }
  let(:signup) do
    create(:fleet_event_signup,
      fleet_event: event,
      fleet_event_slot: slot,
      fleet_membership: membership,
      status: "confirmed")
  end

  def deliver(event_name, payload)
    described_class.new(event_name, payload).call
  end

  describe "fleet_event_signup.status_changed" do
    it "notifies the member when an admin approves a pending signup" do
      signup.update!(status: "confirmed")
      expect {
        deliver("fleet_event_signup.status_changed",
          signup: signup, previous_status: "pending", by_admin: true)
      }.to change { Notification.where(user: member, notification_type: "fleet_event_signup_confirmed").count }.by(1)
    end

    it "ignores member-side status changes" do
      expect {
        deliver("fleet_event_signup.status_changed",
          signup: signup, previous_status: "tentative", by_admin: false)
      }.not_to change(Notification, :count)
    end
  end

  describe "fleet_event_signup.assigned" do
    it "notifies the member that they were moved" do
      signup.update!(fleet_event_slot_id: other_slot.id)
      expect {
        deliver("fleet_event_signup.assigned",
          signup: signup, previous_slot_id: slot.id)
      }.to change { Notification.where(user: member, notification_type: "fleet_event_signup_assigned").count }.by(1)
    end
  end

  describe "fleet_event_signup.withdrawn (kicked)" do
    it "notifies the kicked member as well as the event creator" do
      signup.withdraw!
      expect {
        deliver("fleet_event_signup.withdrawn", signup: signup, kicked: true)
      }.to change { Notification.where(user: member, notification_type: "fleet_event_signup_kicked").count }.by(1)
        .and change { Notification.where(user: admin, notification_type: "fleet_event_signup_withdrawn").count }.by(1)
    end

    it "only notifies the creator on a self-withdraw" do
      signup.withdraw!
      expect {
        deliver("fleet_event_signup.withdrawn", signup: signup)
      }.to change { Notification.where(user: admin, notification_type: "fleet_event_signup_withdrawn").count }.by(1)
      expect(Notification.where(user: member, notification_type: "fleet_event_signup_kicked")).to be_empty
    end
  end
end

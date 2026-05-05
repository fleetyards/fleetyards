# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FleetEventSignup upsert flows", type: :request do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }
  let(:team) { create(:fleet_event_team, fleet_event: event) }
  let(:slot) { create(:fleet_event_slot, slottable: team) }

  before do
    Flipper.enable("mission_builder")
    sign_in(member)
  end

  describe "POST /api/v1/fleets/:fleet/events/:slug/signup" do
    let(:url) { "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/signup" }

    it "creates an interested signup by default" do
      post url, params: {}, as: :json
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["status"]).to eq("interested")
    end

    it "upserts an existing event-level signup to a different status" do
      post url, params: {status: "interested"}, as: :json
      expect(response).to have_http_status(:created)

      post url, params: {status: "tentative"}, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("tentative")

      membership = fleet.fleet_memberships.find_by(user: member)
      expect(event.fleet_event_signups.where(fleet_membership: membership).where.not(status: "withdrawn").count).to eq(1)
    end

    it "returns 409 when the member is already in a slot" do
      membership = fleet.fleet_memberships.find_by(user: member)
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: slot, fleet_membership: membership, status: "confirmed")

      post url, params: {status: "interested"}, as: :json
      expect(response).to have_http_status(:conflict)
    end
  end

  describe "POST /api/v1/fleet-event-slots/:id/signup" do
    let(:url) { "/api/v1/fleet-event-slots/#{slot.id}/signup" }

    it "promotes an existing event-level signup onto the slot" do
      post "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/signup", params: {status: "interested"}, as: :json
      expect(response).to have_http_status(:created)

      post url, params: {status: "confirmed"}, as: :json
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["status"]).to eq("confirmed")
      expect(data["fleetEventSlotId"]).to eq(slot.id)

      membership = fleet.fleet_memberships.find_by(user: member)
      expect(event.fleet_event_signups.where(fleet_membership: membership).where.not(status: "withdrawn").count).to eq(1)
    end

    it "coerces tentative requests to confirmed when binding to a slot" do
      post url, params: {status: "tentative"}, as: :json
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["status"]).to eq("confirmed")
    end

    it "returns 409 when the member is already in a different slot" do
      other_slot = create(:fleet_event_slot, slottable: team)
      membership = fleet.fleet_memberships.find_by(user: member)
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: other_slot, fleet_membership: membership, status: "confirmed")

      post url, params: {status: "confirmed"}, as: :json
      expect(response).to have_http_status(:conflict)
    end

    it "rejects signups when the event is past" do
      event.update!(starts_at: 2.hours.ago, ends_at: 1.hour.ago)

      post url, params: {status: "confirmed"}, as: :json
      expect(response).to have_http_status(:forbidden).or have_http_status(:bad_request)
    end
  end

  describe "PATCH /api/v1/fleet-event-signups/:id/assign (admin)" do
    let(:other_member) { create(:user) }
    let!(:other_membership) { create(:fleet_membership, fleet: fleet, user: other_member, aasm_state: "accepted") }
    let(:signup) do
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: nil, fleet_membership: other_membership, status: "interested")
    end

    before do
      sign_out(member)
      sign_in(admin)
    end

    it "assigns an unassigned signup to a slot and promotes it to confirmed" do
      patch "/api/v1/fleet-event-signups/#{signup.id}/assign",
        params: {fleetEventSlotId: slot.id},
        as: :json

      expect(response).to have_http_status(:ok), "got #{response.status}: #{response.body}"
      data = JSON.parse(response.body)
      expect(data["fleetEventSlotId"]).to eq(slot.id)
      expect(data["status"]).to eq("confirmed")
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Signing up for a recurring event", type: :request do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:event) do
    create(:fleet_event, :open,
      fleet: fleet, created_by: admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
  end

  before do
    Flipper.enable("mission_builder")
    sign_in member
  end

  it "requires an occurrence_date for recurring events" do
    post "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/signup",
      params: {status: "interested"}, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["code"]).to eq("missing_occurrence_date")
  end

  it "stores the occurrence_date on the signup" do
    post "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/signup",
      params: {status: "interested", occurrenceDate: "2026-05-21"},
      as: :json

    expect(response).to have_http_status(:created), response.body
    membership = fleet.fleet_memberships.find_by(user: member)
    signup = FleetEventSignup.find_by(
      fleet_event_id: event.id, fleet_membership_id: membership.id
    )
    expect(signup.occurrence_date).to eq(Date.parse("2026-05-21"))
  end

  it "allows the same member to sign up for two different occurrences" do
    post "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/signup",
      params: {status: "interested", occurrenceDate: "2026-05-21"},
      as: :json
    expect(response).to have_http_status(:created)

    post "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/signup",
      params: {status: "interested", occurrenceDate: "2026-05-28"},
      as: :json
    expect(response).to have_http_status(:created)

    membership = fleet.fleet_memberships.find_by(user: member)
    expect(FleetEventSignup.where(
      fleet_event_id: event.id, fleet_membership_id: membership.id
    ).count).to eq(2)
  end
end

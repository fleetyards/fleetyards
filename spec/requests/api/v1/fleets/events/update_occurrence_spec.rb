# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PATCH /api/v1/fleets/:fleet/events/:slug/update-occurrence", type: :request do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:event) do
    create(:fleet_event, :open,
      fleet: fleet, created_by: admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC", location: "Stanton",
      recurring: true, recurrence_interval: "weekly")
  end

  before do
    Flipper.enable("mission_builder")
    sign_in admin
  end

  it "creates a per-occurrence state row with the override fields" do
    patch "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/update-occurrence",
      params: {date: "2026-05-21", location: "Levski", scenario: "Bunker raid"},
      as: :json

    expect(response).to have_http_status(:ok), response.body
    state = event.reload.fleet_event_occurrence_states.find_by(
      occurrence_date: Date.parse("2026-05-21")
    )
    expect(state.location).to eq("Levski")
    expect(state.scenario).to eq("Bunker raid")
  end

  it "updates an existing state row" do
    create(:fleet_event_occurrence_state,
      fleet_event: event, occurrence_date: Date.parse("2026-05-21"),
      location: "Levski")

    patch "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/update-occurrence",
      params: {date: "2026-05-21", location: "Yela"},
      as: :json

    expect(response).to have_http_status(:ok), response.body
    expect(event.fleet_event_occurrence_states.first.reload.location).to eq("Yela")
  end

  it "rejects when the event is not recurring" do
    one_off = create(:fleet_event, :open, fleet: fleet, created_by: admin)

    patch "/api/v1/fleets/#{fleet.slug}/events/#{one_off.slug}/update-occurrence",
      params: {date: "2026-05-21", location: "Levski"},
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "rejects when date is missing" do
    patch "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/update-occurrence",
      params: {location: "Levski"},
      as: :json

    expect(response).to have_http_status(:bad_request)
  end
end

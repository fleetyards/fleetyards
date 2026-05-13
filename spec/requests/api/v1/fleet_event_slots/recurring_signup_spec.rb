# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recurring slot signups", type: :request do
  let(:admin) { create(:user) }
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [alice, bob]) }
  let(:event) do
    create(:fleet_event, :open,
      fleet: fleet, created_by: admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
  end
  let(:team) { create(:fleet_event_team, fleet_event: event) }
  let(:slot) { create(:fleet_event_slot, slottable: team, title: "Pilot") }

  before { Flipper.enable("mission_builder") }

  it "allows two different members in the same slot on different occurrences" do
    sign_in alice
    post "/api/v1/fleet-event-slots/#{slot.id}/signup",
      params: {status: "confirmed", occurrenceDate: "2026-05-21"},
      as: :json
    expect(response).to have_http_status(:created), response.body

    sign_out alice
    sign_in bob
    post "/api/v1/fleet-event-slots/#{slot.id}/signup",
      params: {status: "confirmed", occurrenceDate: "2026-05-28"},
      as: :json
    expect(response).to have_http_status(:created), response.body

    expect(slot.fleet_event_signups.count).to eq(2)
  end

  it "still blocks two members claiming the same slot on the same occurrence" do
    sign_in alice
    post "/api/v1/fleet-event-slots/#{slot.id}/signup",
      params: {status: "confirmed", occurrenceDate: "2026-05-21"},
      as: :json
    expect(response).to have_http_status(:created)

    sign_out alice
    sign_in bob
    post "/api/v1/fleet-event-slots/#{slot.id}/signup",
      params: {status: "confirmed", occurrenceDate: "2026-05-21"},
      as: :json

    expect(response.status).to be_in([400, 422])
  end

  it "requires occurrenceDate for recurring slot signups" do
    sign_in alice
    post "/api/v1/fleet-event-slots/#{slot.id}/signup",
      params: {status: "confirmed"},
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end
end

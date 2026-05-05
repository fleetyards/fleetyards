# frozen_string_literal: true

require "rails_helper"

RSpec.describe "api/v1/fleets/events.ics", type: :request do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], calendar_feed_token: SecureRandom.hex(16)) }

  before { Flipper.enable("mission_builder") }

  context "with valid token" do
    it "returns an ICS feed" do
      create(:fleet_event, :open, fleet: fleet, created_by: admin, starts_at: 2.days.from_now)

      get "/api/v1/fleets/#{fleet.slug}/events.ics", params: {token: fleet.calendar_feed_token}

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/calendar")
      expect(response.body).to include("BEGIN:VCALENDAR")
      expect(response.body).to include("BEGIN:VEVENT")
      expect(response.body).to include("END:VCALENDAR")
    end

    it "skips cancelled events" do
      create(:fleet_event, :cancelled, fleet: fleet, created_by: admin, title: "Scrubbed Op")
      create(:fleet_event, :open, fleet: fleet, created_by: admin, title: "Live Op")

      get "/api/v1/fleets/#{fleet.slug}/events.ics", params: {token: fleet.calendar_feed_token}

      expect(response.body).to include("Live Op")
      expect(response.body).not_to include("Scrubbed Op")
    end
  end

  context "with invalid token" do
    it "returns forbidden" do
      get "/api/v1/fleets/#{fleet.slug}/events.ics", params: {token: "wrong"}

      expect(response).to have_http_status(:forbidden)
    end
  end
end

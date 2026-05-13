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

    it "includes recently cancelled events with STATUS:CANCELLED" do
      create(:fleet_event, :cancelled,
        fleet: fleet, created_by: admin, title: "Scrubbed Op",
        starts_at: 2.days.from_now)
      create(:fleet_event, :open, fleet: fleet, created_by: admin, title: "Live Op")

      get "/api/v1/fleets/#{fleet.slug}/events.ics", params: {token: fleet.calendar_feed_token}

      expect(response.body).to include("Live Op")
      expect(response.body).to include("Scrubbed Op")
      expect(response.body).to include("STATUS:CANCELLED")
    end

    it "drops cancelled events more than a week past their start time" do
      create(:fleet_event, :cancelled,
        fleet: fleet, created_by: admin, title: "Old Scrubbed Op",
        starts_at: 10.days.ago)

      get "/api/v1/fleets/#{fleet.slug}/events.ics", params: {token: fleet.calendar_feed_token}

      expect(response.body).not_to include("Old Scrubbed Op")
    end

    it "drops events older than the 90-day past horizon" do
      create(:fleet_event, :open,
        fleet: fleet, created_by: admin, title: "Ancient Op",
        starts_at: 100.days.ago)
      create(:fleet_event, :open,
        fleet: fleet, created_by: admin, title: "Recent Op",
        starts_at: 30.days.ago)

      get "/api/v1/fleets/#{fleet.slug}/events.ics", params: {token: fleet.calendar_feed_token}

      expect(response.body).not_to include("Ancient Op")
      expect(response.body).to include("Recent Op")
    end
  end

  context "with invalid token" do
    it "returns forbidden" do
      get "/api/v1/fleets/#{fleet.slug}/events.ics", params: {token: "wrong"}

      expect(response).to have_http_status(:forbidden)
    end
  end
end

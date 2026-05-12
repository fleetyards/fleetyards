# frozen_string_literal: true

require "rails_helper"

RSpec.describe "api/v1/fleets/events/:slug/event.ics", type: :request do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:fleet_event) do
    create(:fleet_event, :open,
      fleet: fleet,
      created_by: admin,
      title: "Thursday Play Evening")
  end

  before do
    Flipper.enable("mission_builder")
    sign_in(admin)
  end

  it "returns a one-shot ICS attachment for the event" do
    get "/api/v1/fleets/#{fleet.slug}/events/#{fleet_event.slug}/event.ics"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/calendar")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("#{fleet_event.slug}.ics")
    expect(response.body).to include("BEGIN:VCALENDAR")
    expect(response.body).to include("SUMMARY:Thursday Play Evening")
    expect(response.body).to include("UID:#{fleet_event.external_uid}@fleetyards.net")
  end

  it "404s for a non-existent event" do
    get "/api/v1/fleets/#{fleet.slug}/events/missing/event.ics"

    expect(response).to have_http_status(:not_found)
  end

  it "respects the fleet:events:read policy" do
    sign_out admin
    outsider = create(:user)
    sign_in outsider

    get "/api/v1/fleets/#{fleet.slug}/events/#{fleet_event.slug}/event.ics"

    expect([401, 403, 404]).to include(response.status)
  end
end

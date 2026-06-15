# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsIcsTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @fleet_event = create(:fleet_event, :open,
      fleet: @fleet,
      created_by: @admin,
      title: "Thursday Play Evening")
    sign_in @admin
  end

  test "GET /fleets/:slug/events/:slug/event.ics returns a one-shot ICS attachment" do
    get "/api/v1/fleets/#{@fleet.slug}/events/#{@fleet_event.slug}/event.ics"

    assert_response :ok
    assert_equal "text/calendar", response.media_type
    assert_includes response.headers["Content-Disposition"], "attachment"
    assert_includes response.headers["Content-Disposition"], "#{@fleet_event.slug}.ics"
    assert_includes response.body, "BEGIN:VCALENDAR"
    assert_includes response.body, "SUMMARY:Thursday Play Evening"
    assert_includes response.body, "UID:#{@fleet_event.external_uid}@fleetyards.net"
  end

  test "GET /fleets/:slug/events/:slug/event.ics 404s for a non-existent event" do
    get "/api/v1/fleets/#{@fleet.slug}/events/missing/event.ics"

    assert_response :not_found
  end

  test "GET /fleets/:slug/events/:slug/event.ics respects the fleet:events:read policy" do
    sign_out @admin
    outsider = create(:user)
    sign_in outsider

    get "/api/v1/fleets/#{@fleet.slug}/events/#{@fleet_event.slug}/event.ics"

    assert_includes [401, 403, 404], response.status
  end
end

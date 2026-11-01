# frozen_string_literal: true

require "test_helper"

class CalendarFeedFrontendHostTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin], calendar_feed_token: SecureRandom.hex(16))
    @admin.ensure_calendar_feed_token!
  end

  test "serves the fleet feed on the frontend host" do
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Open Op", starts_at: 2.days.from_now)

    get "/v1/fleets/#{@fleet.slug}/events.ics", params: {token: @fleet.calendar_feed_token}

    assert_response :ok
    assert_equal "text/calendar", response.media_type
    assert_includes response.body, "SUMMARY:Open Op"
  end

  test "rejects a wrong fleet feed token on the frontend host" do
    get "/v1/fleets/#{@fleet.slug}/events.ics", params: {token: "nope"}

    assert_response :forbidden
  end

  test "serves the personal feed on the frontend host" do
    get "/v1/me/calendar/events.ics", params: {token: @admin.calendar_feed_token}

    assert_response :ok
    assert_equal "text/calendar", response.media_type
    assert_includes response.body, "BEGIN:VCALENDAR"
  end
end

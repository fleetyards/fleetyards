# frozen_string_literal: true

require "test_helper"

class CalendarFeedFrontendHostTest < ActionDispatch::IntegrationTest
  test "redirects the fleet feed to the API host, keeping the token" do
    get "/v1/fleets/my-fleet/events.ics", params: {token: "abc"}

    assert_redirected_to "#{API_ENDPOINT}/fleets/my-fleet/events.ics?token=abc"
    assert_response :moved_permanently
  end

  test "redirects the fleet feed as issued, with a trailing slash" do
    get "/v1/fleets/my-fleet/events.ics/", params: {token: "abc"}

    assert_redirected_to "#{API_ENDPOINT}/fleets/my-fleet/events.ics?token=abc"
  end

  test "redirects the personal feed to the API host, keeping the token" do
    get "/v1/me/calendar/events.ics/", params: {token: "abc"}

    assert_redirected_to "#{API_ENDPOINT}/me/calendar/events.ics?token=abc"
  end

  test "the redirect target serves the feed" do
    Flipper.enable("fleet_mission_builder")
    admin = create(:user)
    fleet = create(:fleet, admins: [admin], calendar_feed_token: SecureRandom.hex(16))
    create(:fleet_event, :open, fleet:, created_by: admin, title: "Open Op", starts_at: 2.days.from_now)

    get "/v1/fleets/#{fleet.slug}/events.ics/", params: {token: fleet.calendar_feed_token}
    follow_redirect!

    assert_response :ok
    assert_equal "text/calendar", response.media_type
    assert_includes response.body, "SUMMARY:Open Op"
  end
end

# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsCalendarIcsTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin], calendar_feed_token: SecureRandom.hex(16))
  end

  test "GET /fleets/:slug/events.ics returns an ICS feed with valid token" do
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, starts_at: 2.days.from_now)

    get "/api/v1/fleets/#{@fleet.slug}/events.ics", params: {token: @fleet.calendar_feed_token}

    assert_response :ok
    assert_equal "text/calendar", response.media_type
    assert_includes response.body, "BEGIN:VCALENDAR"
    assert_includes response.body, "BEGIN:VEVENT"
    assert_includes response.body, "END:VCALENDAR"
  end

  test "GET /fleets/:slug/events.ics includes recently cancelled events with STATUS:CANCELLED" do
    create(:fleet_event, :cancelled,
      fleet: @fleet, created_by: @admin, title: "Scrubbed Op",
      starts_at: 2.days.from_now)
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Live Op")

    get "/api/v1/fleets/#{@fleet.slug}/events.ics", params: {token: @fleet.calendar_feed_token}

    assert_includes response.body, "Live Op"
    assert_includes response.body, "Scrubbed Op"
    assert_includes response.body, "STATUS:CANCELLED"
  end

  test "GET /fleets/:slug/events.ics drops cancelled events more than a week past their start time" do
    create(:fleet_event, :cancelled,
      fleet: @fleet, created_by: @admin, title: "Old Scrubbed Op",
      starts_at: 10.days.ago)

    get "/api/v1/fleets/#{@fleet.slug}/events.ics", params: {token: @fleet.calendar_feed_token}

    refute_includes response.body, "Old Scrubbed Op"
  end

  test "GET /fleets/:slug/events.ics drops events older than the 90-day past horizon" do
    create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin, title: "Ancient Op",
      starts_at: 100.days.ago)
    create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin, title: "Recent Op",
      starts_at: 30.days.ago)

    get "/api/v1/fleets/#{@fleet.slug}/events.ics", params: {token: @fleet.calendar_feed_token}

    refute_includes response.body, "Ancient Op"
    assert_includes response.body, "Recent Op"
  end

  test "GET /fleets/:slug/events.ics returns forbidden with invalid token" do
    get "/api/v1/fleets/#{@fleet.slug}/events.ics", params: {token: "wrong"}

    assert_response :forbidden
  end
end

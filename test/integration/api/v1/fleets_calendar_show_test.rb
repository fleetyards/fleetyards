# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsCalendarShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/calendar" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Fleet Calendar") do
      operationId "fleetCalendar"
      tags "Fleet Events"
      produces "application/json"

      parameter name: :from, in: :query, schema: {type: :string}, required: false
      parameter name: :to, in: :query, schema: {type: :string}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Events::FleetCalendar
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  test "GET /fleets/:slug/calendar returns events" do
    # Without from/to the window is the month start plus 35 days, so it shrinks
    # to a few days late in the month. Anchor the clock so both events fit.
    travel_to Time.current.beginning_of_month + 5.days

    create(:fleet_event, fleet: @fleet, created_by: @admin, starts_at: 1.day.from_now)
    create(:fleet_event, fleet: @fleet, created_by: @admin, starts_at: 5.days.from_now)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert parsed_body["items"].size >= 2
    end
  end

  # The calendar is another list of the fleet's events, so it keeps a
  # squadron's events to that squadron the way the event list does.
  test "GET /fleets/:slug/calendar leaves out squadron events the reader is not in" do
    travel_to Time.current.beginning_of_month + 5.days

    member = create(:user)
    create(:fleet_membership, :accepted, fleet: @fleet, user: member)
    squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_event, fleet: @fleet, created_by: @admin, title: "Open", starts_at: 1.day.from_now)
    create(:fleet_event, fleet: @fleet, created_by: @admin, title: "Squadron only",
      starts_at: 2.days.from_now, visibility: "squadron", fleet_squadrons: [squadron])

    sign_in member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Open"], parsed_body["items"].map { |entry| entry["title"] }
    end

    sign_in @admin
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 2, parsed_body["items"].size
    end
  end

  # A recurring signup names its day, so only that occurrence carries it, and a
  # withdrawn one is no longer the reader's plan at all.
  test "GET /fleets/:slug/calendar carries the reader's own signup per occurrence" do
    travel_to Time.zone.parse("2026-05-13 20:00:00 UTC")

    member = create(:user)
    membership = create(:fleet_membership, :accepted, fleet: @fleet, user: member)
    weekly = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Weekly",
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"), timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
    one_off = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "One-off",
      starts_at: Time.zone.parse("2026-05-16 20:00:00 UTC"))
    withdrawn = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Withdrawn",
      starts_at: Time.zone.parse("2026-05-17 20:00:00 UTC"))

    create(:fleet_event_signup, fleet_event: weekly, fleet_event_slot: nil, fleet_membership: membership,
      status: "tentative", occurrence_date: Date.new(2026, 5, 21))
    create(:fleet_event_signup, fleet_event: one_off, fleet_event_slot: nil, fleet_membership: membership)
    create(:fleet_event_signup, fleet_event: withdrawn, fleet_event_slot: nil, fleet_membership: membership,
      status: "withdrawn")

    sign_in member
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {from: "2026-05-13", to: "2026-05-30"} do
      signups = parsed_body["items"].to_h do |entry|
        [[entry["title"], entry["occurrenceDate"]], entry.dig("viewerSignup", "status")]
      end

      assert_nil signups[["Weekly", "2026-05-14"]]
      assert_equal "tentative", signups[["Weekly", "2026-05-21"]]
      assert_equal "confirmed", signups[["One-off", nil]]
      assert_nil signups[["Withdrawn", nil]]
    end
  end

  test "GET /fleets/:slug/calendar with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/calendar returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "GET /fleets/:slug/calendar returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end

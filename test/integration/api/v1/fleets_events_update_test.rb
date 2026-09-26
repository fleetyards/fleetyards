# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Update Fleet Event") do
      operationId "updateFleetEvent"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::FleetEventUpdateInput, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Events::FleetEventExtended
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
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
  end

  test "PUT /fleets/:slug/events/:slug updates the event" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {title: "Renamed Event"} do
      assert_equal "Renamed Event", parsed_body["title"]
    end
  end

  test "PUT /fleets/:slug/events/:slug sets a custom recurrence" do
    @fleet_event.update!(starts_at: Time.zone.parse("2026-10-08 20:00"), timezone: "UTC")
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {recurring: true, recurrenceInterval: "weekly", recurrenceEvery: 2, recurrenceWeekdays: [2, 4]} do
      assert_equal "weekly", parsed_body["recurrenceInterval"]
      assert_equal 2, parsed_body["recurrenceEvery"]
      assert_equal [2, 4], parsed_body["recurrenceWeekdays"]
    end
  end

  # Held to squadrons after it was announced, the event has to come back off
  # the fleet-wide surfaces -- the Discord guild is one.
  test "PUT /fleets/:slug/events/:slug announces an event becoming squadron-only" do
    Flipper.enable("fleet_squadrons")
    squadron = create(:fleet_squadron, fleet: @fleet)
    sign_in @admin

    restricted = []
    callback = ->(*args) { restricted << ActiveSupport::Notifications::Event.new(*args).payload[:event] }
    ActiveSupport::Notifications.subscribed(callback, "fleet_event.restricted") do
      assert_api_response :put, 200,
        path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
        body: {description: "Kept open to everyone"}

      assert_api_response :put, 200,
        path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
        body: {visibility: "squadron", fleetSquadronIds: [squadron.id]}
    end

    assert_equal [@fleet_event.id], restricted.map(&:id)
  end

  test "PUT /fleets/:slug/events/:slug takes an event kept to officers off the guild" do
    sign_in @admin

    restricted = []
    callback = ->(*args) { restricted << ActiveSupport::Notifications::Event.new(*args).payload[:event] }
    ActiveSupport::Notifications.subscribed(callback, "fleet_event.restricted") do
      assert_api_response :put, 200,
        path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
        body: {visibility: "officers"}
    end

    assert_equal [@fleet_event.id], restricted.map(&:id)
  end

  test "PUT /fleets/:slug/events/:slug puts an event opened up again back on the guild" do
    @fleet_event.update_columns(visibility: "officers", status: "open")
    sign_in @admin

    unrestricted = []
    callback = ->(*args) { unrestricted << ActiveSupport::Notifications::Event.new(*args).payload[:event] }
    ActiveSupport::Notifications.subscribed(callback, "fleet_event.unrestricted") do
      assert_api_response :put, 200,
        path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
        body: {visibility: "members"}

      assert_api_response :put, 200,
        path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
        body: {visibility: "fleet"}
    end

    assert_equal [@fleet_event.id], unrestricted.map(&:id)
  end

  test "PUT /fleets/:slug/events/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Renamed Event"}
  end

  test "PUT /fleets/:slug/events/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Renamed Event"}
  end

  test "PUT /fleets/:slug/events/:slug returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {title: "Renamed Event"}
  end
end

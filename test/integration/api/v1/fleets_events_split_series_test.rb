# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsSplitSeriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/split-series" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    post("Split a recurring event series at an occurrence") do
      operationId "splitFleetEventSeries"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetEventOccurrenceDateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "created") do
        schema ::V1::Schemas::Fleets::Events::FleetEventExtended
      end

      response(422, "not an occurrence of a recurring series") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @fleet_event = create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
  end

  test "POST /fleets/:slug/events/:slug/split-series returns the new series" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {date: "2026-06-04"}

    successor = @fleet.fleet_events.find_by!(slug: response.parsed_body["slug"])
    assert_equal Time.zone.parse("2026-06-04 20:00:00 UTC"), successor.starts_at
    assert_equal Date.parse("2026-06-03"), @fleet_event.reload.recurrence_until
  end

  test "POST /fleets/:slug/events/:slug/split-series returns 422 for a date without an occurrence" do
    sign_in @admin

    assert_api_response :post, 422,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {date: "2026-06-05"}

    assert_equal "not_an_occurrence", response.parsed_body["code"]
  end

  test "POST /fleets/:slug/events/:slug/split-series returns 422 at the start of the series" do
    sign_in @admin

    assert_api_response :post, 422,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {date: "2026-05-14"}

    assert_equal "split_at_series_start", response.parsed_body["code"]
  end

  test "POST /fleets/:slug/events/:slug/split-series is refused to a member" do
    sign_in @member

    post "/api/v1/fleets/#{@fleet.slug}/events/#{@fleet_event.slug}/split-series",
      params: {date: "2026-06-04"}, as: :json

    assert_equal 403, response.status
    assert_nil @fleet_event.reload.recurrence_until
  end

  test "POST /fleets/:slug/events/:slug/split-series resyncs the Discord events it moved" do
    create(:fleet_event_occurrence_state, fleet_event: @fleet_event,
      occurrence_date: Date.parse("2026-06-11"), discord_event_id: "987")
    sign_in @admin

    assert_difference -> { Discord::SyncFleetEventJob.jobs.size }, 1 do
      post "/api/v1/fleets/#{@fleet.slug}/events/#{@fleet_event.slug}/split-series",
        params: {date: "2026-06-04"}, as: :json
    end

    assert_equal 201, response.status
    assert_equal "upsert_occurrences", Discord::SyncFleetEventJob.jobs.last["args"].last
  end
end

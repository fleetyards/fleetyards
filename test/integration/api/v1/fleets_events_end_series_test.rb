# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsEndSeriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/end-series" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    post("End a recurring event series from a given date") do
      operationId "endFleetEventSeries"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      request_body schema: {
        type: :object,
        properties: {date: {type: :string, format: :date}},
        required: %w[date]
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @fleet_event = create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
  end

  test "POST /fleets/:slug/events/:slug/end-series sets recurrence_until to the day before" do
    sign_in @admin

    assert_api_response :post, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {date: "2026-06-04"}

    assert_equal Date.parse("2026-06-03"), @fleet_event.reload.recurrence_until
  end
end

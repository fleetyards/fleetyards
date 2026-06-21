# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsRecurrenceTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/skip-occurrence" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    post("Skip a specific occurrence of a recurring event") do
      operationId "skipFleetEventOccurrence"
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

      response(422, "not recurring") do
        schema "$ref": "#/components/schemas/StandardError"
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

  test "POST /fleets/:slug/events/:slug/skip-occurrence adds the date to excluded_dates" do
    sign_in @admin

    assert_api_response :post, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {date: "2026-05-21"}

    assert_includes @fleet_event.reload.excluded_dates.map(&:to_s), "2026-05-21"
  end

  test "POST /fleets/:slug/events/:slug/skip-occurrence returns 422 when event is not recurring" do
    non_recurring = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, recurring: false)
    sign_in @admin

    assert_api_response :post, 422,
      path_params: {fleetSlug: @fleet.slug, slug: non_recurring.slug},
      body: {date: "2026-05-21"}
  end
end

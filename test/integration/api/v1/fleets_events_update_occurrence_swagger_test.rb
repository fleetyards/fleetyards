# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsUpdateOccurrenceSwaggerTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/update-occurrence" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    patch("Override fields on a single occurrence") do
      operationId "updateFleetEventOccurrence"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      request_body schema: {
        type: :object,
        properties: {
          date: {type: :string, format: :date},
          title: {type: :string, nullable: true},
          description: {type: :string, nullable: true},
          briefing: {type: :string, nullable: true},
          location: {type: :string, nullable: true},
          meetupLocation: {type: :string, nullable: true},
          scenario: {type: :string, nullable: true},
          coverImagePreset: {type: :string, nullable: true}
        },
        required: %w[date]
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventOccurrenceState"
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

  test "PATCH /fleets/:slug/events/:slug/update-occurrence overrides occurrence fields" do
    sign_in @admin

    assert_api_response :patch, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {date: "2026-05-21", location: "Levski", scenario: "Bunker raid"} do
      assert_equal "Levski", parsed_body["location"]
      assert_equal "Bunker raid", parsed_body["scenario"]
    end
  end
end

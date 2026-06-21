# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventSlotsSortTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleet-event-slots/sort" do
    put("Sort event slots") do
      operationId "sortFleetEventSlots"
      tags "Fleet Event Slots"
      consumes "application/json"
      produces "application/json"

      request_body schema: {
        type: :object,
        properties: {
          slottableType: {type: :string, enum: %w[FleetEventTeam FleetEventShip]},
          slottableId: {type: :string, format: :uuid},
          sorting: {type: :array, items: {type: :string, format: :uuid}}
        },
        required: %w[slottableType slottableId sorting]
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    @team = create(:fleet_event_team, fleet_event: @fleet_event)
    @slots = create_list(:fleet_event_slot, 3, slottable: @team)
  end

  test "PUT /fleet-event-slots/sort sorts slots" do
    sign_in @admin

    assert_api_response :put, 200,
      body: {
        slottableType: "FleetEventTeam",
        slottableId: @team.id,
        sorting: @slots.reverse.map(&:id)
      }
  end

  test "PUT /fleet-event-slots/sort with OAuth bearer token" do
    assert_api_response :put, 200,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {
        slottableType: "FleetEventTeam",
        slottableId: @team.id,
        sorting: @slots.reverse.map(&:id)
      }
  end

  test "PUT /fleet-event-slots/sort returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {
        slottableType: "FleetEventTeam",
        slottableId: @team.id,
        sorting: @slots.reverse.map(&:id)
      }
  end

  test "PUT /fleet-event-slots/sort returns 401 when not signed in" do
    assert_api_response :put, 401,
      body: {
        slottableType: "FleetEventTeam",
        slottableId: @team.id,
        sorting: @slots.reverse.map(&:id)
      }
  end
end

# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventSlotsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleet-event-slots/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}

    put("Update event slot") do
      operationId "updateFleetEventSlot"
      tags "Fleet Event Slots"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventSlotUpdateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSlot"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Destroy event slot") do
      operationId "destroyFleetEventSlot"
      tags "Fleet Event Slots"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
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
    @slot = create(:fleet_event_slot, slottable: @team)
  end

  test "PUT /fleet-event-slots/:id updates the slot" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {id: @slot.id},
      body: {title: "Wing Lead", description: "Squadron lead"}
  end

  test "PUT /fleet-event-slots/:id with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {id: @slot.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Wing Lead", description: "Squadron lead"}
  end

  test "PUT /fleet-event-slots/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {id: @slot.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Wing Lead", description: "Squadron lead"}
  end

  test "PUT /fleet-event-slots/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {id: @slot.id},
      body: {title: "Wing Lead", description: "Squadron lead"}
  end

  test "DELETE /fleet-event-slots/:id destroys the slot" do
    sign_in @admin

    assert_api_response :delete, 204, path_params: {id: @slot.id}
    assert_raises(ActiveRecord::RecordNotFound) { @slot.reload }
  end

  test "DELETE /fleet-event-slots/:id with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {id: @slot.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleet-event-slots/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :delete, 401,
      path_params: {id: @slot.id},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /fleet-event-slots/:id returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {id: @slot.id}
  end
end

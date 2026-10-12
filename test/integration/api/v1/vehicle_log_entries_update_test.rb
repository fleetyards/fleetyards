# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleLogEntriesUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/log-entries/{id}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, description: "Log entry id", schema: {type: :string, format: :uuid}

    put("Update Vehicle Log Entry") do
      operationId "updateVehicleLogEntry"
      tags "VehicleLogEntries"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleLogEntryUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::VehicleLogEntry
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("vehicle_overview")
    @user = create(:user)
    @vehicle = create(:vehicle, user: @user)
    @log_entry = create(:vehicle_log_entry, vehicle: @vehicle, title: "Before")
  end

  test "PUT /vehicles/:vehicle_id/log-entries/:id updates the entry" do
    sign_in @user

    assert_api_response :put, 200,
      path_params: {vehicle_id: @vehicle.id, id: @log_entry.id},
      body: {title: "After", public: true} do
      assert_equal "After", parsed_body["title"]
      assert_equal true, parsed_body["public"]
    end
  end

  test "PUT /vehicles/:vehicle_id/log-entries/:id returns 400 for a blank title" do
    sign_in @user

    assert_api_response :put, 400,
      path_params: {vehicle_id: @vehicle.id, id: @log_entry.id},
      body: {title: ""}

    assert_equal "Before", @log_entry.reload.title
  end

  test "PUT /vehicles/:vehicle_id/log-entries/:id returns 404 for an entry on another ship" do
    other_entry = create(:vehicle_log_entry, vehicle: create(:vehicle, user: @user))
    sign_in @user

    assert_api_response :put, 404,
      path_params: {vehicle_id: @vehicle.id, id: other_entry.id},
      body: {title: "Crossed"}
  end

  test "PUT /vehicles/:vehicle_id/log-entries/:id returns 404 for another user" do
    sign_in create(:user)

    assert_api_response :put, 404,
      path_params: {vehicle_id: @vehicle.id, id: @log_entry.id},
      body: {title: "Not mine"}
  end

  test "PUT /vehicles/:vehicle_id/log-entries/:id returns 403 while the feature is off" do
    Flipper.disable("vehicle_overview")
    sign_in @user

    assert_api_response :put, 403,
      path_params: {vehicle_id: @vehicle.id, id: @log_entry.id},
      body: {title: "Too early"}
  end

  test "PUT /vehicles/:vehicle_id/log-entries/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {vehicle_id: @vehicle.id, id: @log_entry.id},
      body: {title: "Anonymous"}
  end
end

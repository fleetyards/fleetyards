# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleLogEntriesDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/log-entries/{id}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, description: "Log entry id", schema: {type: :string, format: :uuid}

    delete("Destroy Vehicle Log Entry") do
      operationId "destroyVehicleLogEntry"
      tags "VehicleLogEntries"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::VehicleLogEntry
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
    @log_entry = create(:vehicle_log_entry, vehicle: @vehicle)
  end

  test "DELETE /vehicles/:vehicle_id/log-entries/:id removes the entry" do
    sign_in @user

    assert_difference "VehicleLogEntry.count", -1 do
      assert_api_response :delete, 200, path_params: {vehicle_id: @vehicle.id, id: @log_entry.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/log-entries/:id returns 404 for another user" do
    sign_in create(:user)

    assert_no_difference "VehicleLogEntry.count" do
      assert_api_response :delete, 404, path_params: {vehicle_id: @vehicle.id, id: @log_entry.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/log-entries/:id returns 403 while the feature is off" do
    Flipper.disable("vehicle_overview")
    sign_in @user

    assert_api_response :delete, 403, path_params: {vehicle_id: @vehicle.id, id: @log_entry.id}
  end

  test "DELETE /vehicles/:vehicle_id/log-entries/:id returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {vehicle_id: @vehicle.id, id: @log_entry.id}
  end
end

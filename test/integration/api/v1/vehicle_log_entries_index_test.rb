# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleLogEntriesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/log-entries" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    get("List Vehicle Log Entries") do
      operationId "vehicleLogEntries"
      tags "VehicleLogEntries"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::VehicleLogEntriesList
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
  end

  test "GET /vehicles/:vehicle_id/log-entries lists the newest entry first" do
    create(:vehicle_log_entry, vehicle: @vehicle, title: "Older", logged_at: 2.days.ago)
    create(:vehicle_log_entry, vehicle: @vehicle, title: "Newer", logged_at: 1.day.ago)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal %w[Newer Older], parsed_body.pluck("title")
    end
  end

  test "GET /vehicles/:vehicle_id/log-entries includes private entries for the owner" do
    create(:vehicle_log_entry, vehicle: @vehicle)
    create(:vehicle_log_entry, :public, vehicle: @vehicle)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal 2, parsed_body.size
    end
  end

  test "GET /vehicles/:vehicle_id/log-entries returns 404 for another user's ship" do
    create(:vehicle_log_entry, vehicle: @vehicle)
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/log-entries returns 403 while the feature is off" do
    Flipper.disable("vehicle_overview")
    sign_in @user

    assert_api_response :get, 403, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/log-entries returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/log-entries with OAuth bearer token" do
    create(:vehicle_log_entry, vehicle: @vehicle)

    assert_api_response :get, 200,
      path_params: {vehicle_id: @vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end

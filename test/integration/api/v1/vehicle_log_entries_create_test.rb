# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleLogEntriesCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/log-entries" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    post("Create Vehicle Log Entry") do
      operationId "createVehicleLogEntry"
      tags "VehicleLogEntries"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleLogEntryCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
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
  end

  test "POST /vehicles/:vehicle_id/log-entries creates a private entry dated now" do
    sign_in @user

    freeze_time do
      assert_api_response :post, 201,
        path_params: {vehicle_id: @vehicle.id},
        body: {title: "Maiden voyage", body: "Stanton to Pyro and back."} do
        assert_equal "Maiden voyage", parsed_body["title"]
        assert_equal false, parsed_body["public"]
        assert_equal Time.current, Time.zone.parse(parsed_body["loggedAt"])
      end
    end
  end

  test "POST /vehicles/:vehicle_id/log-entries keeps a date the owner chose" do
    sign_in @user
    logged_at = 3.weeks.ago.change(usec: 0)

    assert_api_response :post, 201,
      path_params: {vehicle_id: @vehicle.id},
      body: {title: "Back-dated", loggedAt: logged_at.iso8601} do
      assert_equal logged_at, Time.zone.parse(parsed_body["loggedAt"])
    end
  end

  test "POST /vehicles/:vehicle_id/log-entries follows the ship's public default" do
    @vehicle.update!(log_entries_public_by_default: true)
    sign_in @user

    assert_api_response :post, 201, path_params: {vehicle_id: @vehicle.id}, body: {title: "Shared"} do
      assert_equal true, parsed_body["public"]
    end
  end

  test "POST /vehicles/:vehicle_id/log-entries lets an entry stay private against a public default" do
    @vehicle.update!(log_entries_public_by_default: true)
    sign_in @user

    assert_api_response :post, 201,
      path_params: {vehicle_id: @vehicle.id},
      body: {title: "Just for me", public: false} do
      assert_equal false, parsed_body["public"]
    end
  end

  test "POST /vehicles/:vehicle_id/log-entries returns 400 without a title" do
    sign_in @user

    assert_no_difference "VehicleLogEntry.count" do
      assert_api_response :post, 400, path_params: {vehicle_id: @vehicle.id}, body: {title: ""}
    end
  end

  test "POST /vehicles/:vehicle_id/log-entries returns 404 for another user's ship" do
    sign_in create(:user)

    assert_no_difference "VehicleLogEntry.count" do
      assert_api_response :post, 404, path_params: {vehicle_id: @vehicle.id}, body: {title: "Not mine"}
    end
  end

  test "POST /vehicles/:vehicle_id/log-entries returns 403 while the feature is off" do
    Flipper.disable("vehicle_overview")
    sign_in @user

    assert_api_response :post, 403, path_params: {vehicle_id: @vehicle.id}, body: {title: "Too early"}
  end

  test "POST /vehicles/:vehicle_id/log-entries returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {vehicle_id: @vehicle.id}, body: {title: "Anonymous"}
  end

  test "POST /vehicles/:vehicle_id/log-entries with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {vehicle_id: @vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {title: "Via the API"}
  end
end

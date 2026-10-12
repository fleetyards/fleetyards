# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicHangarsVehicleLogEntriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/hangars/{username}/vehicles/{vehicle_id}/log-entries" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username", required: true
    parameter name: "vehicle_id", in: :path, schema: {type: :string, format: :uuid}, description: "Vehicle id", required: true

    get("Public Vehicle Log Entries") do
      operationId "publicVehicleLogEntries"
      tags "PublicVehicleLogEntries"
      produces "application/json"

      parameter name: "share", in: :query, schema: {type: :string}, required: false, description: "Hangar share token"

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::VehicleLogEntriesPublicList
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
    @user = create(:user, public_hangar: true)
    @vehicle = create(:vehicle, user: @user, public: true)
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/log-entries lists only the public entries" do
    create(:vehicle_log_entry, :public, vehicle: @vehicle, title: "Shared")
    create(:vehicle_log_entry, vehicle: @vehicle, title: "Private")

    assert_api_response :get, 200, path_params: {username: @user.username, vehicle_id: @vehicle.id} do
      assert_equal %w[Shared], parsed_body.pluck("title")
    end
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/log-entries opens a private hangar to its share token" do
    @user.update!(public_hangar: false)
    create(:vehicle_log_entry, :public, vehicle: @vehicle)
    token = @user.ensure_hangar_share_token!

    assert_api_response :get, 200,
      path_params: {username: @user.username, vehicle_id: @vehicle.id},
      params: {share: token} do
      assert_equal 1, parsed_body.size
    end
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/log-entries returns 404 for a private hangar" do
    @user.update!(public_hangar: false)
    create(:vehicle_log_entry, :public, vehicle: @vehicle)

    assert_api_response :get, 404, path_params: {username: @user.username, vehicle_id: @vehicle.id}
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/log-entries returns 404 for a hidden ship" do
    @vehicle.update!(public: false)
    create(:vehicle_log_entry, :public, vehicle: @vehicle)

    assert_api_response :get, 404, path_params: {username: @user.username, vehicle_id: @vehicle.id}
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/log-entries returns 404 for a wishlist ship" do
    wanted = create(:vehicle, user: @user, public: true, wanted: true)
    create(:vehicle_log_entry, :public, vehicle: wanted)

    assert_api_response :get, 404, path_params: {username: @user.username, vehicle_id: wanted.id}
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/log-entries follows the owner's flag, not the visitor's" do
    Flipper.disable("vehicle_overview")
    Flipper.enable_actor("vehicle_overview", @user)
    create(:vehicle_log_entry, :public, vehicle: @vehicle)

    assert_api_response :get, 200, path_params: {username: @user.username, vehicle_id: @vehicle.id} do
      assert_equal 1, parsed_body.size
    end
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/log-entries returns 403 while the feature is off" do
    Flipper.disable("vehicle_overview")

    assert_api_response :get, 403, path_params: {username: @user.username, vehicle_id: @vehicle.id}
  end
end

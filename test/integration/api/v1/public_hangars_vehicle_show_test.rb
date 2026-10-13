# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicHangarsVehicleShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/hangars/{username}/vehicles/{id}" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username", required: true
    parameter name: "id", in: :path, schema: {type: :string}, description: "Vehicle address: its id, or its serial, followed by its name", required: true

    get("Public Hangar Vehicle") do
      operationId "publicHangarVehicle"
      tags "PublicHangar"
      produces "application/json"

      parameter name: "share", in: :query, schema: {type: :string}, required: false, description: "Hangar share token"

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::VehiclePublic
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
    @vehicle = create(:vehicle, user: @user, public: true, dedication: "To boldly go")
  end

  test "GET /public/hangars/:username/vehicles/:id returns a public ship with its plaque" do
    assert_api_response :get, 200, path_params: {username: @user.username, id: @vehicle.id} do
      assert_equal @vehicle.id, parsed_body["id"]
      assert_equal "To boldly go", parsed_body["dedication"]
    end
  end

  test "GET /public/hangars/:username/vehicles/:id finds a ship by the serial its address leads with" do
    @vehicle.update!(serial: "L8-4261-HA", name: "Contorta", name_visible: true)

    assert_api_response :get, 200, path_params: {username: @user.username, id: "l8-4261-ha-contorta"} do
      assert_equal @vehicle.id, parsed_body["id"]
    end
  end

  test "GET /public/hangars/:username/vehicles/:id opens a private hangar to its share token" do
    @user.update!(public_hangar: false)

    assert_api_response :get, 200,
      path_params: {username: @user.username, id: @vehicle.id},
      params: {share: @user.ensure_hangar_share_token!}
  end

  test "GET /public/hangars/:username/vehicles/:id returns 404 for a hidden ship" do
    @vehicle.update!(public: false)

    assert_api_response :get, 404, path_params: {username: @user.username, id: @vehicle.id}
  end

  test "GET /public/hangars/:username/vehicles/:id returns 404 for a private hangar" do
    @user.update!(public_hangar: false)

    assert_api_response :get, 404, path_params: {username: @user.username, id: @vehicle.id}
  end

  test "GET /public/hangars/:username/vehicles/:id returns 403 while the owner lacks the feature" do
    Flipper.disable("vehicle_overview")

    assert_api_response :get, 403, path_params: {username: @user.username, id: @vehicle.id}
  end
end

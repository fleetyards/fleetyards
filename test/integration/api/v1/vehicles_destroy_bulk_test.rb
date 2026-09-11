# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehiclesDestroyBulkTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/destroy-bulk" do
    put("Destroy multiple Vehicles") do
      operationId "destroyBulkVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleDestroyBulkInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "PUT /vehicles/destroy-bulk destroys the listed vehicles" do
    vehicles = create_list(:vehicle, 3, user: @user)
    sign_in @user

    assert_api_response :put, 204, body: {ids: vehicles.map(&:id)}
  end

  test "PUT /vehicles/destroy-bulk destroys what hangs off the vehicles" do
    vehicle = create(:vehicle, user: @user)
    create(:vehicle_loadout, vehicle: vehicle)
    TaskForce.create!(vehicle: vehicle, hangar_group: create(:hangar_group, user: @user))
    FleetVehicle.create!(fleet: create(:fleet), vehicle: vehicle)
    sign_in @user

    assert_not_empty PaperTrail::Version.where(item_type: "Vehicle", item_id: vehicle.id)

    assert_api_response :put, 204, body: {ids: [vehicle.id]}

    assert_empty VehicleLoadout.where(vehicle_id: vehicle.id)
    assert_empty TaskForce.where(vehicle_id: vehicle.id)
    assert_empty FleetVehicle.where(vehicle_id: vehicle.id)
    assert_empty PaperTrail::Version.where(item_type: "Vehicle", item_id: vehicle.id)
  end

  test "PUT /vehicles/destroy-bulk returns 401 when not signed in" do
    vehicles = create_list(:vehicle, 3, user: @user)

    assert_api_response :put, 401, body: {ids: vehicles.map(&:id)}
  end

  test "PUT /vehicles/destroy-bulk with OAuth bearer token" do
    vehicles = create_list(:vehicle, 3, user: @user)

    assert_api_response :put, 204,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {ids: vehicles.map(&:id)}
  end
end

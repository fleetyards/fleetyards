# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehiclePaintsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/paints" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    get("List Vehicle Paints") do
      operationId "vehiclePaints"
      tags "VehiclePaints"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::VehiclePaintsList
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
    @model = create(:model, name: "Ironclad")
    @rust = create(:model_paint, model: @model, name: "Rust Society")
    @storm = create(:model_paint, :with_store_image, model: @model, name: "Stormbringer")
    @vehicle = create(:vehicle, user: @user, model: @model, model_paints: [@storm])
  end

  test "GET /vehicles/:vehicle_id/paints lists the ship's paints first, then the pledged ones" do
    create(:model_paint, model: @model, name: "Alpha")
    item = create(:hangar_pledge_item, user: @user, name: "Ironclad - Rust Society Paint")
    HangarPledgeItems::PaintLinker.new.link([item])
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal ["Stormbringer", "Rust Society", "Alpha"], parsed_body.map { |entry| entry.dig("paint", "name") }
      assert_equal [true, false, false], parsed_body.pluck("owned")
      assert_equal [false, true, false], parsed_body.pluck("pledged")
    end
  end

  test "GET /vehicles/:vehicle_id/paints marks the paint whose picture the ship shows" do
    @vehicle.update!(picture: @storm)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      picture = parsed_body.select { |entry| entry["picture"] }
      assert_equal ["Stormbringer"], picture.map { |entry| entry.dig("paint", "name") }
    end
  end

  test "GET /vehicles/:vehicle_id/paints leaves out hidden paints" do
    create(:model_paint, :hidden, model: @model, name: "Unreleased")
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal 2, parsed_body.size
    end
  end

  test "GET /vehicles/:vehicle_id/paints keeps an owned paint once the catalogue hides it" do
    @storm.update!(hidden: true)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      owned = parsed_body.find { |entry| entry["owned"] }
      assert_equal "Stormbringer", owned&.dig("paint", "name")
    end
  end

  test "GET /vehicles/:vehicle_id/paints returns 404 for another user's ship" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/paints returns 403 while the feature is off" do
    Flipper.disable("vehicle_overview")
    sign_in @user

    assert_api_response :get, 403, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/paints returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id}
  end
end

# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles" do
    post("Create new Vehicle") do
      operationId "createVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleCreateInput

      response(201, "successful") do
        schema ::V1::Schemas::Vehicles::Vehicle
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/vehicles/bulk" do
    put("Update multiple vehicles") do
      operationId "updateBulkVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleUpdateBulkInput

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/vehicles/destroy-all-ingame" do
    delete("Delete all ingame bought Vehicles") do
      operationId "destroyAllIngameVehicles"
      tags "Vehicles"

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

  api_path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    delete("Delete Vehicle") do
      operationId "destroyVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::Vehicle
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Show Vehicle") do
      operationId "showVehicle"
      tags "Vehicles"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::Vehicle
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update Vehicle") do
      operationId "updateVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleUpdateInput

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::Vehicle
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
  end

  # POST /vehicles
  test "POST /vehicles creates a vehicle" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 201, body: {modelId: model.id}
  end

  test "POST /vehicles returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {modelId: model.id}
  end

  test "POST /vehicles with OAuth bearer token" do
    model = create(:model)

    assert_api_response :post, 201,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {modelId: model.id}
  end

  # PUT /vehicles/bulk
  test "PUT /vehicles/bulk updates the listed vehicles" do
    vehicles = create_list(:vehicle, 3, user: @user)
    sign_in @user

    assert_api_response :put, 204, body: {ids: vehicles.map(&:id), wanted: true}
  end

  test "PUT /vehicles/bulk returns 401 when not signed in" do
    vehicles = create_list(:vehicle, 3, user: @user)

    assert_api_response :put, 401, body: {ids: vehicles.map(&:id), wanted: true}
  end

  test "PUT /vehicles/bulk with OAuth bearer token" do
    vehicles = create_list(:vehicle, 3, user: @user)

    assert_api_response :put, 204,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {ids: vehicles.map(&:id), wanted: true}
  end

  # DELETE /vehicles/destroy-all-ingame
  test "DELETE /vehicles/destroy-all-ingame keeps non-ingame vehicles" do
    create_list(:vehicle, 3, user: @user, bought_via: :pledge_store)
    create_list(:vehicle, 3, user: @user, bought_via: :ingame)
    sign_in @user

    assert_api_response :delete, 204 do
      assert_equal 3, @user.vehicles.where(bought_via: :pledge_store).count
      assert_equal 0, @user.vehicles.where(bought_via: :ingame).count
    end
  end

  test "DELETE /vehicles/destroy-all-ingame returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  test "DELETE /vehicles/destroy-all-ingame with OAuth bearer token" do
    create_list(:vehicle, 2, user: @user, bought_via: :ingame)

    assert_api_response :delete, 204, headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
  end

  # DELETE /vehicles/:id
  test "DELETE /vehicles/:id removes the vehicle" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: vehicle.id}
  end

  test "DELETE /vehicles/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :delete, 401, path_params: {id: vehicle.id}
  end

  test "DELETE /vehicles/:id with OAuth bearer token" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :delete, 200,
      path_params: {id: vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
  end

  # GET /vehicles/:id
  test "GET /vehicles/:id returns the vehicle" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: vehicle.id}
  end

  test "GET /vehicles/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :get, 401, path_params: {id: vehicle.id}
  end

  test "GET /vehicles/:id with OAuth bearer token" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :get, 200,
      path_params: {id: vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end

  # PUT /vehicles/:id
  test "PUT /vehicles/:id updates the vehicle" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {name: "Enterprise A"}
  end

  # The controller sets `whodunnit` from `current_resource_owner`, so the owner
  # is on the record the moment their edit is filed at all -- which it was not
  # until the `author_id` gate came off.
  test "PUT /vehicles/:id records the change against the user who made it" do
    vehicle = create(:vehicle, user: @user)
    sign_in @user

    assert_difference -> { PaperTrail::Version.where(item_type: "Vehicle", item_id: vehicle.id).count }, 1 do
      assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {name: "Enterprise A"}
    end

    version = PaperTrail::Version
      .where(item_type: "Vehicle", item_id: vehicle.id).order(created_at: :desc).first

    assert_equal "Enterprise A", version.changeset["name"].last
    assert_equal @user.id, version.whodunnit
    assert_nil version.author_id, "an owner's own edit is not an admin action"
  end

  test "PUT /vehicles/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :put, 401, path_params: {id: vehicle.id}, body: {name: "x"}
  end

  test "PUT /vehicles/:id with OAuth bearer token" do
    vehicle = create(:vehicle, user: @user)

    assert_api_response :put, 200,
      path_params: {id: vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "Enterprise A"}
  end
end

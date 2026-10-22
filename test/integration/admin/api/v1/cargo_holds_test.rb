# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::CargoHoldsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/cargo-holds" do
    get("Cargo Holds list") do
      operationId "listCargoHolds"
      tags "CargoHolds"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: CargoHold.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::CargoHoldQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Models::CargoHolds::AdminCargoHolds
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/cargo-holds/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Cargo Hold") do
      operationId "updateCargoHold"
      tags "CargoHolds"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::CargoHoldInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Models::CargoHolds::AdminCargoHold
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:cargo_holds])
  end

  # GET /cargo-holds
  test "GET /cargo-holds lists cargo holds" do
    create_list(:cargo_hold, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /cargo-holds returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /cargo-holds returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # PUT /cargo-holds/{id}
  test "PUT /cargo-holds/{id} updates the cargo hold offsets" do
    cargo_hold = create(:cargo_hold)
    sign_in @user

    body = {offsetX: 2.5, offsetY: 1.0, offsetZ: 0.0}
    assert_api_response :put, 200, path_params: {id: cargo_hold.id}, body: body do
      assert_equal 2.5, parsed_body["offsetX"]
      assert_equal 1.0, parsed_body["offsetY"]
      assert_equal 0.0, parsed_body["offsetZ"]
    end
  end

  test "PUT /cargo-holds/{id} limits the crates the hold can be loaded with" do
    cargo_hold = create(:cargo_hold, dimension_x: 2.5, dimension_y: 3.75, dimension_z: 2.5, capacity_scu: 12, max_container_size_scu: 8)
    cargo_hold.calculate_container_capacities!
    sign_in @user

    assert_api_response :put, 200, path_params: {id: cargo_hold.id}, body: {maxLoadableContainerSizeScu: 2} do
      assert_equal 2, parsed_body["maxLoadableContainerSizeScu"]
      assert_equal 8, parsed_body["maxContainerSizeScu"]
    end

    capacities = cargo_hold.cargo_hold_container_capacities.reload.to_h { |capacity| [capacity.container_size_scu, capacity.max_quantity] }
    assert_equal 0, capacities[8]
    assert_equal 0, capacities[4]
    assert_equal 6, capacities[2]
  end

  test "PUT /cargo-holds/{id} rejects a crate size that does not exist" do
    cargo_hold = create(:cargo_hold)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: cargo_hold.id}, body: {maxLoadableContainerSizeScu: 3}
  end

  test "PUT /cargo-holds/{id} rejects a limit the grid already stays under" do
    cargo_hold = create(:cargo_hold, max_container_size_scu: 2)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: cargo_hold.id}, body: {maxLoadableContainerSizeScu: 4}
  end

  test "PUT /cargo-holds/{id} returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404,
      path_params: {id: "00000000-0000-0000-0000-000000000000"},
      body: {offsetX: 0, offsetY: 0, offsetZ: 0}
  end

  test "PUT /cargo-holds/{id} returns 401 when not signed in" do
    cargo_hold = create(:cargo_hold)

    assert_api_response :put, 401,
      path_params: {id: cargo_hold.id},
      body: {offsetX: 0, offsetY: 0, offsetZ: 0}
  end

  test "PUT /cargo-holds/{id} returns 403 for admin without access" do
    cargo_hold = create(:cargo_hold)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403,
      path_params: {id: cargo_hold.id},
      body: {offsetX: 0, offsetY: 0, offsetZ: 0}
  end
end

# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::VehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/vehicles" do
    get("Vehicles list") do
      operationId "vehicles"
      tags "Vehicles"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Vehicle.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/VehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Vehicles"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "Vehicle id", schema: {type: :string, format: :uuid}

    # Operation order matches the alphabetical load order of the original
    # spec files (destroy_spec, show_spec, update_spec) so schema output
    # stays byte-identical to pre-migration.

    delete("Destroy Vehicle") do
      operationId "destroyVehicle"
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Vehicle Detail") do
      operationId "vehicle"
      tags "Vehicles"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Update Vehicle") do
      operationId "updateVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/VehicleInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:admin_user, resource_access: [:vehicles])
  end

  # GET /vehicles
  test "GET /vehicles lists vehicles" do
    create_list(:vehicle, 3)
    create_list(:vehicle, 3, :with_name)
    sign_in @admin

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /vehicles filters by nameCont query" do
    create_list(:vehicle, 3)
    named = create_list(:vehicle, 3, :with_name)
    sign_in @admin

    assert_api_response :get, 200, params: {q: {"nameCont" => named.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /vehicles paginates with perPage" do
    create_list(:vehicle, 3)
    create_list(:vehicle, 3, :with_name)
    sign_in @admin

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
      assert_equal 3, parsed_body.dig("meta", "pagination", "totalPages")
    end
  end

  test "GET /vehicles returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /vehicles returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # GET /vehicles/{id}
  test "GET /vehicles/:id returns the vehicle" do
    vehicle = create(:vehicle)
    sign_in @admin

    assert_api_response :get, 200, path_params: {id: vehicle.id}
  end

  test "GET /vehicles/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /vehicles/:id returns 403 for admin without access" do
    vehicle = create(:vehicle)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: vehicle.id}
  end

  test "GET /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle)

    assert_api_response :get, 401, path_params: {id: vehicle.id}
  end

  # PUT /vehicles/{id}
  test "PUT /vehicles/:id updates the vehicle" do
    vehicle = create(:vehicle, :with_name)
    sign_in @admin

    assert_api_response :put, 200, path_params: {id: vehicle.id}, body: {name: "Updated Vehicle"} do
      assert_equal "Updated Vehicle", parsed_body["name"]
    end
  end

  test "PUT /vehicles/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /vehicles/:id returns 403 for admin without access" do
    vehicle = create(:vehicle)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: vehicle.id}, body: {name: "x"}
  end

  test "PUT /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle)

    assert_api_response :put, 401, path_params: {id: vehicle.id}, body: {name: "x"}
  end

  # DELETE /vehicles/{id}
  test "DELETE /vehicles/:id destroys the vehicle" do
    vehicle = create(:vehicle)
    sign_in @admin

    assert_api_response :delete, 200, path_params: {id: vehicle.id}
  end

  test "DELETE /vehicles/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /vehicles/:id returns 403 for admin without access" do
    vehicle = create(:vehicle)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: vehicle.id}
  end

  test "DELETE /vehicles/:id returns 401 when not signed in" do
    vehicle = create(:vehicle)

    assert_api_response :delete, 401, path_params: {id: vehicle.id}
  end
end

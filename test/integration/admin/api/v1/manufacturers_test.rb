# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ManufacturersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update). /options is in
  # a separate test class to avoid context-resolution collision with
  # /manufacturers under the Minitest adapter (both shapes have no
  # path params).

  api_path "/manufacturers" do
    post("Create Manufacturer") do
      operationId "createManufacturer"
      tags "Manufacturers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ManufacturerInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturer"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Manufacturers list") do
      operationId "manufacturers"
      tags "Manufacturers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Manufacturer.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ManufacturerQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/manufacturers/{id}" do
    parameter name: "id", in: :path, description: "Manufacturer id", schema: {type: :string, format: :uuid}

    delete("Destroy Manufacturer") do
      operationId "destroyManufacturer"
      tags "Manufacturers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturer"
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

    get("Manufacturer Detail") do
      operationId "manufacturer"
      tags "Manufacturers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturer"
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

    put("Update Manufacturer") do
      operationId "updateManufacturer"
      tags "Manufacturers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ManufacturerInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturer"
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
    @user = create(:admin_user, resource_access: [:manufacturers])
  end

  # POST
  test "POST /manufacturers creates a manufacturer" do
    sign_in @user

    assert_api_response :post, 200, body: {name: "Roberts Space Industries"} do
      assert_equal "Roberts Space Industries", parsed_body["name"]
    end
  end

  test "POST /manufacturers returns 401 when not signed in" do
    assert_api_response :post, 401, body: {name: "x"}
  end

  test "POST /manufacturers returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "x"}
  end

  # GET list
  test "GET /manufacturers lists manufacturers" do
    create_list(:manufacturer, 3)
    create_list(:manufacturer, 3, :with_models)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 6, parsed_body["items"].count
    end
  end

  test "GET /manufacturers filters by withModels" do
    create_list(:manufacturer, 3)
    create_list(:manufacturer, 3, :with_models)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"withModels" => true}} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /manufacturers paginates with perPage" do
    create_list(:manufacturer, 3)
    create_list(:manufacturer, 3, :with_models)
    sign_in @user

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /manufacturers returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /manufacturers returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE
  test "DELETE /manufacturers/:id destroys the manufacturer" do
    manufacturer = create(:manufacturer)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: manufacturer.id}
  end

  test "DELETE /manufacturers/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /manufacturers/:id returns 401 when not signed in" do
    manufacturer = create(:manufacturer)

    assert_api_response :delete, 401, path_params: {id: manufacturer.id}
  end

  test "DELETE /manufacturers/:id returns 403 for admin without access" do
    manufacturer = create(:manufacturer)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: manufacturer.id}
  end

  # GET single
  test "GET /manufacturers/:id returns the manufacturer" do
    manufacturer = create(:manufacturer)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: manufacturer.id}
  end

  test "GET /manufacturers/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "c1a705dd-21ad-46f6-ba3d-9dbf506f8033"}
  end

  test "GET /manufacturers/:id returns 401 when not signed in" do
    manufacturer = create(:manufacturer)

    assert_api_response :get, 401, path_params: {id: manufacturer.id}
  end

  test "GET /manufacturers/:id returns 403 for admin without access" do
    manufacturer = create(:manufacturer)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: manufacturer.id}
  end

  # PUT
  test "PUT /manufacturers/:id updates the manufacturer" do
    manufacturer = create(:manufacturer)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: manufacturer.id}, body: {name: "Updated Manufacturer"} do
      assert_equal "Updated Manufacturer", parsed_body["name"]
    end
  end

  test "PUT /manufacturers/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /manufacturers/:id returns 401 when not signed in" do
    manufacturer = create(:manufacturer)

    assert_api_response :put, 401, path_params: {id: manufacturer.id}, body: {name: "x"}
  end

  test "PUT /manufacturers/:id returns 403 for admin without access" do
    manufacturer = create(:manufacturer)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: manufacturer.id}, body: {name: "x"}
  end
end

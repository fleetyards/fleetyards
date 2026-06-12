# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ModelModulePackagesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/model-module-packages" do
    post("Create Model Module Package") do
      operationId "createModelModulePackage"
      tags "ModelModulePackages"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelModulePackageInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackage"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Model Module Packages list") do
      operationId "listModelModulePackages"
      tags "ModelModulePackages"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModulePackage.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelModulePackageQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackages"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-module-packages/{id}" do
    parameter name: "id", in: :path, description: "Model Module Package id", schema: {type: :string, format: :uuid}

    delete("Destroy Model Module Package") do
      operationId "destroyModelModulePackage"
      tags "ModelModulePackages"
      produces "application/json"

      response(204, "successful")

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

    get("Model Module Package Detail") do
      operationId "modelModulePackage"
      tags "ModelModulePackages"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackage"
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

    put("Update Model Module Package") do
      operationId "updateModelModulePackage"
      tags "ModelModulePackages"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelModulePackageInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackage"
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
    @user = create(:admin_user, resource_access: [:model_module_packages])
  end

  # POST /model-module-packages
  test "POST /model-module-packages creates a package" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 200, body: {name: "Starter Package", modelId: model.id} do
      assert_equal "Starter Package", parsed_body["name"]
    end
  end

  test "POST /model-module-packages returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {name: "x", modelId: model.id}
  end

  test "POST /model-module-packages returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "x", modelId: model.id}
  end

  # GET /model-module-packages
  test "GET /model-module-packages lists packages" do
    create_list(:model_module_package, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /model-module-packages filters by nameCont query" do
    packages = create_list(:model_module_package, 3)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"nameCont" => packages.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /model-module-packages returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-module-packages returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /model-module-packages/:id
  test "DELETE /model-module-packages/:id destroys the package" do
    package = create(:model_module_package)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: package.id}
  end

  test "DELETE /model-module-packages/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /model-module-packages/:id returns 401 when not signed in" do
    package = create(:model_module_package)

    assert_api_response :delete, 401, path_params: {id: package.id}
  end

  test "DELETE /model-module-packages/:id returns 403 for admin without access" do
    package = create(:model_module_package)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: package.id}
  end

  # GET /model-module-packages/:id
  test "GET /model-module-packages/:id returns the package" do
    package = create(:model_module_package)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: package.id}
  end

  test "GET /model-module-packages/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /model-module-packages/:id returns 401 when not signed in" do
    package = create(:model_module_package)

    assert_api_response :get, 401, path_params: {id: package.id}
  end

  test "GET /model-module-packages/:id returns 403 for admin without access" do
    package = create(:model_module_package)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: package.id}
  end

  # PUT /model-module-packages/:id
  test "PUT /model-module-packages/:id updates the package" do
    package = create(:model_module_package)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: package.id}, body: {name: "Updated Package"} do
      assert_equal "Updated Package", parsed_body["name"]
    end
  end

  test "PUT /model-module-packages/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /model-module-packages/:id returns 401 when not signed in" do
    package = create(:model_module_package)

    assert_api_response :put, 401, path_params: {id: package.id}, body: {name: "x"}
  end

  test "PUT /model-module-packages/:id returns 403 for admin without access" do
    package = create(:model_module_package)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: package.id}, body: {name: "x"}
  end
end

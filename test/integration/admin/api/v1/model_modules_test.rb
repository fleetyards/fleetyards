# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelModulesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/model-modules" do
    post("Create new Model Module") do
      operationId "createModelModule"
      tags "ModelModules"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::ModelModuleInput

      response(201, "successful") do
        schema ::Admin::V1::Schemas::Models::Modules::ModelModule
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Model Modules list") do
      operationId "listModelModules"
      tags "ModelModules"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::ModelModuleQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Models::Modules::ModelModules
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/model-modules/bulk" do
    delete("Bulk destroy model modules") do
      operationId "destroyBulkModelModule"
      tags "ModelModules"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::ModelModuleDestroyBulkInput

      response(204, "successful")

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Bulk update model modules") do
      operationId "updateBulkModelModule"
      tags "ModelModules"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::ModelModuleUpdateBulkInput

      response(200, "successful")

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/model-modules/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Model Module destroy") do
      operationId "destroyModelModule"
      tags "ModelModules"

      response(204, "successful")

      response(404, "not_found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Get Model Module") do
      operationId "modelModule"
      tags "ModelModules"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Models::Modules::ModelModule
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

    put("Update Model Module") do
      operationId "updateModelModule"
      tags "ModelModules"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::ModelModuleInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Models::Modules::ModelModule
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
    @user = create(:admin_user, resource_access: [:model_modules])
  end

  # POST /model-modules
  test "POST /model-modules creates a module and its hardpoint" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 201, body: {name: "Cargo Module", modelId: model.id} do
      created = ModelModule.last
      assert_equal 1, created.module_hardpoints.count
      assert_equal model.id, created.module_hardpoints.first.model_id
    end
  end

  test "POST /model-modules returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {name: "x", modelId: model.id}
  end

  test "POST /model-modules returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "x", modelId: model.id}
  end

  # GET /model-modules
  test "GET /model-modules lists modules" do
    create_list(:model_module, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  # The manufacturer edit page links straight here with the company selected, so
  # the list has to hold the filter the other catalogues already had.
  test "GET /model-modules filters by manufacturerIdIn" do
    manufacturer = create(:manufacturer)
    mine = create(:model_module, manufacturer:)
    create(:model_module)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"manufacturerIdIn" => [manufacturer.id]}} do
      assert_equal [mine.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /model-modules returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-modules returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /model-modules/bulk
  test "DELETE /model-modules/bulk destroys the listed modules" do
    modules = create_list(:model_module, 3)
    sign_in @user

    assert_api_response :delete, 204, body: {ids: modules.map(&:id)}
  end

  test "DELETE /model-modules/bulk returns 401 when not signed in" do
    modules = create_list(:model_module, 3)

    assert_api_response :delete, 401, body: {ids: modules.map(&:id)}
  end

  test "DELETE /model-modules/bulk returns 403 for admin without access" do
    modules = create_list(:model_module, 3)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, body: {ids: modules.map(&:id)}
  end

  # PUT /model-modules/bulk
  test "PUT /model-modules/bulk updates the listed modules" do
    modules = create_list(:model_module, 3)
    sign_in @user

    assert_api_response :put, 200, body: {ids: modules.map(&:id), active: true}
  end

  test "PUT /model-modules/bulk returns 401 when not signed in" do
    modules = create_list(:model_module, 3)

    assert_api_response :put, 401, body: {ids: modules.map(&:id), active: true}
  end

  test "PUT /model-modules/bulk returns 403 for admin without access" do
    modules = create_list(:model_module, 3)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, body: {ids: modules.map(&:id), active: true}
  end

  # DELETE /model-modules/:id
  test "DELETE /model-modules/:id destroys the module" do
    mod = create(:model_module)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: mod.id}
  end

  test "DELETE /model-modules/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /model-modules/:id returns 401 when not signed in" do
    mod = create(:model_module)

    assert_api_response :delete, 401, path_params: {id: mod.id}
  end

  test "DELETE /model-modules/:id returns 403 for admin without access" do
    mod = create(:model_module)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: mod.id}
  end

  # GET /model-modules/:id
  test "GET /model-modules/:id returns the module" do
    mod = create(:model_module)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: mod.id}
  end

  test "GET /model-modules/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /model-modules/:id returns 401 when not signed in" do
    mod = create(:model_module)

    assert_api_response :get, 401, path_params: {id: mod.id}
  end

  test "GET /model-modules/:id returns 403 for admin without access" do
    mod = create(:model_module)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: mod.id}
  end

  # PUT /model-modules/:id
  test "PUT /model-modules/:id updates the module" do
    mod = create(:model_module)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: mod.id}, body: {name: "Updated Module"}
  end

  # Clearing sends a null -- that is what the file input emits -- so the request
  # schema has to accept one, or the admin UI cannot remove a picture at all.
  test "PUT /model-modules/:id clears the store image" do
    mod = create(:model_module)
    mod.store_image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test.png")),
      filename: "test.png",
      content_type: "image/png"
    )
    sign_in @user

    assert_api_response :put, 200, path_params: {id: mod.id}, body: {storeImage: nil}

    assert_not_predicate mod.reload.store_image, :attached?
  end

  test "PUT /model-modules/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {name: "x"}
  end

  test "PUT /model-modules/:id returns 401 when not signed in" do
    mod = create(:model_module)

    assert_api_response :put, 401, path_params: {id: mod.id}, body: {name: "x"}
  end

  test "PUT /model-modules/:id returns 403 for admin without access" do
    mod = create(:model_module)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: mod.id}, body: {name: "x"}
  end
end

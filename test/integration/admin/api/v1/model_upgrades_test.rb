# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelUpgradesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/model-upgrades" do
    post("Create Model Upgrade") do
      operationId "createModelUpgrade"
      tags "ModelUpgrades"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelUpgradeInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Model Upgrades list") do
      operationId "listModelUpgrades"
      tags "ModelUpgrades"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelUpgrade.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelUpgradeQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrades"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-upgrades/{id}" do
    parameter name: "id", in: :path, description: "Model Upgrade id", schema: {type: :string, format: :uuid}

    delete("Destroy Model Upgrade") do
      operationId "destroyModelUpgrade"
      tags "ModelUpgrades"

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

    get("Model Upgrade Detail") do
      operationId "modelUpgrade"
      tags "ModelUpgrades"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"
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

    put("Update Model Upgrade") do
      operationId "updateModelUpgrade"
      tags "ModelUpgrades"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelUpgradeInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"
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
    @user = create(:admin_user, resource_access: [:model_upgrades])
  end

  # POST /model-upgrades
  test "POST /model-upgrades creates an upgrade and an upgrade kit" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 201, body: {name: "Warbond Upgrade", modelId: model.id} do
      created = ModelUpgrade.last
      assert_equal 1, created.upgrade_kits.count
      assert_equal model.id, created.upgrade_kits.first.model_id
    end
  end

  test "POST /model-upgrades returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {name: "x", modelId: model.id}
  end

  test "POST /model-upgrades returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "x", modelId: model.id}
  end

  # GET /model-upgrades
  test "GET /model-upgrades lists upgrades" do
    create_list(:model_upgrade, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /model-upgrades filters by nameCont query" do
    upgrades = create_list(:model_upgrade, 3)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"nameCont" => upgrades.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /model-upgrades returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-upgrades returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /model-upgrades/:id
  test "DELETE /model-upgrades/:id destroys the upgrade" do
    upgrade = create(:model_upgrade)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: upgrade.id}
  end

  test "DELETE /model-upgrades/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /model-upgrades/:id returns 401 when not signed in" do
    upgrade = create(:model_upgrade)

    assert_api_response :delete, 401, path_params: {id: upgrade.id}
  end

  test "DELETE /model-upgrades/:id returns 403 for admin without access" do
    upgrade = create(:model_upgrade)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: upgrade.id}
  end

  # GET /model-upgrades/:id
  test "GET /model-upgrades/:id returns the upgrade" do
    upgrade = create(:model_upgrade)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: upgrade.id}
  end

  test "GET /model-upgrades/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /model-upgrades/:id returns 401 when not signed in" do
    upgrade = create(:model_upgrade)

    assert_api_response :get, 401, path_params: {id: upgrade.id}
  end

  test "GET /model-upgrades/:id returns 403 for admin without access" do
    upgrade = create(:model_upgrade)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: upgrade.id}
  end

  # PUT /model-upgrades/:id
  test "PUT /model-upgrades/:id updates the upgrade" do
    upgrade = create(:model_upgrade)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: upgrade.id}, body: {name: "Updated Upgrade"} do
      assert_equal "Updated Upgrade", parsed_body["name"]
    end
  end

  test "PUT /model-upgrades/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /model-upgrades/:id returns 401 when not signed in" do
    upgrade = create(:model_upgrade)

    assert_api_response :put, 401, path_params: {id: upgrade.id}, body: {name: "x"}
  end

  test "PUT /model-upgrades/:id returns 403 for admin without access" do
    upgrade = create(:model_upgrade)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: upgrade.id}, body: {name: "x"}
  end
end

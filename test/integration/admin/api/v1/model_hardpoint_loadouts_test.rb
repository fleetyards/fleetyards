# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelHardpointLoadoutsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/model-hardpoint-loadouts" do
    post("Create Model Hardpoint Loadout") do
      operationId "createModelHardpointLoadout"
      tags "ModelHardpointLoadouts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelHardpointLoadoutInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpointLoadout"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Model Hardpoint Loadouts list") do
      operationId "listModelHardpointLoadouts"
      tags "ModelHardpointLoadouts"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelHardpointLoadoutQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpointLoadouts"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-hardpoint-loadouts/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Destroy Model Hardpoint Loadout") do
      operationId "destroyModelHardpointLoadout"
      tags "ModelHardpointLoadouts"

      response(204, "successful")

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Get Model Hardpoint Loadout") do
      operationId "modelHardpointLoadout"
      tags "ModelHardpointLoadouts"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpointLoadout"
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

    put("Update Model Hardpoint Loadout") do
      operationId "updateModelHardpointLoadout"
      tags "ModelHardpointLoadouts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelHardpointLoadoutInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpointLoadout"
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
    @user = create(:admin_user, resource_access: [:model_hardpoints])
  end

  # POST /model-hardpoint-loadouts
  test "POST /model-hardpoint-loadouts creates a loadout" do
    hardpoint = create(:model_hardpoint)
    sign_in @user

    assert_api_response :post, 201, body: {name: "Loadout 01", modelHardpointId: hardpoint.id}
  end

  test "POST /model-hardpoint-loadouts returns 400 for missing hardpoint" do
    sign_in @user

    assert_api_response :post, 400, body: {name: "Missing hardpoint"}
  end

  test "POST /model-hardpoint-loadouts returns 401 when not signed in" do
    hardpoint = create(:model_hardpoint)

    assert_api_response :post, 401, body: {name: "x", modelHardpointId: hardpoint.id}
  end

  test "POST /model-hardpoint-loadouts returns 403 for admin without access" do
    hardpoint = create(:model_hardpoint)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "x", modelHardpointId: hardpoint.id}
  end

  # GET /model-hardpoint-loadouts
  test "GET /model-hardpoint-loadouts lists loadouts" do
    create_list(:model_hardpoint_loadout, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /model-hardpoint-loadouts returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-hardpoint-loadouts returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /model-hardpoint-loadouts/:id
  test "DELETE /model-hardpoint-loadouts/:id destroys the loadout" do
    record = create(:model_hardpoint_loadout)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: record.id}
  end

  test "DELETE /model-hardpoint-loadouts/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /model-hardpoint-loadouts/:id returns 401 when not signed in" do
    record = create(:model_hardpoint_loadout)

    assert_api_response :delete, 401, path_params: {id: record.id}
  end

  test "DELETE /model-hardpoint-loadouts/:id returns 403 for admin without access" do
    record = create(:model_hardpoint_loadout)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: record.id}
  end

  # GET /model-hardpoint-loadouts/:id
  test "GET /model-hardpoint-loadouts/:id returns the record" do
    record = create(:model_hardpoint_loadout)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: record.id}
  end

  test "GET /model-hardpoint-loadouts/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /model-hardpoint-loadouts/:id returns 401 when not signed in" do
    record = create(:model_hardpoint_loadout)

    assert_api_response :get, 401, path_params: {id: record.id}
  end

  test "GET /model-hardpoint-loadouts/:id returns 403 for admin without access" do
    record = create(:model_hardpoint_loadout)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: record.id}
  end

  # PUT /model-hardpoint-loadouts/:id
  test "PUT /model-hardpoint-loadouts/:id updates the record" do
    record = create(:model_hardpoint_loadout)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: record.id}, body: {name: "Updated Loadout"}
  end

  test "PUT /model-hardpoint-loadouts/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {name: "x"}
  end

  test "PUT /model-hardpoint-loadouts/:id returns 401 when not signed in" do
    record = create(:model_hardpoint_loadout)

    assert_api_response :put, 401, path_params: {id: record.id}, body: {name: "x"}
  end

  test "PUT /model-hardpoint-loadouts/:id returns 403 for admin without access" do
    record = create(:model_hardpoint_loadout)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: record.id}, body: {name: "x"}
  end
end

# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::VersionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/versions" do
    get("Versions list") do
      operationId "versions"
      tags "Versions"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string}, required: false
      parameter name: "itemType", in: :query, schema: ::Admin::V1::Schemas::Enums::VersionItemTypeEnum, required: true
      parameter name: "itemId", in: :query, schema: {type: :string, format: :uuid}, required: true

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Versions
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

  api_path "/versions/{id}/revert" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Revert one field of a version") do
      operationId "revertVersion"
      tags "Versions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::VersionRevertInput

      response(204, "successful") do
        schema nil
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
    @user = create(:admin_user, resource_access: [:models])
    @model = create(:model, name: "Carrack", cargo: 456)
    @model.update!(cargo: 400)
    @version = @model.versions.last
  end

  def list_params(item = nil)
    item ||= @model

    {itemType: item.class.name, itemId: item.id}
  end

  # GET list
  test "GET /versions lists the history of one item" do
    sign_in @user

    assert_api_response :get, 200, params: list_params do
      assert_equal 1, parsed_body["items"].count
      assert_equal [{"field" => "cargo", "from" => "456.0", "to" => "400.0"}], parsed_body["items"].first["changes"]
    end
  end

  test "GET /versions returns 404 for a missing id" do
    sign_in @user

    assert_api_response :get, 404, params: {itemType: "Model", itemId: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /versions returns 401 when not signed in" do
    assert_api_response :get, 401, params: list_params
  end

  test "GET /versions returns 403 for an admin without access to the item" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, params: list_params
  end

  # A fleet's roles and inventories have no admin page of their own, so the
  # fleet's access is what decides.
  test "GET /versions authorises a fleet role through its fleet" do
    role = create(:fleet_role, name: "Quartermaster")
    role.update!(name: "Bosun")
    sign_in create(:admin_user, resource_access: [:fleets])

    assert_api_response :get, 200, params: list_params(role) do
      assert_equal role.versions.count, parsed_body["items"].count
    end
  end

  test "GET /versions returns 403 for a fleet role without fleet access" do
    role = create(:fleet_role, name: "Quartermaster")
    role.update!(name: "Bosun")
    sign_in @user

    assert_api_response :get, 403, params: list_params(role)
  end

  # PUT revert
  test "PUT /versions/:id/revert puts one field back" do
    sign_in @user

    assert_api_response :put, 204, path_params: {id: @version.id}, body: {field: "cargo"} do
      assert_equal 456, @model.reload.cargo
    end
  end

  test "PUT /versions/:id/revert records who reverted it and why" do
    sign_in @user

    assert_api_response :put, 204, path_params: {id: @version.id}, body: {field: "cargo"} do
      reverting = @model.reload.versions.last

      assert_equal @user.id, reverting.author_id
      assert_equal "custom", reverting.reason
      assert_equal "Reverted cargo", reverting.reason_description
    end
  end

  test "PUT /versions/:id/revert returns 400 for a field the version never changed" do
    sign_in @user

    assert_api_response :put, 400, path_params: {id: @version.id}, body: {field: "mass"}
  end

  test "PUT /versions/:id/revert returns 400 when the value is already back" do
    @model.update!(cargo: 456)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: @version.id}, body: {field: "cargo"}
  end

  # Six of the ten track creates too, and a create's changeset is every column
  # from nothing -- there is no previous value to go back to.
  test "PUT /versions/:id/revert returns 400 for a create version" do
    role = create(:fleet_role, name: "Quartermaster")
    creation = role.versions.find_by(event: "create")
    sign_in create(:admin_user, resource_access: [:fleets])

    assert_api_response :put, 400, path_params: {id: creation.id}, body: {field: "name"}
  end

  test "PUT /versions/:id/revert returns 404 for a missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {field: "cargo"}
  end

  test "PUT /versions/:id/revert returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: @version.id}, body: {field: "cargo"}
  end

  test "PUT /versions/:id/revert returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: @version.id}, body: {field: "cargo"}
  end
end

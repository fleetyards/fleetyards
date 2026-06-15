# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ImportsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/imports" do
    get("Imports list") do
      operationId "imports"
      description "Get a List of Imports"
      produces "application/json"
      tags "Imports"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Import.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ImportQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Imports"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/imports/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id", required: true

    get("Import Detail") do
      operationId "import"
      tags "Imports"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Import"
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
    @user = create(:admin_user, resource_access: [:imports])
  end

  # GET /imports
  test "GET /imports lists all imports" do
    create_list(:import, 10)
    sign_in @user

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /imports filters by type query" do
    imports = create_list(:import, 10)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"typeEq" => imports.first.type}} do
      assert_equal Import.where(type: imports.first.type).count, parsed_body["items"].count
    end
  end

  test "GET /imports filters by admin_user requester" do
    admin_user = create(:admin_user)
    admin_import = create(:import, :model_import, admin_user: admin_user)
    create(:import, :hangar_sync, user: create(:user))
    create(:import, :model_import)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"adminUserUsernameIn" => [admin_user.username]}} do
      assert_equal [admin_import.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /imports filters by user requester" do
    hangar_user = create(:user)
    user_import = create(:import, :hangar_sync, user: hangar_user)
    create(:import, :model_import, admin_user: create(:admin_user))
    create(:import, :model_import)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"userUsernameIn" => [hangar_user.username]}} do
      assert_equal [user_import.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /imports filters by includeSystem" do
    create(:import, :model_import, admin_user: create(:admin_user))
    create(:import, :hangar_sync, user: create(:user))
    system_import = create(:import, :model_import)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"includeSystem" => "true"}} do
      assert_equal [system_import.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /imports OR-combines requester filters" do
    admin_user = create(:admin_user)
    admin_import = create(:import, :model_import, admin_user: admin_user)
    create(:import, :hangar_sync, user: create(:user))
    system_import = create(:import, :model_import)
    sign_in @user

    assert_api_response :get, 200,
      params: {q: {"adminUserUsernameIn" => [admin_user.username], "includeSystem" => "true"}} do
      assert_equal [admin_import.id, system_import.id].sort, parsed_body["items"].pluck("id").sort
    end
  end

  test "GET /imports returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  # GET /imports/{id}
  test "GET /imports/{id} returns the import" do
    import = create(:import)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: import.id}
  end

  test "GET /imports/{id} returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /imports/{id} returns 401 when not signed in" do
    import = create(:import)

    assert_api_response :get, 401, path_params: {id: import.id}
  end

  test "GET /imports/{id} returns 403 for admin without access" do
    import = create(:import)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: import.id}
  end
end

# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::UsersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/users" do
    get("Users list") do
      operationId "users"
      tags "Users"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: User.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/UserQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Users"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/users/{id}" do
    parameter name: "id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    delete("Destroy User") do
      operationId "destroyUser"
      tags "Users"
      produces "application/json"

      parameter name: :destroy_fleets, in: :query, required: false, schema: {type: :boolean},
        description: "Also destroy fleets where the user is the sole admin but other members exist"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"
      end

      response(400, "blocked by permanent fleet role") do
        schema "$ref": "#/components/schemas/ValidationError"
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

    get("User Detail") do
      operationId "user"
      tags "Users"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"
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

    put("Update User") do
      operationId "updateUser"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/UserInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"
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
    @admin = create(:admin_user, resource_access: [:users])
  end

  # GET /users
  test "GET /users lists users" do
    create_list(:user, 7)
    sign_in @admin

    assert_api_response :get, 200 do
      assert_equal 7, parsed_body["items"].count
    end
  end

  test "GET /users filters by usernameCont" do
    users = create_list(:user, 7)
    sign_in @admin

    assert_api_response :get, 200, params: {q: {"usernameCont" => users.first.username}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /users honours perPage" do
    create_list(:user, 7)
    sign_in @admin

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /users returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /users returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /users/:id
  test "DELETE /users/:id destroys the user" do
    user = create(:user)
    sign_in @admin

    assert_api_response :delete, 200, path_params: {id: user.id}
  end

  test "DELETE /users/:id destroys the user when sole fleet admin" do
    user = create(:user)
    create(:fleet, admins: [user])
    sign_in @admin

    assert_api_response :delete, 200, path_params: {id: user.id}
  end

  test "DELETE /users/:id with destroy_fleets=true removes multi-member fleet" do
    user = create(:user)
    other = create(:user)
    create(:fleet, admins: [user], members: [other])
    sign_in @admin

    assert_api_response :delete, 200, path_params: {id: user.id}, params: {destroy_fleets: true}
  end

  test "DELETE /users/:id returns 400 when blocked by permanent fleet role" do
    user = create(:user)
    other = create(:user)
    create(:fleet, admins: [user], members: [other])
    sign_in @admin

    assert_api_response :delete, 400, path_params: {id: user.id}
  end

  test "DELETE /users/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /users/:id returns 401 when not signed in" do
    user = create(:user)

    assert_api_response :delete, 401, path_params: {id: user.id}
  end

  test "DELETE /users/:id returns 403 for admin without access" do
    user = create(:user)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: user.id}
  end

  # GET /users/:id
  test "GET /users/:id returns the user" do
    user = create(:user)
    sign_in @admin

    assert_api_response :get, 200, path_params: {id: user.id}
  end

  test "GET /users/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /users/:id returns 401 when not signed in" do
    user = create(:user)

    assert_api_response :get, 401, path_params: {id: user.id}
  end

  test "GET /users/:id returns 403 for admin without access" do
    user = create(:user)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: user.id}
  end

  # PUT /users/:id
  test "PUT /users/:id updates the user" do
    user = create(:user)
    sign_in @admin

    assert_api_response :put, 200, path_params: {id: user.id}, body: {username: "updated_username"} do
      assert_equal "updated_username", parsed_body["username"]
    end
  end

  test "PUT /users/:id returns 404 for missing id" do
    sign_in @admin

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {username: "x"}
  end

  test "PUT /users/:id returns 401 when not signed in" do
    user = create(:user)

    assert_api_response :put, 401, path_params: {id: user.id}, body: {username: "x"}
  end

  test "PUT /users/:id returns 403 for admin without access" do
    user = create(:user)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: user.id}, body: {username: "x"}
  end
end

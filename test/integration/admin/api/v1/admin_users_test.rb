# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::AdminUsersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/admin_users" do
    post("Create Admin User") do
      operationId "createAdminUser"
      tags "AdminUsers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/AdminUserInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUser"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Admin Users list") do
      operationId "adminUsers"
      tags "AdminUsers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUsers"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/admin_users/{id}" do
    parameter name: "id", in: :path, description: "Admin User id", schema: {type: :string, format: :uuid}

    delete("Destroy Admin User") do
      operationId "destroyAdminUser"
      tags "AdminUsers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUser"
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

    get("Admin User Detail") do
      operationId "adminUser"
      tags "AdminUsers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUser"
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

    put("Update Admin User") do
      operationId "updateAdminUser"
      tags "AdminUsers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/AdminUserInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminUser"
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
    @super_admin = create(:admin_user, super_admin: true)
  end

  # POST /admin_users
  test "POST /admin_users creates an admin user" do
    sign_in @super_admin

    body = {
      username: "newadmin",
      email: "newadmin@example.com",
      password: "password123",
      passwordConfirmation: "password123"
    }
    assert_api_response :post, 200, body: body do
      assert_equal "newadmin", parsed_body["username"]
    end
  end

  test "POST /admin_users returns 401 when not signed in" do
    body = {username: "x", email: "x@example.com", password: "password123", passwordConfirmation: "password123"}
    assert_api_response :post, 401, body: body
  end

  test "POST /admin_users returns 403 for non-super-admin" do
    sign_in create(:admin_user, super_admin: false)

    body = {username: "x", email: "x@example.com", password: "password123", passwordConfirmation: "password123"}
    assert_api_response :post, 403, body: body
  end

  # GET /admin_users
  test "GET /admin_users lists admin users" do
    create_list(:admin_user, 3)
    sign_in @super_admin

    assert_api_response :get, 200
  end

  test "GET /admin_users returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /admin_users returns 403 for non-super-admin" do
    sign_in create(:admin_user, super_admin: false)

    assert_api_response :get, 403
  end

  # DELETE /admin_users/:id
  test "DELETE /admin_users/:id destroys the admin user" do
    target = create(:admin_user)
    sign_in @super_admin

    assert_api_response :delete, 200, path_params: {id: target.id}
  end

  test "DELETE /admin_users/:id returns 404 for missing id" do
    sign_in @super_admin

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /admin_users/:id returns 401 when not signed in" do
    target = create(:admin_user)

    assert_api_response :delete, 401, path_params: {id: target.id}
  end

  test "DELETE /admin_users/:id returns 403 for non-super-admin" do
    target = create(:admin_user)
    sign_in create(:admin_user, super_admin: false)

    assert_api_response :delete, 403, path_params: {id: target.id}
  end

  # GET /admin_users/:id
  test "GET /admin_users/:id returns the admin user" do
    target = create(:admin_user)
    sign_in @super_admin

    assert_api_response :get, 200, path_params: {id: target.id}
  end

  test "GET /admin_users/:id returns 404 for missing id" do
    sign_in @super_admin

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /admin_users/:id returns 401 when not signed in" do
    target = create(:admin_user)

    assert_api_response :get, 401, path_params: {id: target.id}
  end

  test "GET /admin_users/:id returns 403 for admin without access" do
    target = create(:admin_user)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: target.id}
  end

  # PUT /admin_users/:id
  test "PUT /admin_users/:id updates the admin user" do
    target = create(:admin_user)
    sign_in @super_admin

    assert_api_response :put, 200, path_params: {id: target.id}, body: {username: "updated_admin"} do
      assert_equal "updated_admin", parsed_body["username"]
    end
  end

  test "PUT /admin_users/:id returns 404 for missing id" do
    sign_in @super_admin

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {username: "x"}
  end

  test "PUT /admin_users/:id returns 401 when not signed in" do
    target = create(:admin_user)

    assert_api_response :put, 401, path_params: {id: target.id}, body: {username: "x"}
  end

  test "PUT /admin_users/:id returns 403 for non-super-admin" do
    target = create(:admin_user)
    sign_in create(:admin_user, super_admin: false)

    assert_api_response :put, 403, path_params: {id: target.id}, body: {username: "x"}
  end
end

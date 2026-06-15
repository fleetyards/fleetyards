# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::OauthApplicationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/oauth-applications" do
    post("Create OAuth Application") do
      operationId "createOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/OauthApplicationInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("OAuth Applications list") do
      operationId "oauthApplications"
      tags "OauthApplications"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/OauthApplicationQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplications"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/oauth-applications/{id}" do
    parameter name: "id", in: :path, description: "OAuth Application id", schema: {type: :string, format: :uuid}

    delete("Destroy OAuth Application") do
      operationId "destroyOauthApplication"
      tags "OauthApplications"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"
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

    get("OAuth Application detail") do
      operationId "oauthApplication"
      tags "OauthApplications"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"
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

    put("Update OAuth Application") do
      operationId "updateOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/OauthApplicationUpdateInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"
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
    @user = create(:admin_user, resource_access: [:oauth_applications])
  end

  # POST
  test "POST /oauth-applications creates an application" do
    sign_in @user

    body = {name: "Admin App", redirectUri: "https://example.com/callback", confidential: true}
    assert_api_response :post, 201, body: body do
      assert_equal "Admin App", parsed_body["name"]
    end
  end

  test "POST /oauth-applications returns 401 when not signed in" do
    body = {name: "x", redirectUri: "https://example.com/callback", confidential: true}
    assert_api_response :post, 401, body: body
  end

  test "POST /oauth-applications returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    body = {name: "x", redirectUri: "https://example.com/callback", confidential: true}
    assert_api_response :post, 403, body: body
  end

  # GET list
  test "GET /oauth-applications lists applications" do
    create_list(:oauth_application, 3)
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /oauth-applications returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /oauth-applications returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE
  test "DELETE /oauth-applications/:id destroys the application" do
    app = create(:oauth_application)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: app.id}
  end

  test "DELETE /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application)

    assert_api_response :delete, 401, path_params: {id: app.id}
  end

  test "DELETE /oauth-applications/:id returns 403 for admin without access" do
    app = create(:oauth_application)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: app.id}
  end

  # GET single
  test "GET /oauth-applications/:id returns the application" do
    app = create(:oauth_application)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: app.id}
  end

  test "GET /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application)

    assert_api_response :get, 401, path_params: {id: app.id}
  end

  test "GET /oauth-applications/:id returns 403 for admin without access" do
    app = create(:oauth_application)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: app.id}
  end

  # PUT
  test "PUT /oauth-applications/:id updates the application" do
    app = create(:oauth_application)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: app.id}, body: {name: "Updated Admin App"} do
      assert_equal "Updated Admin App", parsed_body["name"]
    end
  end

  test "PUT /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application)

    assert_api_response :put, 401, path_params: {id: app.id}, body: {name: "x"}
  end

  test "PUT /oauth-applications/:id returns 403 for admin without access" do
    app = create(:oauth_application)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: app.id}, body: {name: "x"}
  end
end

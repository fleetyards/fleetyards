# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::OauthApplicationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/oauth-applications" do
    post("Create OAuth Application") do
      operationId "createOauthApplication"
      tags "OauthApplications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/OauthApplicationInput"}

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/OauthApplicationWithSecret"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("OAuth Applications list") do
      operationId "oauthApplications"
      tags "OauthApplications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/OauthApplication"}
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

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(204, "successful")

      response(404, "not found") do
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

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"
      end

      response(404, "not found") do
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

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/OauthApplication"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("oauth-applications")
    @user = create(:user)
  end

  test "POST /oauth-applications creates an app" do
    sign_in @user

    body = {name: "My App", redirectUri: "https://example.com/callback", confidential: true}
    assert_api_response :post, 201, body: body do
      assert_equal "My App", parsed_body["name"]
    end
  end

  test "POST /oauth-applications returns 400 for invalid body" do
    sign_in @user

    assert_api_response :post, 400, body: {name: ""}
  end

  test "POST /oauth-applications returns 401 when not signed in" do
    body = {name: "x", redirectUri: "https://example.com/callback", confidential: true}
    assert_api_response :post, 401, body: body
  end

  test "GET /oauth-applications lists user's apps" do
    create_list(:oauth_application, 3, owner: @user)
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /oauth-applications returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "DELETE /oauth-applications/:id destroys the app" do
    app = create(:oauth_application, owner: @user)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: app.id}
  end

  test "DELETE /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application, owner: @user)

    assert_api_response :delete, 401, path_params: {id: app.id}
  end

  test "GET /oauth-applications/:id returns the app" do
    app = create(:oauth_application, owner: @user)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: app.id}
  end

  test "GET /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application, owner: @user)

    assert_api_response :get, 401, path_params: {id: app.id}
  end

  test "PUT /oauth-applications/:id updates the app" do
    app = create(:oauth_application, owner: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: app.id}, body: {name: "Updated App"} do
      assert_equal "Updated App", parsed_body["name"]
    end
  end

  test "PUT /oauth-applications/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /oauth-applications/:id returns 401 when not signed in" do
    app = create(:oauth_application, owner: @user)

    assert_api_response :put, 401, path_params: {id: app.id}, body: {name: "x"}
  end
end

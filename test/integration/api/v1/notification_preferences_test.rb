# frozen_string_literal: true

require "openapi_helper"

class Api::V1::NotificationPreferencesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/notification-preferences" do
    get("List notification preferences") do
      operationId "notificationPreferences"
      tags "NotificationPreferences"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:read"]},
        {OpenId: ["notifications", "notifications:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/NotificationPreference"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notification-preferences/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}, required: true

    put("Update a notification preference") do
      operationId "updateNotificationPreference"
      tags "NotificationPreferences"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      request_body schema: {
        type: :object,
        properties: {
          app: {type: :boolean},
          mail: {type: :boolean},
          push: {type: :boolean}
        }
      }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/NotificationPreference"
      end

      response(404, "not found for invalid type")

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  # GET /notification-preferences
  test "GET /notification-preferences lists all preference types for the signed-in user" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal Notification.notification_types.count, parsed_body.count
      first = parsed_body.first
      assert_includes first.keys, "notificationType"
      assert_includes first.keys, "app"
      assert_includes first.keys, "mail"
      assert_includes first.keys, "push"
      assert_includes first.keys, "mailAvailable"
    end
  end

  test "GET /notification-preferences with valid OAuth read token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["notifications", "notifications:read"])

    assert_api_response :get, 200, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "GET /notification-preferences returns 401 with wrong-scope OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["public"])

    assert_api_response :get, 401, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "GET /notification-preferences returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  # PUT /notification-preferences/{id}
  test "PUT /notification-preferences/:id updates the preference" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "hangar_create"}, body: {app: false} do
      assert_equal "hangar_create", parsed_body["notificationType"]
      assert_equal false, parsed_body["app"]
    end
  end

  test "PUT /notification-preferences/:id with valid OAuth write token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["notifications", "notifications:write"])

    assert_api_response :put, 200,
      path_params: {id: "hangar_create"},
      body: {app: false},
      headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "PUT /notification-preferences/:id returns 404 for invalid type" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "invalid_type"}, body: {app: false}
  end

  test "PUT /notification-preferences/:id returns 401 with wrong-scope OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["public"])

    assert_api_response :put, 401,
      path_params: {id: "hangar_create"},
      body: {app: false},
      headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "PUT /notification-preferences/:id returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "hangar_create"}, body: {app: false}
  end
end

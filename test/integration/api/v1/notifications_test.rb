# frozen_string_literal: true

require "openapi_helper"

class Api::V1::NotificationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/notifications" do
    get("List notifications") do
      operationId "notifications"
      tags "Notifications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:read"]},
        {OpenId: ["notifications", "notifications:read"]}
      ]

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Notification.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Notifications"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/destroy-all" do
    delete("Delete all notifications") do
      operationId "destroyAllNotifications"
      tags "Notifications"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/read-all" do
    put("Mark all notifications as read") do
      operationId "readAllNotifications"
      tags "Notifications"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}, required: true

    delete("Delete a notification") do
      operationId "destroyNotification"
      tags "Notifications"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/{id}/read" do
    parameter name: "id", in: :path, schema: {type: :string}, required: true

    put("Mark notification as read") do
      operationId "readNotification"
      tags "Notifications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Notification"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  # GET /notifications
  test "GET /notifications lists the user's notifications" do
    create_list(:notification, 3, user: @user)
    create(:notification, :expired, user: @user)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /notifications filters by notification_type_eq" do
    create_list(:notification, 3, user: @user)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"notification_type_eq" => "hangar_create"}} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /notifications returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  # DELETE /notifications/destroy-all
  test "DELETE /notifications/destroy-all removes all notifications" do
    create_list(:notification, 3, user: @user)
    sign_in @user

    assert_api_response :delete, 204 do
      assert_equal 0, @user.notifications.count
    end
  end

  test "DELETE /notifications/destroy-all returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  # PUT /notifications/read-all
  test "PUT /notifications/read-all marks all notifications read" do
    create_list(:notification, 3, user: @user)
    sign_in @user

    assert_api_response :put, 204, body: {} do
      assert_equal 0, @user.notifications.unread.count
    end
  end

  test "PUT /notifications/read-all returns 401 when not signed in" do
    assert_api_response :put, 401, body: {}
  end

  # DELETE /notifications/:id
  test "DELETE /notifications/:id removes the notification" do
    notification = create(:notification, user: @user)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: notification.id} do
      assert_nil Notification.find_by(id: notification.id)
    end
  end

  test "DELETE /notifications/:id returns 401 when not signed in" do
    notification = create(:notification, user: @user)

    assert_api_response :delete, 401, path_params: {id: notification.id}
  end

  # PUT /notifications/:id/read
  test "PUT /notifications/:id/read marks the notification read" do
    notification = create(:notification, user: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: notification.id}, body: {} do
      assert_equal true, parsed_body["read"]
      assert parsed_body["readAt"].present?
    end
  end

  test "PUT /notifications/:id/read returns 401 when not signed in" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 401, path_params: {id: notification.id}, body: {}
  end

  # OAuth Bearer token variants.
  test "GET /notifications with OAuth bearer token" do
    create_list(:notification, 3, user: @user)

    assert_api_response :get, 200, headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:read"])
  end

  test "DELETE /notifications/destroy-all with OAuth bearer token" do
    create_list(:notification, 3, user: @user)

    assert_api_response :delete, 204, headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:write"])
  end

  test "PUT /notifications/read-all with OAuth bearer token" do
    create_list(:notification, 3, user: @user)

    assert_api_response :put, 204,
      headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:write"]),
      body: {}
  end

  test "DELETE /notifications/:id with OAuth bearer token" do
    notification = create(:notification, user: @user)

    assert_api_response :delete, 204,
      path_params: {id: notification.id},
      headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:write"])
  end

  test "PUT /notifications/:id/read with OAuth bearer token" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 200,
      path_params: {id: notification.id},
      headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:write"]),
      body: {}
  end
end

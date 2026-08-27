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

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Notification.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::NotificationQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Notifications
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/unread-count" do
    get("Unread notification count") do
      operationId "notificationsUnreadCount"
      tags "Notifications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:read"]},
        {OpenId: ["notifications", "notifications:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::NotificationUnreadCount
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
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
        schema ::Shared::V1::Schemas::StandardError
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
        schema ::Shared::V1::Schemas::StandardError
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
        schema ::Shared::V1::Schemas::StandardError
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
        schema ::V1::Schemas::Notification
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/{id}/unread" do
    parameter name: "id", in: :path, schema: {type: :string}, required: true

    put("Mark notification as unread") do
      operationId "unreadNotification"
      tags "Notifications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Notification
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/{id}/archive" do
    parameter name: "id", in: :path, schema: {type: :string}, required: true

    put("Archive a notification") do
      operationId "archiveNotification"
      tags "Notifications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Notification
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/{id}/unarchive" do
    parameter name: "id", in: :path, schema: {type: :string}, required: true

    put("Move a notification back to the inbox") do
      operationId "unarchiveNotification"
      tags "Notifications"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Notification
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
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

    assert_api_response :get, 200, api_path: "/notifications" do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /notifications files an expired notification into the archive" do
    create(:notification, :expired, user: @user, title: "expired")
    sign_in @user

    assert_api_response :get, 200, api_path: "/notifications", params: {q: {archivedAtNull: false}} do
      assert_equal ["expired"], parsed_body["items"].pluck("title")
    end
  end

  test "GET /notifications filters by notificationTypeEq" do
    create_list(:notification, 3, user: @user)
    sign_in @user

    assert_api_response :get, 200, api_path: "/notifications", params: {q: {"notificationTypeEq" => "hangar_create"}} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /notifications returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/notifications"
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

    assert_api_response :put, 204, api_path: "/notifications/read-all", body: {} do
      assert_equal 0, @user.notifications.unread.count
    end
  end

  test "PUT /notifications/read-all returns 401 when not signed in" do
    assert_api_response :put, 401, api_path: "/notifications/read-all", body: {}
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

    assert_api_response :put, 200, api_path: "/notifications/{id}/read", path_params: {id: notification.id}, body: {} do
      assert_equal true, parsed_body["read"]
      assert parsed_body["readAt"].present?
    end
  end

  test "PUT /notifications/:id/read returns 401 when not signed in" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/{id}/read", path_params: {id: notification.id}, body: {}
  end

  test "GET /notifications hides archived notifications from the inbox" do
    create(:notification, user: @user, title: "inbox")
    create(:notification, :archived, user: @user, title: "archived")
    sign_in @user

    assert_api_response :get, 200, api_path: "/notifications" do
      assert_equal ["inbox"], parsed_body["items"].pluck("title")
    end
  end

  test "GET /notifications lists the archive on archivedAtNull false" do
    create(:notification, user: @user, title: "inbox")
    create(:notification, :archived, user: @user, title: "archived")
    sign_in @user

    assert_api_response :get, 200, api_path: "/notifications", params: {q: {archivedAtNull: false}} do
      assert_equal ["archived"], parsed_body["items"].pluck("title")
    end
  end

  test "GET /notifications searches title and body" do
    create(:notification, user: @user, title: "Hangar Sync finished")
    create(:notification, user: @user, title: "Ship on sale", body: "The **Aurora MR** is on sale")
    sign_in @user

    assert_api_response :get, 200, api_path: "/notifications", params: {q: {searchCont: "aurora"}} do
      assert_equal ["Ship on sale"], parsed_body["items"].pluck("title")
    end
  end

  test "GET /notifications keeps unread notifications on top" do
    create(:notification, :read, user: @user, title: "read newest")
    travel(-1.hour) do
      create(:notification, user: @user, title: "unread older")
    end
    sign_in @user

    assert_api_response :get, 200, api_path: "/notifications" do
      assert_equal ["unread older", "read newest"], parsed_body["items"].pluck("title")
    end
  end

  # GET /notifications/unread-count
  test "GET /notifications/unread-count counts only unread inbox notifications" do
    create(:notification, user: @user)
    create(:notification, :read, user: @user)
    create(:notification, :archived, user: @user)
    create(:notification, :expired, user: @user)
    sign_in @user

    assert_api_response :get, 200, api_path: "/notifications/unread-count" do
      assert_equal 1, parsed_body["count"]
    end
  end

  test "GET /notifications/unread-count returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/notifications/unread-count"
  end

  # PUT /notifications/:id/unread
  test "PUT /notifications/:id/unread marks the notification unread" do
    notification = create(:notification, :read, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/{id}/unread", path_params: {id: notification.id}, body: {} do
      assert_equal false, parsed_body["read"]
      assert_nil parsed_body["readAt"]
    end
  end

  test "PUT /notifications/:id/unread returns 401 when not signed in" do
    notification = create(:notification, :read, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/{id}/unread", path_params: {id: notification.id}, body: {}
  end

  # PUT /notifications/:id/archive
  test "PUT /notifications/:id/archive archives the notification" do
    notification = create(:notification, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/{id}/archive", path_params: {id: notification.id}, body: {} do
      assert_equal true, parsed_body["archived"]
      assert parsed_body["archivedAt"].present?
    end
  end

  test "PUT /notifications/:id/archive returns 401 when not signed in" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/{id}/archive", path_params: {id: notification.id}, body: {}
  end

  # PUT /notifications/:id/unarchive
  test "PUT /notifications/:id/unarchive moves the notification back to the inbox" do
    notification = create(:notification, :archived, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/{id}/unarchive", path_params: {id: notification.id}, body: {} do
      assert_equal false, parsed_body["archived"]
      assert_nil parsed_body["archivedAt"]
    end
  end

  test "PUT /notifications/:id/unarchive returns 401 when not signed in" do
    notification = create(:notification, :archived, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/{id}/unarchive", path_params: {id: notification.id}, body: {}
  end

  # PUT /notifications/read-all
  test "PUT /notifications/read-all leaves the archive alone" do
    archived = create(:notification, :archived, user: @user)
    sign_in @user

    assert_api_response :put, 204, api_path: "/notifications/read-all", body: {} do
      assert_nil archived.reload.read_at
    end
  end

  # OAuth Bearer token variants.
  test "GET /notifications with OAuth bearer token" do
    create_list(:notification, 3, user: @user)

    assert_api_response :get, 200,
      api_path: "/notifications",
      headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:read"])
  end

  test "DELETE /notifications/destroy-all with OAuth bearer token" do
    create_list(:notification, 3, user: @user)

    assert_api_response :delete, 204, headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:write"])
  end

  test "PUT /notifications/read-all with OAuth bearer token" do
    create_list(:notification, 3, user: @user)

    assert_api_response :put, 204, api_path: "/notifications/read-all",
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

    assert_api_response :put, 200, api_path: "/notifications/{id}/read",
      path_params: {id: notification.id},
      headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:write"]),
      body: {}
  end
end

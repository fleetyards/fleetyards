# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::NotificationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/notifications" do
    get("Admin Notifications list") do
      operationId "adminNotifications"
      tags "Notifications"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: AdminNotification.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query, schema: {"$ref": "#/components/schemas/AdminNotificationQuery"}, required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminNotifications"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/unread-count" do
    get("Unread Admin Notification count") do
      operationId "adminNotificationsUnreadCount"
      tags "Notifications"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminNotificationUnreadCount"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/{id}/read" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Admin Notification id", required: true

    put("Mark Admin Notification as read") do
      operationId "readAdminNotification"
      tags "Notifications"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminNotification"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/read-all" do
    put("Mark all Admin Notifications as read") do
      operationId "readAllAdminNotifications"
      tags "Notifications"
      produces "application/json"

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Admin Notification id", required: true

    delete("Delete Admin Notification") do
      operationId "destroyAdminNotification"
      tags "Notifications"
      produces "application/json"

      response(204, "successful")

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/notifications/destroy-all" do
    delete("Delete all Admin Notifications") do
      operationId "destroyAllAdminNotifications"
      tags "Notifications"
      produces "application/json"

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin_user = create(:admin_user, resource_access: [:models])
    @other_admin = create(:admin_user, resource_access: [:models])
  end

  test "GET /notifications lists the signed in admin's notifications" do
    create(:admin_notification, admin_user: @admin_user)
    create(:admin_notification, admin_user: @other_admin)
    sign_in @admin_user

    assert_api_response :get, 200, api_path: "/notifications" do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /notifications hides expired notifications" do
    create(:admin_notification, :expired, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :get, 200, api_path: "/notifications" do
      assert_equal 0, parsed_body["items"].count
    end
  end

  test "GET /notifications filters by unread" do
    create(:admin_notification, :read, admin_user: @admin_user)
    create(:admin_notification, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :get, 200, api_path: "/notifications", params: {q: {readAtNull: true}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /notifications returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/notifications"
  end

  test "GET /notifications/unread-count counts only unread notifications" do
    create(:admin_notification, admin_user: @admin_user)
    create(:admin_notification, :read, admin_user: @admin_user)
    create(:admin_notification, admin_user: @other_admin)
    sign_in @admin_user

    assert_api_response :get, 200, api_path: "/notifications/unread-count" do
      assert_equal 1, parsed_body["count"]
    end
  end

  test "GET /notifications/unread-count returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/notifications/unread-count"
  end

  test "PUT /notifications/:id/read marks it read" do
    notification = create(:admin_notification, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, path_params: {id: notification.id} do
      assert parsed_body["read"]
    end
  end

  test "PUT /notifications/:id/read does not reach another admin's notification" do
    notification = create(:admin_notification, admin_user: @other_admin)
    sign_in @admin_user

    assert_api_response :put, 404, path_params: {id: notification.id}
  end

  test "PUT /notifications/:id/read returns 401 when not signed in" do
    notification = create(:admin_notification, admin_user: @admin_user)

    assert_api_response :put, 401, path_params: {id: notification.id}
  end

  test "PUT /notifications/read-all leaves other admins untouched" do
    create(:admin_notification, admin_user: @admin_user)
    other = create(:admin_notification, admin_user: @other_admin)
    sign_in @admin_user

    assert_api_response :put, 204

    assert_equal 0, AdminNotification.where(admin_user: @admin_user).unread.count
    assert_nil other.reload.read_at
  end

  test "PUT /notifications/read-all returns 401 when not signed in" do
    assert_api_response :put, 401
  end

  test "DELETE /notifications/:id removes it" do
    notification = create(:admin_notification, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :delete, 204, path_params: {id: notification.id}

    assert_nil AdminNotification.find_by(id: notification.id)
  end

  test "DELETE /notifications/:id does not reach another admin's notification" do
    notification = create(:admin_notification, admin_user: @other_admin)
    sign_in @admin_user

    assert_api_response :delete, 404, path_params: {id: notification.id}
  end

  test "DELETE /notifications/:id returns 401 when not signed in" do
    notification = create(:admin_notification, admin_user: @admin_user)

    assert_api_response :delete, 401, path_params: {id: notification.id}
  end

  test "DELETE /notifications/destroy-all leaves other admins untouched" do
    create(:admin_notification, admin_user: @admin_user)
    create(:admin_notification, admin_user: @other_admin)
    sign_in @admin_user

    assert_api_response :delete, 204

    assert_equal 0, AdminNotification.where(admin_user: @admin_user).count
    assert_equal 1, AdminNotification.where(admin_user: @other_admin).count
  end

  test "DELETE /notifications/destroy-all returns 401 when not signed in" do
    assert_api_response :delete, 401
  end
end

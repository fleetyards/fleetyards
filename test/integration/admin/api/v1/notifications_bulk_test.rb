# frozen_string_literal: true

require "openapi_helper"

# Every path here is a collection-level PUT, which the DSL cannot tell apart on
# the verb alone, so each assertion names its `api_path`.
class Admin::Api::V1::NotificationsBulkTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/notifications/read-bulk" do
    put("Mark the selected Admin Notifications as read") do
      operationId "readBulkAdminNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AdminNotificationBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminNotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/unread-bulk" do
    put("Mark the selected Admin Notifications as unread") do
      operationId "unreadBulkAdminNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AdminNotificationBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminNotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/archive-bulk" do
    put("Archive the selected Admin Notifications") do
      operationId "archiveBulkAdminNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AdminNotificationBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminNotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/unarchive-bulk" do
    put("Move the selected Admin Notifications back to the inbox") do
      operationId "unarchiveBulkAdminNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AdminNotificationBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminNotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/destroy-bulk" do
    put("Delete the selected Admin Notifications") do
      operationId "destroyBulkAdminNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AdminNotificationBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminNotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin_user = create(:admin_user, resource_access: [:models])
    @other_admin = create(:admin_user, resource_access: [:models])
  end

  # PUT /notifications/read-bulk
  test "PUT /notifications/read-bulk marks the listed notifications read" do
    selected = create_list(:admin_notification, 2, admin_user: @admin_user)
    untouched = create(:admin_notification, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert selected.all? { |notification| notification.reload.read? }
      assert_not untouched.reload.read?
    end
  end

  test "PUT /notifications/read-bulk on all reaches past the first page" do
    create_list(:admin_notification, AdminNotification.default_per_page + 5, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {all: true} do
      assert_equal AdminNotification.default_per_page + 5, parsed_body["count"]
    end
  end

  test "PUT /notifications/read-bulk on all honours the filter it was given" do
    create(:admin_notification, admin_user: @admin_user, title: "Paints Import Results")
    spared = create(:admin_notification, admin_user: @admin_user, title: "Loaner Sync")
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk",
      body: {all: true, q: {searchCont: "paints"}} do
      assert_equal 1, parsed_body["count"]
      assert_not spared.reload.read?
    end
  end

  test "PUT /notifications/read-bulk on all stays out of the archive" do
    archived = create(:admin_notification, :archived, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {all: true} do
      assert_equal 0, parsed_body["count"]
      assert_not archived.reload.read?
    end
  end

  # A body naming neither `ids` nor `all` must never be read as "everything":
  # the endpoint next door is `destroy-all`.
  test "PUT /notifications/read-bulk changes nothing when nothing is selected" do
    notification = create(:admin_notification, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {} do
      assert_equal 0, parsed_body["count"]
      assert_not notification.reload.read?
    end
  end

  test "PUT /notifications/read-bulk ignores another admin's notification" do
    stranger = create(:admin_notification, admin_user: @other_admin)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {ids: [stranger.id]} do
      assert_equal 0, parsed_body["count"]
      assert_not stranger.reload.read?
    end
  end

  test "PUT /notifications/read-bulk ignores a type the admin no longer has access to" do
    stranger = create(:admin_notification, admin_user: @admin_user, notification_type: "new_supporter")
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {ids: [stranger.id]} do
      assert_equal 0, parsed_body["count"]
      assert_not stranger.reload.read?
    end
  end

  test "PUT /notifications/read-bulk returns 401 when not signed in" do
    notification = create(:admin_notification, admin_user: @admin_user)

    assert_api_response :put, 401, api_path: "/notifications/read-bulk", body: {ids: [notification.id]}
  end

  # PUT /notifications/unread-bulk
  test "PUT /notifications/unread-bulk marks the listed notifications unread" do
    selected = create_list(:admin_notification, 2, :read, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/unread-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert selected.none? { |notification| notification.reload.read? }
    end
  end

  test "PUT /notifications/unread-bulk returns 401 when not signed in" do
    notification = create(:admin_notification, :read, admin_user: @admin_user)

    assert_api_response :put, 401, api_path: "/notifications/unread-bulk", body: {ids: [notification.id]}
  end

  # PUT /notifications/archive-bulk
  test "PUT /notifications/archive-bulk archives the listed notifications" do
    selected = create_list(:admin_notification, 2, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/archive-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert selected.all? { |notification| notification.reload.archived? }
    end
  end

  test "PUT /notifications/archive-bulk returns 401 when not signed in" do
    notification = create(:admin_notification, admin_user: @admin_user)

    assert_api_response :put, 401, api_path: "/notifications/archive-bulk", body: {ids: [notification.id]}
  end

  # PUT /notifications/unarchive-bulk
  test "PUT /notifications/unarchive-bulk moves the listed notifications back to the inbox" do
    selected = create_list(:admin_notification, 2, :archived, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/unarchive-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert selected.none? { |notification| notification.reload.archived? }
    end
  end

  test "PUT /notifications/unarchive-bulk on all reads the archive tab off the filter" do
    archived = create(:admin_notification, :archived, admin_user: @admin_user)
    inbox = create(:admin_notification, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/unarchive-bulk",
      body: {all: true, q: {archivedAtNull: false}} do
      assert_equal 1, parsed_body["count"]
      assert_not archived.reload.archived?
      assert_not inbox.reload.archived?
    end
  end

  test "PUT /notifications/unarchive-bulk returns 401 when not signed in" do
    notification = create(:admin_notification, :archived, admin_user: @admin_user)

    assert_api_response :put, 401, api_path: "/notifications/unarchive-bulk", body: {ids: [notification.id]}
  end

  # PUT /notifications/destroy-bulk
  test "PUT /notifications/destroy-bulk deletes the listed notifications" do
    selected = create_list(:admin_notification, 2, admin_user: @admin_user)
    untouched = create(:admin_notification, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert_equal [untouched.id], AdminNotification.where(admin_user: @admin_user).pluck(:id)
    end
  end

  test "PUT /notifications/destroy-bulk on all deletes everything the filter matches" do
    create_list(:admin_notification, 2, admin_user: @admin_user, title: "Paints Import Results")
    spared = create(:admin_notification, admin_user: @admin_user, title: "Loaner Sync")
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk",
      body: {all: true, q: {searchCont: "paints"}} do
      assert_equal 2, parsed_body["count"]
      assert_equal [spared.id], AdminNotification.where(admin_user: @admin_user).pluck(:id)
    end
  end

  test "PUT /notifications/destroy-bulk deletes nothing when nothing is selected" do
    create_list(:admin_notification, 3, admin_user: @admin_user)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk", body: {} do
      assert_equal 0, parsed_body["count"]
      assert_equal 3, AdminNotification.where(admin_user: @admin_user).count
    end
  end

  test "PUT /notifications/destroy-bulk ignores another admin's notification" do
    stranger = create(:admin_notification, admin_user: @other_admin)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk", body: {ids: [stranger.id]} do
      assert_equal 0, parsed_body["count"]
      assert AdminNotification.exists?(stranger.id)
    end
  end

  test "PUT /notifications/destroy-bulk returns 401 when not signed in" do
    notification = create(:admin_notification, admin_user: @admin_user)

    assert_api_response :put, 401, api_path: "/notifications/destroy-bulk", body: {ids: [notification.id]}
  end
end

# frozen_string_literal: true

require "openapi_helper"

# Every path here is a collection-level PUT, which the DSL cannot tell apart on
# the verb alone, so each assertion names its `api_path`.
class Api::V1::NotificationsBulkTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/notifications/read-bulk" do
    put("Mark the selected notifications as read") do
      operationId "readBulkNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::NotificationBulkInput

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::NotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/unread-bulk" do
    put("Mark the selected notifications as unread") do
      operationId "unreadBulkNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::NotificationBulkInput

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::NotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/archive-bulk" do
    put("Archive the selected notifications") do
      operationId "archiveBulkNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::NotificationBulkInput

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::NotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/unarchive-bulk" do
    put("Move the selected notifications back to the inbox") do
      operationId "unarchiveBulkNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::NotificationBulkInput

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::NotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/notifications/destroy-bulk" do
    put("Delete the selected notifications") do
      operationId "destroyBulkNotifications"
      tags "Notifications"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::NotificationBulkInput

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::NotificationBulkResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
  end

  # PUT /notifications/read-bulk
  test "PUT /notifications/read-bulk marks the listed notifications read" do
    selected = create_list(:notification, 2, user: @user)
    untouched = create(:notification, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert selected.all? { |notification| notification.reload.read? }
      assert_not untouched.reload.read?
    end
  end

  test "PUT /notifications/read-bulk counts only what it changed" do
    already_read = create(:notification, :read, user: @user)
    unread = create(:notification, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk",
      body: {ids: [already_read.id, unread.id]} do
      assert_equal 1, parsed_body["count"]
    end
  end

  test "PUT /notifications/read-bulk leaves an already read notification's timestamp alone" do
    read_at = 2.days.ago
    notification = create(:notification, user: @user, read_at:)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {ids: [notification.id]} do
      assert_in_delta read_at, notification.reload.read_at, 1.second
    end
  end

  test "PUT /notifications/read-bulk on all reaches past the first page" do
    create_list(:notification, Notification.default_per_page + 5, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {all: true} do
      assert_equal Notification.default_per_page + 5, parsed_body["count"]
      assert_equal 0, @user.notifications.unread.count
    end
  end

  test "PUT /notifications/read-bulk on all honours the filter it was given" do
    create(:notification, user: @user, title: "Hangar Sync finished")
    spared = create(:notification, user: @user, title: "Ship on sale")
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk",
      body: {all: true, q: {searchCont: "hangar"}} do
      assert_equal 1, parsed_body["count"]
      assert_not spared.reload.read?
    end
  end

  test "PUT /notifications/read-bulk on all stays out of the archive" do
    archived = create(:notification, :archived, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {all: true} do
      assert_equal 0, parsed_body["count"]
      assert_not archived.reload.read?
    end
  end

  # A body naming neither `ids` nor `all` must never be read as "everything":
  # the endpoint next door is `destroy-all`.
  test "PUT /notifications/read-bulk changes nothing when nothing is selected" do
    notification = create(:notification, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {} do
      assert_equal 0, parsed_body["count"]
      assert_not notification.reload.read?
    end
  end

  test "PUT /notifications/read-bulk ignores another user's notification" do
    stranger = create(:notification, user: create(:user))
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/read-bulk", body: {ids: [stranger.id]} do
      assert_equal 0, parsed_body["count"]
      assert_not stranger.reload.read?
    end
  end

  test "PUT /notifications/read-bulk returns 401 when not signed in" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/read-bulk", body: {ids: [notification.id]}
  end

  test "PUT /notifications/read-bulk with OAuth bearer token" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 200, api_path: "/notifications/read-bulk",
      headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:write"]),
      body: {ids: [notification.id]}
  end

  # PUT /notifications/unread-bulk
  test "PUT /notifications/unread-bulk marks the listed notifications unread" do
    selected = create_list(:notification, 2, :read, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/unread-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert selected.none? { |notification| notification.reload.read? }
    end
  end

  test "PUT /notifications/unread-bulk returns 401 when not signed in" do
    notification = create(:notification, :read, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/unread-bulk", body: {ids: [notification.id]}
  end

  # PUT /notifications/archive-bulk
  test "PUT /notifications/archive-bulk archives the listed notifications" do
    selected = create_list(:notification, 2, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/archive-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert selected.all? { |notification| notification.reload.archived? }
    end
  end

  test "PUT /notifications/archive-bulk returns 401 when not signed in" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/archive-bulk", body: {ids: [notification.id]}
  end

  # PUT /notifications/unarchive-bulk
  test "PUT /notifications/unarchive-bulk moves the listed notifications back to the inbox" do
    selected = create_list(:notification, 2, :archived, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/unarchive-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert selected.none? { |notification| notification.reload.archived? }
    end
  end

  test "PUT /notifications/unarchive-bulk on all reads the archive tab off the filter" do
    archived = create(:notification, :archived, user: @user)
    inbox = create(:notification, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/unarchive-bulk",
      body: {all: true, q: {archivedAtNull: false}} do
      assert_equal 1, parsed_body["count"]
      assert_not archived.reload.archived?
      assert_not inbox.reload.archived?
    end
  end

  test "PUT /notifications/unarchive-bulk returns 401 when not signed in" do
    notification = create(:notification, :archived, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/unarchive-bulk", body: {ids: [notification.id]}
  end

  # PUT /notifications/destroy-bulk
  test "PUT /notifications/destroy-bulk deletes the listed notifications" do
    selected = create_list(:notification, 2, user: @user)
    untouched = create(:notification, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
      assert_equal [untouched.id], @user.notifications.pluck(:id)
    end
  end

  test "PUT /notifications/destroy-bulk on all deletes everything the filter matches" do
    create_list(:notification, 2, user: @user, title: "Hangar Sync finished")
    spared = create(:notification, user: @user, title: "Ship on sale")
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk",
      body: {all: true, q: {searchCont: "hangar"}} do
      assert_equal 2, parsed_body["count"]
      assert_equal [spared.id], @user.notifications.pluck(:id)
    end
  end

  test "PUT /notifications/destroy-bulk deletes nothing when nothing is selected" do
    create_list(:notification, 3, user: @user)
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk", body: {} do
      assert_equal 0, parsed_body["count"]
      assert_equal 3, @user.notifications.count
    end
  end

  test "PUT /notifications/destroy-bulk ignores another user's notification" do
    stranger = create(:notification, user: create(:user))
    sign_in @user

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk", body: {ids: [stranger.id]} do
      assert_equal 0, parsed_body["count"]
      assert Notification.exists?(stranger.id)
    end
  end

  test "PUT /notifications/destroy-bulk returns 401 when not signed in" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 401, api_path: "/notifications/destroy-bulk", body: {ids: [notification.id]}
  end

  test "PUT /notifications/destroy-bulk with OAuth bearer token" do
    notification = create(:notification, user: @user)

    assert_api_response :put, 200, api_path: "/notifications/destroy-bulk",
      headers: oauth_headers_for(@user, scopes: ["notifications", "notifications:write"]),
      body: {ids: [notification.id]}
  end
end

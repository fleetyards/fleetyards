# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PushSubscriptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/push-subscriptions" do
    get("Push subscriptions") do
      operationId "pushSubscriptions"
      tags "PushSubscriptions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:read"]},
        {OpenId: ["notifications", "notifications:read"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::PushSubscriptionsList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Subscribe this browser to push notifications") do
      operationId "createPushSubscription"
      tags "PushSubscriptions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::PushSubscriptionInput

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(201, "created") { schema ::V1::Schemas::PushSubscription }
      response(200, "an already known browser subscribed again") { schema ::V1::Schemas::PushSubscription }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/push-subscriptions/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    delete("Unsubscribe a browser from push notifications") do
      operationId "destroyPushSubscription"
      tags "PushSubscriptions"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(204, "successful")
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/push-subscriptions/{id}/touch" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Mark this browser's push subscription as still in use") do
      operationId "touchPushSubscription"
      tags "PushSubscriptions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["notifications", "notifications:write"]},
        {OpenId: ["notifications", "notifications:write"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::PushSubscription }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  FIREFOX = "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0"
  P256DH = "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM"
  AUTH = "tBHItJI5svbpez7KI4CCXg"

  setup do
    @user = create(:user)
    Flipper.enable("push_notifications")
    Push::Vapid.stubs(:configured?).returns(true)
  end

  def subscription_body(endpoint: "https://fcm.googleapis.com/fcm/send/abc")
    {endpoint:, expirationTime: nil, keys: {p256dh: P256DH, auth: AUTH}}
  end

  test "GET lists the user's own subscriptions" do
    create(:push_subscription, user: @user)
    create(:push_subscription)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.count
      assert_equal "Firefox", parsed_body.first["browser"]
      assert_equal "Linux x86_64", parsed_body.first["os"]
      refute_includes parsed_body.first.keys, "endpoint"
    end
  end

  test "GET answers null rather than leaving a field out" do
    create(:push_subscription, user: @user, user_agent: nil)
    sign_in @user

    assert_api_response :get, 200 do
      subscription = parsed_body.first
      assert_includes subscription.keys, "lastDeliveredAt"
      assert_includes subscription.keys, "browser"
      assert_includes subscription.keys, "os"
      assert_nil subscription["lastDeliveredAt"]
      assert_nil subscription["browser"]
    end
  end

  test "GET with a notifications read token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["notifications:read"])

    assert_api_response :get, 200, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "GET without a session is unauthorized" do
    assert_api_response :get, 401
  end

  test "GET is forbidden with the feature off" do
    Flipper.disable("push_notifications")
    sign_in @user

    assert_api_response :get, 403
  end

  test "GET is forbidden without VAPID keys" do
    Push::Vapid.stubs(:configured?).returns(false)
    sign_in @user

    assert_api_response :get, 403
  end

  test "POST subscribes this browser" do
    sign_in @user

    assert_api_response :post, 201, body: subscription_body, headers: {"User-Agent" => FIREFOX} do
      assert parsed_body["id"].present?
      assert_equal "Firefox", parsed_body["browser"]
    end

    subscription = @user.push_subscriptions.sole
    assert_equal "https://fcm.googleapis.com/fcm/send/abc", subscription.endpoint
    assert_equal P256DH, subscription.p256dh_key
    assert_equal AUTH, subscription.auth_key
  end

  test "POST with a known endpoint answers with the same row" do
    existing = create(:push_subscription, user: @user, endpoint: "https://fcm.googleapis.com/fcm/send/abc")
    sign_in @user

    assert_api_response :post, 200, body: subscription_body do
      assert_equal existing.id, parsed_body["id"]
    end

    assert_equal 1, PushSubscription.count
  end

  test "POST rejects an endpoint that is not a push service" do
    sign_in @user

    assert_api_response :post, 400, body: subscription_body(endpoint: "https://169.254.169.254/latest/meta-data")

    assert_equal 0, PushSubscription.count
  end

  test "POST of another user's endpoint without its keys is a bad request" do
    subscription = create(:push_subscription, endpoint: "https://fcm.googleapis.com/fcm/send/abc", auth_key: Base64.urlsafe_encode64("0123456789abcdef", padding: false))
    sign_in @user

    assert_api_response :post, 400, body: subscription_body

    assert_equal subscription.user_id, subscription.reload.user_id
  end

  test "POST without keys is a bad request" do
    sign_in @user

    assert_api_response :post, 400, body: {endpoint: "https://fcm.googleapis.com/fcm/send/abc", keys: {}}
  end

  test "POST with keys that are not an object is a bad request" do
    sign_in @user

    assert_api_response :post, 400, body: {endpoint: "https://fcm.googleapis.com/fcm/send/abc", keys: "abc"}

    assert_equal 0, PushSubscription.count
  end

  test "POST with a notifications write token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["notifications:write"])

    assert_api_response :post, 201, body: subscription_body, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "POST with only a read token is unauthorized" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["notifications:read"])

    assert_api_response :post, 401, body: subscription_body, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "POST is forbidden with the feature off" do
    Flipper.disable("push_notifications")
    sign_in @user

    assert_api_response :post, 403, body: subscription_body
  end

  test "PUT touch marks the browser as in use and keeps its failures" do
    subscription = create(:push_subscription, user: @user, failure_count: 3)
    subscription.update_columns(updated_at: 1.year.ago)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: subscription.id} do
      assert_equal subscription.id, parsed_body["id"]
    end

    subscription.reload
    assert_operator subscription.updated_at, :>, 1.minute.ago
    assert_equal 3, subscription.failure_count
  end

  # A device removed in the meantime stays removed.
  test "PUT touch for a removed subscription is not found and creates nothing" do
    subscription = create(:push_subscription, user: @user)
    subscription.destroy!
    sign_in @user

    assert_api_response :put, 404, path_params: {id: subscription.id}

    assert_equal 0, PushSubscription.count
  end

  test "PUT touch of another user's subscription is not found" do
    subscription = create(:push_subscription)
    sign_in @user

    assert_api_response :put, 404, path_params: {id: subscription.id}
  end

  test "DELETE unsubscribes a browser" do
    subscription = create(:push_subscription, user: @user)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: subscription.id}

    refute PushSubscription.exists?(subscription.id)
  end

  # Somebody else's subscription does not exist as far as this user can tell.
  test "DELETE of another user's subscription is not found" do
    subscription = create(:push_subscription)
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: subscription.id}

    assert PushSubscription.exists?(subscription.id)
  end

  test "DELETE without a session is unauthorized" do
    subscription = create(:push_subscription, user: @user)

    assert_api_response :delete, 401, path_params: {id: subscription.id}
  end
end

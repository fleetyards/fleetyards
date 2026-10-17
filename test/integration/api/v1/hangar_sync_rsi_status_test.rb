# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarSyncRsiStatusTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/sync-rsi-hangar/status" do
    get("Sync RSI Hangar Status") do
      operationId "syncRsiHangarStatus"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::HangarSyncStatus
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /hangar/sync-rsi-hangar/status returns sync status" do
    user = create(:user)
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /hangar/sync-rsi-hangar/status reports a running sync as active" do
    user = create(:user)
    sign_in user
    Imports::HangarSync.create!(user:, input: [], aasm_state: "started", started_at: 5.minutes.ago)

    get "/api/v1/hangar/sync-rsi-hangar/status", as: :json

    assert_response :ok
    assert response.parsed_body["active"]
  end

  # The sync button stays disabled while the status says active, and the
  # request it sends is what writes the abandoned run off.
  test "GET /hangar/sync-rsi-hangar/status reports an abandoned sync as over" do
    user = create(:user)
    sign_in user
    Imports::HangarSync.create!(user:, input: [], aasm_state: "started", started_at: 2.hours.ago)

    get "/api/v1/hangar/sync-rsi-hangar/status", as: :json

    assert_response :ok
    assert_not response.parsed_body["active"]
  end

  test "GET /hangar/sync-rsi-hangar/status returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/sync-rsi-hangar/status with OAuth bearer token" do
    user = create(:user)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:write"])
  end
end

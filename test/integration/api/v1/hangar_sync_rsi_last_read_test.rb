# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarSyncRsiLastReadTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/sync-rsi-hangar/last-read" do
    get("Sync RSI Hangar Last Read") do
      operationId "syncRsiHangarLastRead"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::HangarSyncLastRead
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /hangar/sync-rsi-hangar/last-read counts what the last finished sync read" do
    user = create(:user)
    sign_in user
    Imports::HangarSync.create!(
      user:,
      aasm_state: "finished",
      finished_at: 2.days.ago,
      input: [
        {id: "1", name: "Avenger Titan", type: "ship", page: 1},
        {id: "1", name: "Avenger Titan", type: "ship", page: 1},
        {id: "2", name: "Poster", type: "flair", page: 2},
        {id: "2", name: "Poster ", type: "flair", page: 2},
        {id: "3", name: "Poster", type: "flair", page: 3}
      ]
    )

    assert_api_response :get, 200 do
      body = response.parsed_body

      assert_equal 4, body["total"]
      assert_equal 3, body["pages"]
      assert_equal 2, body.dig("counts", "ship")
      assert_equal 2, body.dig("counts", "flair")
      assert_equal 0, body.dig("counts", "skin")
    end
  end

  test "GET /hangar/sync-rsi-hangar/last-read skips a newer run that did not finish" do
    user = create(:user)
    sign_in user
    Imports::HangarSync.create!(user:, aasm_state: "finished", finished_at: 2.days.ago,
      input: [{id: "1", name: "Avenger Titan", type: "ship", page: 1}])
    Imports::HangarSync.create!(user:, aasm_state: "failed", failed_at: 1.hour.ago,
      input: [{id: "1", name: "Avenger Titan", type: "ship", page: 1}, {id: "2", name: "Cutlass Black", type: "ship", page: 1}])

    get "/api/v1/hangar/sync-rsi-hangar/last-read", as: :json

    assert_response :ok
    assert_equal 1, response.parsed_body["total"]
  end

  test "GET /hangar/sync-rsi-hangar/last-read reports nothing before a first sync" do
    user = create(:user)
    sign_in user

    get "/api/v1/hangar/sync-rsi-hangar/last-read", as: :json

    assert_response :ok
    assert_equal 0, response.parsed_body["total"]
    assert_nil response.parsed_body["finishedAt"]
  end

  test "GET /hangar/sync-rsi-hangar/last-read returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end

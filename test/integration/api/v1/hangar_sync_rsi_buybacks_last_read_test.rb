# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarSyncRsiBuybacksLastReadTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/sync-rsi-buybacks/last-read" do
    get("Sync RSI Buy-back Pledges Last Read") do
      operationId "syncRsiBuybacksLastRead"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::BuybackSyncLastRead
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /hangar/sync-rsi-buybacks/last-read reads what the last finished sync read" do
    user = create(:user)
    Imports::BuybackSync.create!(user:, aasm_state: "finished", finished_at: 1.day.ago,
      input: [{"id" => "1", "page" => 1}, {"id" => "2", "page" => 2}, {"id" => "2", "page" => 2}])
    Imports::BuybackSync.create!(user:, aasm_state: "failed", failed_at: 1.hour.ago, input: [{"id" => "9"}])
    sign_in user

    assert_api_response :get, 200, api_path: "/hangar/sync-rsi-buybacks/last-read" do
      assert_equal 2, parsed_body["total"]
      assert_equal 2, parsed_body["pages"]
    end
  end

  test "GET /hangar/sync-rsi-buybacks/last-read counts the stored list before a first recorded sync" do
    user = create(:user)
    buyback(user, rsi_pledge_id: "1")
    buyback(user, rsi_pledge_id: "2")
    buyback(create(:user), rsi_pledge_id: "3")
    sign_in user

    get "/api/v1/hangar/sync-rsi-buybacks/last-read", as: :json

    assert_response :ok
    assert_equal 2, response.parsed_body["total"]
    assert_nil response.parsed_body["pages"]
  end

  private def buyback(user, **attributes)
    BuybackPledge.create!(
      user:, rsi_pledge_id: SecureRandom.random_number(10**8).to_s, kind: "ship", name: "Standalone Ship - Cutlass Black",
      **attributes
    )
  end
end

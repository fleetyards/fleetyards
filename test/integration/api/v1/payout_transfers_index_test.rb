# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutTransfersIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{payoutLedgerId}/transfers" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}

    get("The frozen payout list") do
      operationId "payoutTransfers"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutTransfersList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    @organiser = create(:user)
    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    @from = create(:payout_participant, payout_ledger: @ledger)
    @to = create(:payout_participant, payout_ledger: @ledger)
  end

  test "GET is empty while the ledger is open" do
    sign_in @organiser

    assert_api_response :get, 200, path_params: {payoutLedgerId: @ledger.id} do
      assert_empty parsed_body
    end
  end

  test "GET lists the frozen transfers once settled" do
    create(:payout_transfer, payout_ledger: @ledger, from_participant: @from, to_participant: @to, amount: 42)
    sign_in @organiser

    assert_api_response :get, 200, path_params: {payoutLedgerId: @ledger.id} do
      assert_equal 1, parsed_body.size
      assert_equal "42.0", parsed_body.first["amount"]
    end
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {payoutLedgerId: @ledger.id}
  end
end

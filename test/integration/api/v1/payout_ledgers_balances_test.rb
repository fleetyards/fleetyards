# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutLedgersBalancesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{id}/balances" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    get("Balances and the transfers that settle them") do
      operationId "payoutLedgerBalances"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutSettlement
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")

    @organiser = create(:user)
    @bob = create(:user)

    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    @alice_p = create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    @bob_p = create(:payout_participant, payout_ledger: @ledger, user: @bob)
    @guest_p = create(:payout_participant, :guest, payout_ledger: @ledger)

    create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: @bob_p, amount: 900_000)
    create(:payout_entry, payout_ledger: @ledger, payout_participant: @alice_p, amount: 12_000)
  end

  test "GET returns a balance per participant that sums to zero" do
    sign_in @bob

    assert_api_response :get, 200, path_params: {id: @ledger.id} do
      assert_equal "888000.0", parsed_body["profit"]
      assert_equal 3, parsed_body["balances"].size
      assert_equal 0, parsed_body["balances"].sum { |b| b["net"].to_d }
    end
  end

  test "GET includes a guest in the split" do
    sign_in @bob

    assert_api_response :get, 200, path_params: {id: @ledger.id} do
      guest = parsed_body["balances"].find { |b| b["participant"]["id"] == @guest_p.id }
      assert_equal "296000.0", guest["share"]
    end
  end

  test "GET returns the transfers without settling" do
    sign_in @bob

    assert_api_response :get, 200, path_params: {id: @ledger.id} do
      assert_equal 2, parsed_body["transfers"].size
      assert_equal "open", @ledger.reload.status
      assert_empty @ledger.payout_transfers
    end
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {id: @ledger.id}
  end
end

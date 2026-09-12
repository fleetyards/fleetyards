# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutLedgersShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    get("Show a payout ledger") do
      operationId "payoutLedger"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutLedger
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    @organiser = create(:user)
    @stranger = create(:user)
    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    @participant = create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: @participant, amount: 400)
  end

  test "GET returns the ledger with its totals" do
    sign_in @organiser

    assert_api_response :get, 200, path_params: {id: @ledger.id} do
      assert_equal "400.0", parsed_body["totalIncome"]
      assert_equal "0.0", parsed_body["totalExpenses"]
      assert_equal "400.0", parsed_body["profit"]
      assert_equal 1, parsed_body["participantsCount"]
      assert_equal 1, parsed_body["participants"].size
    end
  end

  test "GET is refused for someone not on the tour" do
    sign_in @stranger

    assert_api_response :get, 403, path_params: {id: @ledger.id}
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {id: @ledger.id}
  end
end

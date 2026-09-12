# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ToursSettleTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{slug}/settle" do
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Settle Tour") do
      operationId "settleTour"
      tags "Tours"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::Tour
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
    @bob = create(:user)

    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    alice_p = create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    bob_p = create(:payout_participant, payout_ledger: @ledger, user: @bob)

    create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: bob_p, amount: 1000)
    create(:payout_entry, payout_ledger: @ledger, payout_participant: alice_p, amount: 200)
  end

  test "PUT settles the tour and its ledger together" do
    sign_in @organiser

    assert_api_response :put, 200, path_params: {slug: @tour.slug} do
      assert_equal "settled", parsed_body["status"]
      assert_equal "settled", @ledger.reload.status
      assert_equal 1, @ledger.payout_transfers.size
      assert_equal 600, @ledger.payout_transfers.first.amount.to_i
    end
  end

  test "PUT is refused for a participant" do
    sign_in @bob

    assert_api_response :put, 403, path_params: {slug: @tour.slug}
  end

  test "PUT returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {slug: @tour.slug}
  end
end

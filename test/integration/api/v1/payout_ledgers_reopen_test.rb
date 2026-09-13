# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutLedgersReopenTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{id}/reopen" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Reopen a settled payout ledger") do
      operationId "reopenPayoutLedger"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
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

      response(409, "not settled") do
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
    create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    bob_p = create(:payout_participant, payout_ledger: @ledger, user: @bob)
    create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: bob_p, amount: 100)
  end

  test "PUT reopens a settled ledger and discards the payout list" do
    @ledger.settle!(@organiser)
    sign_in @organiser

    assert_api_response :put, 200, path_params: {id: @ledger.id} do
      assert_equal "open", parsed_body["status"]
      assert_empty @ledger.reload.payout_transfers
    end
  end

  test "PUT refuses a ledger that is still open" do
    sign_in @organiser

    assert_api_response :put, 409, path_params: {id: @ledger.id}
  end

  test "PUT is refused for a participant" do
    @ledger.settle!(@organiser)
    sign_in @bob

    assert_api_response :put, 403, path_params: {id: @ledger.id}
  end

  test "PUT returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: @ledger.id}
  end

  test "PUT carries the tour back to open" do
    @ledger.settle!(@organiser)

    assert_equal "settled", @tour.reload.status

    sign_in @organiser

    assert_api_response :put, 200, path_params: {id: @ledger.id} do
      assert_equal "open", @tour.reload.status
      assert_nil @tour.settled_at
    end
  end

  # With the tour left open behind a settled ledger, this used to be reachable
  # and deleted every confirmation people had ticked off.
  test "a tour settled through the ledger cannot then be settled again" do
    @ledger.settle!(@organiser)
    transfer = @ledger.payout_transfers.first
    transfer.confirm!(@organiser)

    sign_in @organiser
    put "/api/v1/tours/#{@tour.slug}/settle"

    assert_response :conflict
    assert_predicate transfer.reload, :confirmed?
  end
end

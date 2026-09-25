# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutEntriesReviewTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{payoutLedgerId}/entries/{id}/approve" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Approve a payout expense") do
      operationId "approvePayoutEntry"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutEntry
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/payouts/{payoutLedgerId}/entries/{id}/decline" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Decline a payout expense") do
      operationId "declinePayoutEntry"
      tags "Payouts"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::PayoutEntryDeclineInput, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutEntry
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
    @member = create(:user)

    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    @member_p = create(:payout_participant, payout_ledger: @ledger, user: @member)

    @entry = create(:payout_entry, :pending, payout_ledger: @ledger,
      payout_participant: @member_p, recorded_by: @member, amount: 100)
  end

  test "PUT approve lets the expense count" do
    sign_in @organiser

    assert_api_response :put, 200, api_path: "/payouts/{payoutLedgerId}/entries/{id}/approve", path_params: {payoutLedgerId: @ledger.id, id: @entry.id} do
      assert_equal "approved", parsed_body["reviewStatus"]
      assert_equal @organiser.username, parsed_body.dig("reviewedBy", "username")
      assert_equal 100, @ledger.settlement.total_expenses
    end
  end

  test "PUT decline keeps the expense out and records why" do
    sign_in @organiser

    assert_api_response :put, 200,
      api_path: "/payouts/{payoutLedgerId}/entries/{id}/decline", path_params: {payoutLedgerId: @ledger.id, id: @entry.id},
      body: {reason: "No receipt"} do
      assert_equal "declined", parsed_body["reviewStatus"]
      assert_equal "No receipt", parsed_body["declineReason"]
      assert_equal 0, @ledger.settlement.total_expenses
    end
  end

  test "PUT approve is refused for the participant who recorded it" do
    sign_in @member

    assert_api_response :put, 403, api_path: "/payouts/{payoutLedgerId}/entries/{id}/approve", path_params: {payoutLedgerId: @ledger.id, id: @entry.id}
  end

  test "PUT approve is refused for income" do
    income = create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: @member_p)
    sign_in @organiser

    assert_api_response :put, 403, api_path: "/payouts/{payoutLedgerId}/entries/{id}/approve", path_params: {payoutLedgerId: @ledger.id, id: income.id}
  end

  test "PUT decline returns 401 when not signed in" do
    assert_api_response :put, 401, api_path: "/payouts/{payoutLedgerId}/entries/{id}/decline", path_params: {payoutLedgerId: @ledger.id, id: @entry.id}
  end
end

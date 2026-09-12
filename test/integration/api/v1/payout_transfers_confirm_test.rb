# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutTransfersConfirmTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{payoutLedgerId}/transfers/{id}/confirm" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Mark a transfer as paid") do
      operationId "confirmPayoutTransfer"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutTransfer
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Undo a confirmation") do
      operationId "unconfirmPayoutTransfer"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutTransfer
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")

    @organiser = create(:user)
    @sender = create(:user)
    @receiver = create(:user)
    @bystander = create(:user)

    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    @from = create(:payout_participant, payout_ledger: @ledger, user: @sender)
    @to = create(:payout_participant, payout_ledger: @ledger, user: @receiver)
    @bystander_p = create(:payout_participant, payout_ledger: @ledger, user: @bystander)

    @transfer = create(:payout_transfer, payout_ledger: @ledger,
      from_participant: @from, to_participant: @to, amount: 500)
  end

  def path_params
    {payoutLedgerId: @ledger.id, id: @transfer.id}
  end

  test "PUT lets the sender tick off a transfer" do
    sign_in @sender

    assert_api_response :put, 200, path_params: path_params do
      assert_equal true, parsed_body["confirmed"]
      assert_equal @sender.id, @transfer.reload.confirmed_by_id
    end
  end

  test "PUT lets the receiver tick off a transfer" do
    sign_in @receiver

    assert_api_response :put, 200, path_params: path_params
  end

  test "PUT lets the organiser tick off a transfer" do
    sign_in @organiser

    assert_api_response :put, 200, path_params: path_params
  end

  # Someone on the tour who is neither end of this particular transfer has no
  # way of knowing whether it was paid.
  test "PUT is refused for a participant who is not party to it" do
    sign_in @bystander

    assert_api_response :put, 403, path_params: path_params
  end

  test "PUT returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: path_params
  end

  test "DELETE undoes a confirmation" do
    @transfer.confirm!(@sender)
    sign_in @sender

    assert_api_response :delete, 200, path_params: path_params do
      assert_equal false, parsed_body["confirmed"]
      assert_nil @transfer.reload.confirmed_at
    end
  end

  test "DELETE returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: path_params
  end
end

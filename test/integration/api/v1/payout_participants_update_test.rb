# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutParticipantsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{payoutLedgerId}/participants/{id}" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    delete("Remove a payout participant") do
      operationId "destroyPayoutParticipant"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutParticipant
      end

      response(400, "still has entries") do
        schema ::Shared::V1::Schemas::ValidationError
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
    @participant = create(:payout_participant, payout_ledger: @ledger, user: @member)
  end

  def path_params
    {payoutLedgerId: @ledger.id, id: @participant.id}
  end

  test "DELETE removes a participant with no entries" do
    sign_in @organiser

    assert_api_response :delete, 200, path_params: path_params do
      assert_not PayoutParticipant.exists?(@participant.id)
    end
  end

  # Their entries would be orphaned and every other balance would move.
  test "DELETE refuses while the participant has entries" do
    create(:payout_entry, payout_ledger: @ledger, payout_participant: @participant)
    sign_in @organiser

    assert_api_response :delete, 400, path_params: path_params
  end

  test "DELETE is refused for a plain participant" do
    sign_in @member

    assert_api_response :delete, 403, path_params: path_params
  end

  test "DELETE returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: path_params
  end
end

# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutParticipantsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{payoutLedgerId}/participants/{id}" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    patch("Update a payout participant") do
      operationId "updatePayoutParticipant"
      tags "Payouts"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::PayoutParticipantUpdateInput, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutParticipant
      end

      response(400, "invalid weight") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

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

  test "PATCH lets the organiser reduce a share" do
    sign_in @organiser

    assert_api_response :patch, 200, path_params: path_params, body: {weight: "0.5"} do
      assert_equal "0.5", parsed_body["weight"]
      assert_equal 0.5, @participant.reload.weight
    end
  end

  test "PATCH lets the organiser hand out more than a full share" do
    sign_in @organiser

    assert_api_response :patch, 200, path_params: path_params, body: {weight: "1.5"} do
      assert_equal 1.5, @participant.reload.weight
    end
  end

  # Nobody is on a ledger for nothing: a zero weight would leave the profit
  # divided by less than it is, and the balances would stop summing to zero.
  test "PATCH refuses a weight of zero" do
    sign_in @organiser

    assert_api_response :patch, 400, path_params: path_params, body: {weight: "0"} do
      assert_equal 1.0, @participant.reload.weight
    end
  end

  test "PATCH refuses a negative weight" do
    sign_in @organiser

    assert_api_response :patch, 400, path_params: path_params, body: {weight: "-1"}
  end

  # A weight is what the profit is divided by, so it answers to the same right
  # as adding and removing somebody.
  test "PATCH is refused for a plain participant" do
    sign_in @member

    assert_api_response :patch, 403, path_params: path_params, body: {weight: "0.5"}
  end

  # The transfers are frozen around the split the weights produced; moving one
  # afterwards would leave the settled list describing something else.
  test "PATCH is refused once the ledger is settled" do
    @ledger.update!(status: "settled", settled_at: Time.current)
    sign_in @organiser

    assert_api_response :patch, 403, path_params: path_params, body: {weight: "0.5"} do
      assert_equal 1.0, @participant.reload.weight
    end
  end

  test "PATCH returns 401 when not signed in" do
    assert_api_response :patch, 401, path_params: path_params, body: {weight: "0.5"}
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

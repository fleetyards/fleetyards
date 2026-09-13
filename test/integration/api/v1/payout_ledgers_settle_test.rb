# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutLedgersSettleTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{id}/settle" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Settle a payout ledger") do
      operationId "settlePayoutLedger"
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

      response(409, "already settled") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")

    @organiser = create(:user)
    @bob = create(:user)
    @cara = create(:user)

    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)

    @alice_p = create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    @bob_p = create(:payout_participant, payout_ledger: @ledger, user: @bob)
    @cara_p = create(:payout_participant, payout_ledger: @ledger, user: @cara)

    create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: @bob_p, amount: 900_000)
    create(:payout_entry, payout_ledger: @ledger, payout_participant: @alice_p, amount: 12_000)
  end

  # The worked example from the issue: costs come back to whoever paid them,
  # then what is left is divided.
  test "PUT freezes the transfer list" do
    sign_in @organiser

    assert_api_response :put, 200, path_params: {id: @ledger.id} do
      assert_equal "settled", parsed_body["status"]

      transfers = @ledger.reload.payout_transfers.order(:amount)
      assert_equal 2, transfers.size
      assert_equal [296_000, 308_000], transfers.map { |t| t.amount.to_i }
      assert transfers.all? { |t| t.from_participant_id == @bob_p.id }
    end
  end

  test "PUT refuses a second settle" do
    @ledger.settle!(@organiser)
    sign_in @organiser

    assert_api_response :put, 409, path_params: {id: @ledger.id}
  end

  test "PUT is refused for a participant who does not manage the tour" do
    sign_in @bob

    assert_api_response :put, 403, path_params: {id: @ledger.id}
  end

  test "PUT returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: @ledger.id}
  end

  # The UI settles through this endpoint, not the tour's, so the tour's own
  # status has to come along -- otherwise its page reads "Open" forever and
  # PUT /tours/:slug/settle stays live and wipes the confirmations.
  test "PUT carries the tour's own status across" do
    sign_in @organiser

    assert_api_response :put, 200, path_params: {id: @ledger.id} do
      assert_equal "settled", @tour.reload.status
      assert_not_nil @tour.settled_at
    end
  end

  test "PUT leaves a fleet event's own lifecycle alone" do
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    event = create(:fleet_event, :active, fleet: fleet, created_by: admin)
    ledger = create(:payout_ledger, subject: event)
    create(:payout_participant, payout_ledger: ledger, user: admin)

    Flipper.enable("fleet_mission_builder")
    sign_in admin

    assert_api_response :put, 200, path_params: {id: ledger.id} do
      assert_equal "active", event.reload.status
    end
  end
end

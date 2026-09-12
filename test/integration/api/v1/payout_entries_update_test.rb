# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutEntriesUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{payoutLedgerId}/entries/{id}" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    patch("Update a payout entry") do
      operationId "updatePayoutEntry"
      tags "Payouts"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::PayoutEntryUpdateInput, required: true

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

    delete("Delete a payout entry") do
      operationId "destroyPayoutEntry"
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
    end
  end

  setup do
    Flipper.enable("tour_payouts")

    @organiser = create(:user)
    @member = create(:user)
    @other = create(:user)

    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    @member_p = create(:payout_participant, payout_ledger: @ledger, user: @member)
    @other_p = create(:payout_participant, payout_ledger: @ledger, user: @other)

    @entry = create(:payout_entry, payout_ledger: @ledger,
      payout_participant: @member_p, recorded_by: @member, amount: 100, description: "Refuel")
  end

  def path_params
    {payoutLedgerId: @ledger.id, id: @entry.id}
  end

  test "PATCH lets the recorder correct their own entry" do
    sign_in @member

    assert_api_response :patch, 200, path_params: path_params, body: {amount: "250", description: "Refuel + ammo"} do
      assert_equal "250.0", parsed_body["amount"]
    end
  end

  test "PATCH lets the organiser correct any entry" do
    sign_in @organiser

    assert_api_response :patch, 200, path_params: path_params, body: {amount: "250"}
  end

  # An entry belongs to whoever recorded it. Another participant editing it
  # would silently move everyone's balance.
  test "PATCH is refused for another participant" do
    sign_in @other

    assert_api_response :patch, 403, path_params: path_params, body: {amount: "1"}
  end

  test "PATCH is refused once the ledger is settled" do
    @ledger.update!(status: "settled", settled_at: Time.current)
    sign_in @member

    assert_api_response :patch, 403, path_params: path_params, body: {amount: "1"}
  end

  test "PATCH returns 401 when not signed in" do
    assert_api_response :patch, 401, path_params: path_params, body: {amount: "1"}
  end

  test "DELETE removes the entry" do
    sign_in @member

    assert_api_response :delete, 200, path_params: path_params do
      assert_not PayoutEntry.exists?(@entry.id)
    end
  end

  test "DELETE returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: path_params
  end
end

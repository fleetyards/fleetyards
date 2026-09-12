# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutEntriesCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{payoutLedgerId}/entries" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}

    post("Record a payout entry") do
      operationId "createPayoutEntry"
      tags "Payouts"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::PayoutEntryCreateInput, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Payouts::PayoutEntry
      end

      response(400, "invalid") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("List payout entries") do
      operationId "payoutEntries"
      tags "Payouts"
      produces "application/json"

      parameter ::Shared::V1::Parameters::PageParameter
      parameter ::Shared::V1::Parameters::SortingParameter

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutEntriesList
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
    @stranger = create(:user)

    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    @organiser_participant = create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    @member_participant = create(:payout_participant, payout_ledger: @ledger, user: @member)
  end

  def entry_body(overrides = {})
    {
      payoutParticipantId: @member_participant.id,
      entryType: "expense",
      amount: "1200.50",
      description: "Refuel"
    }.merge(overrides)
  end

  test "POST records an expense against a participant" do
    sign_in @member

    assert_api_response :post, 201,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body do
      assert_equal "expense", parsed_body["entryType"]
      assert_equal "1200.5", parsed_body["amount"]
      assert_equal @member.id, PayoutEntry.find(parsed_body["id"]).recorded_by_id
    end
  end

  test "POST records income" do
    sign_in @member

    assert_api_response :post, 201,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body(entryType: "income", amount: "900000") do
      assert_equal "income", parsed_body["entryType"]
    end
  end

  test "POST rejects a non-positive amount" do
    sign_in @member

    assert_api_response :post, 400,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body(amount: "0")
  end

  # A participant id from a different ledger would otherwise let one tour's
  # money be booked against another tour's member.
  test "POST rejects a participant from another ledger" do
    other = create(:payout_participant)
    sign_in @member

    assert_api_response :post, 400,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body(payoutParticipantId: other.id)
  end

  test "POST refuses once the ledger is settled" do
    @ledger.update!(status: "settled", settled_at: Time.current)
    sign_in @member

    assert_api_response :post, 403,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body
  end

  test "POST is refused for someone who is not on the tour" do
    sign_in @stranger

    assert_api_response :post, 403,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body
  end

  test "POST returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body
  end

  test "GET lists the entries" do
    create(:payout_entry, payout_ledger: @ledger, payout_participant: @member_participant, amount: 50)
    sign_in @member

    assert_api_response :get, 200, path_params: {payoutLedgerId: @ledger.id} do
      assert_equal 1, parsed_body["items"].size
    end
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {payoutLedgerId: @ledger.id}
  end
end

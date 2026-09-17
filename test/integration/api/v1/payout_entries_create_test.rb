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
  # money be booked against another tour's member. Asked as the organiser: a
  # member naming anyone but themselves is refused a step earlier, which would
  # never reach the validation this covers.
  test "POST rejects a participant from another ledger" do
    other = create(:payout_participant)
    sign_in @organiser

    assert_api_response :post, 400,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body(payoutParticipantId: other.id)
  end

  # Everyone accounts for their own money: one member booking an expense
  # against another moves both their balances.
  test "POST refuses a member recording against someone else's row" do
    sign_in @member

    assert_api_response :post, 403,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body(payoutParticipantId: @organiser_participant.id)
  end

  test "POST refuses a member recording against a guest" do
    guest = create(:payout_participant, :guest, payout_ledger: @ledger)
    sign_in @member

    assert_api_response :post, 403,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body(payoutParticipantId: guest.id)
  end

  # The organiser is the only way a guest's spending reaches the ledger at all.
  test "POST lets the organiser record against a guest" do
    guest = create(:payout_participant, :guest, payout_ledger: @ledger)
    sign_in @organiser

    assert_api_response :post, 201,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body(payoutParticipantId: guest.id) do
      assert_equal guest.id, parsed_body["payoutParticipantId"]
    end
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

  # The ledger's children are gated by PayoutLedgerScoped rather than by the
  # ledgers controller, which is a second code path -- so the refusal is
  # asserted here too, not only where a ledger is created.
  test "an entry on a fleet event's ledger needs the fleet flag" do
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    event = create(:fleet_event, :active, fleet:, created_by: admin)
    ledger = create(:payout_ledger, subject: event)
    participant = create(:payout_participant, payout_ledger: ledger, user: admin)

    Flipper.enable("fleet_mission_builder")
    Flipper.disable("fleet_tours")
    sign_in admin

    assert_api_response :post, 403,
      path_params: {payoutLedgerId: ledger.id},
      body: entry_body(payoutParticipantId: participant.id)
  end

  test "the same entry is allowed once the fleet flag is on" do
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    event = create(:fleet_event, :active, fleet:, created_by: admin)
    ledger = create(:payout_ledger, subject: event)
    participant = create(:payout_participant, payout_ledger: ledger, user: admin)

    Flipper.enable("fleet_mission_builder")
    Flipper.enable("fleet_tours")
    sign_in admin

    assert_api_response :post, 201,
      path_params: {payoutLedgerId: ledger.id},
      body: entry_body(payoutParticipantId: participant.id)
  end

  # The other half of the D3 split, and the one that is easy to lose: a
  # standalone tour has no fleet, so it must keep working with the fleet flag
  # off. The personal tool stays free of what prices the fleet feature.
  test "a standalone tour's ledger does not need the fleet flag" do
    Flipper.disable("fleet_tours")
    sign_in @member

    assert_api_response :post, 201,
      path_params: {payoutLedgerId: @ledger.id},
      body: entry_body
  end
end

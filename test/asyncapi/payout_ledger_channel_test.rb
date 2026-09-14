# frozen_string_literal: true

require "asyncapi_helper"

# The ledger is shared, so one change fans out to every participant with an
# account -- which is why this asserts against a second participant's stream
# rather than the user who made the change.
class PayoutLedgerChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "payout_ledger:{user_gid}", channel_class: PayoutLedgerChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A payout ledger the user takes part in changed" do
      operationId "receivePayoutLedgerUpdate"
      message ::V1::Schemas::Payouts::PayoutLedger
    end
  end

  test "broadcasts the ledger payload to a participant when an entry is recorded" do
    ledger = create(:payout_ledger)
    recorder = create(:payout_participant, payout_ledger: ledger)
    other = create(:payout_participant, payout_ledger: ledger)

    payloads = assert_asyncapi_broadcast(params: {user_gid: other.user.to_gid_param}) do
      create(:payout_entry, payout_ledger: ledger, payout_participant: recorder, amount: 1000)
    end

    assert_equal ledger.id, payloads.first["id"]
  end

  # The rows themselves are created inside settle!, which is why PayoutTransfer
  # only broadcasts on update -- this is the update that matters.
  test "broadcasts to a participant when a transfer is confirmed" do
    ledger = create(:payout_ledger)
    spender = create(:payout_participant, payout_ledger: ledger)
    other = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, payout_ledger: ledger, payout_participant: spender, amount: 1000)

    # Settled through the ledger, so the transfer under test is a real one off
    # the settlement rather than a row assembled by hand.
    ledger.settle!

    payloads = assert_asyncapi_broadcast(params: {user_gid: other.user.to_gid_param}) do
      ledger.payout_transfers.first.confirm!
    end

    assert_equal ledger.id, payloads.first["id"]
  end

  # Whoever can answer a request to join a tour has no participant row until
  # they join one, so the fan-out over the participants would never reach them
  # -- and the request is exactly what they are waiting to see appear.
  test "broadcasts to a tour's organiser when somebody asks to join it" do
    Flipper.enable("tour_payouts")
    Flipper.enable("fleet_tours")

    organiser = create(:user)
    member = create(:user)
    fleet = create(:fleet, admins: [organiser], members: [member])
    tour = create(:tour, fleet: fleet, created_by: organiser)
    ledger = create(:payout_ledger, subject: tour)

    payloads = assert_asyncapi_broadcast(params: {user_gid: organiser.to_gid_param}) do
      create(:tour_join_request, tour: tour, user: member)
    end

    assert_equal ledger.id, payloads.first["id"]
  end

  test "broadcasts to a participant when the ledger is settled" do
    ledger = create(:payout_ledger)
    participant = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, payout_ledger: ledger, payout_participant: participant, amount: 1000)

    payloads = assert_asyncapi_broadcast(params: {user_gid: participant.user.to_gid_param}) do
      ledger.settle!
    end

    assert_equal 1, payloads.size
    assert_equal "settled", payloads.first["status"]
  end
end

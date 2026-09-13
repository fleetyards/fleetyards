# frozen_string_literal: true

# Per-user rather than per-ledger, like every other channel here: the
# connection already identifies who is listening, so a stream nobody else can
# address needs no authorization of its own. PayoutLedger#broadcast_change
# fans one change out to each participant's stream.
class PayoutLedgerChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end
end

# frozen_string_literal: true

class PayoutTransferPolicy < FleetBasePolicy
  authorize :payout_ledger, optional: true

  def index? = ledger_policy.read?

  # Either side of a transfer can tick it off -- the sender knows when they sent
  # it, the receiver knows when it arrived -- and so can whoever manages the
  # ledger.
  def confirm?
    return true if ledger_policy.manage?

    party_to_transfer?
  end

  alias_rule :unconfirm?, to: :confirm?

  private def ledger
    @ledger ||= record.try(:payout_ledger) || payout_ledger
  end

  private def ledger_policy
    @ledger_policy ||= PayoutLedgerPolicy.new(ledger, user: user, payout_ledger: ledger, fleet: fleet)
  end

  private def party_to_transfer?
    return false if user.blank? || !record.is_a?(PayoutTransfer)

    [record.from_participant, record.to_participant].compact.any? { |p| p.user_id == user.id }
  end
end

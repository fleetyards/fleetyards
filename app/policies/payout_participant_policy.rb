# frozen_string_literal: true

class PayoutParticipantPolicy < FleetBasePolicy
  authorize :payout_ledger, optional: true

  def index? = ledger_policy.read?

  # Changing who is on the list re-divides the profit across everyone, so it is
  # a manage action even though recording an entry is not.
  def create?
    ledger&.open? && ledger_policy.manage?
  end

  alias_rule :destroy?, to: :create?

  params_filter do |params|
    params.permit(:user_id, :username, :name)
  end

  private def ledger
    @ledger ||= record.try(:payout_ledger) || payout_ledger
  end

  private def ledger_policy
    @ledger_policy ||= PayoutLedgerPolicy.new(ledger, user: user, payout_ledger: ledger, fleet: fleet)
  end
end

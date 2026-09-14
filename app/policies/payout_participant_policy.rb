# frozen_string_literal: true

class PayoutParticipantPolicy < FleetBasePolicy
  authorize :payout_ledger, optional: true

  def index? = ledger_policy.read?

  # Changing who is on the list re-divides the profit across everyone, so it is
  # a manage action even though recording an entry is not.
  def create?
    ledger&.open? && ledger_policy.manage?
  end

  # A weight decides what the profit is divided by, so it answers to the same
  # right as adding and removing -- recording an entry does not earn it.
  alias_rule :destroy?, :update?, to: :create?

  params_filter do |params|
    params.permit(:user_id, :username, :name, :weight)
  end

  private def ledger
    @ledger ||= record.try(:payout_ledger) || payout_ledger
  end

  private def ledger_policy
    @ledger_policy ||= PayoutLedgerPolicy.new(ledger, user: user, payout_ledger: ledger, fleet: fleet)
  end
end

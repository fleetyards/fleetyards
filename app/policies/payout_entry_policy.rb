# frozen_string_literal: true

# Delegates every question about the ledger to PayoutLedgerPolicy, and only
# adds the one rule that is about the entry itself: who may touch a row once it
# exists.
class PayoutEntryPolicy < FleetBasePolicy
  authorize :payout_ledger, optional: true

  def index? = ledger_policy.read?

  def create? = ledger_policy.contribute?

  def update?
    return false unless ledger&.open?
    return true if ledger_policy.manage?

    own_entry? && ledger_policy.contribute?
  end

  alias_rule :destroy?, to: :update?

  params_filter do |params|
    params.permit(:payout_participant_id, :entry_type, :amount, :description, :notes, :occurred_at)
  end

  private def ledger
    @ledger ||= record.try(:payout_ledger) || payout_ledger
  end

  private def ledger_policy
    @ledger_policy ||= PayoutLedgerPolicy.new(ledger, user: user, payout_ledger: ledger, fleet: fleet)
  end

  # An entry belongs to whoever recorded it, not to the participant it names --
  # an organiser recording a guest's spending still owns that row.
  private def own_entry?
    user.present? && record.respond_to?(:recorded_by_id) && record.recorded_by_id == user.id
  end
end

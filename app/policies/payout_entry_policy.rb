# frozen_string_literal: true

# Delegates every question about the ledger to PayoutLedgerPolicy, and only
# adds the one rule that is about the entry itself: who may touch a row once it
# exists.
class PayoutEntryPolicy < FleetBasePolicy
  authorize :payout_ledger, optional: true

  def index? = ledger_policy.read?

  def create?
    return false unless ledger_policy.contribute?

    ledger_policy.manage? || own_participant?
  end

  def update?
    return false unless ledger&.open?
    return true if ledger_policy.manage?

    own_entry? && own_participant? && ledger_policy.contribute?
  end

  alias_rule :destroy?, to: :update?

  # Only an expense is ever pending, and only someone who could have recorded
  # it without review may let it count.
  def review?
    return false unless ledger&.open?
    return false unless record.respond_to?(:expense?) && record.expense?

    ledger_policy.manage?
  end

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

  # Everyone accounts for their own money. Without the manage right a
  # participant may only put an amount against their own row -- otherwise one
  # person could move everyone else's balance, and a guest, who has no account
  # to object with, is entirely at their mercy. An organiser records for
  # anyone, which is the only way a guest's spending reaches the ledger at all.
  private def own_participant?
    return false if user.blank?

    participant = record.try(:payout_participant)

    # A missing participant is a validation error rather than an authorization
    # one, so it falls through to the 400 the client knows how to render.
    return true if participant.blank?

    participant.user_id == user.id
  end
end

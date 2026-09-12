# frozen_string_literal: true

# Shared by every controller that hangs off a ledger rather than off one of its
# owners. The children are addressed top-level by ledger id -- the same shape
# fleet_event_slots uses -- so each of them needs the same three things: find
# the ledger, work out which feature scope gates it, and hand the ledger to the
# policies as context.
module PayoutLedgerScoped
  extend ActiveSupport::Concern

  # Deliberately no `included do ... before_action`: a callback registered from
  # here runs before the ones the including controller declares, so the ledger
  # would be looked up and authorized before doorkeeper had a chance to reject
  # an unauthenticated request -- turning every 401 into a 403. Each controller
  # declares these two itself, after its scope gates.

  private def set_payout_ledger
    @payout_ledger = PayoutLedger.includes(:subject).find(params[:payout_ledger_id] || params[:id])

    authorize! @payout_ledger, with: PayoutLedgerPolicy, to: :show?
  end

  # One flag, two surfaces. A ledger on a fleet event is gated for that fleet;
  # a tour is gated for the signed-in user alone, since it has no fleet to
  # carry the toggle.
  private def check_tour_payouts_feature
    actors = @payout_ledger&.fleet ? [@payout_ledger.fleet] : []
    return if feature_enabled?("tour_payouts", *actors)

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end

  private def ledger_context
    {payout_ledger: @payout_ledger, fleet: @payout_ledger&.fleet}
  end
end

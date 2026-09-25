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

  # Two flags, and which apply depends on what the ledger hangs off -- three
  # for a contract, which also needs `fleet_contracts`.
  #
  # `tour_payouts` is what makes a ledger exist at all and gates every one of
  # them. A ledger that belongs to a fleet -- an event always, a tour when it
  # was organised from a fleet's page -- is a *fleet* surface and needs
  # `fleet_tours` on top. A standalone tour under /tools/ has no fleet to carry
  # a toggle and stays on `tour_payouts` alone, which is what keeps the personal
  # tool free of the fleet flag.
  private def check_tour_payouts_feature
    fleet = @payout_ledger&.fleet
    actors = fleet ? [fleet] : []

    return render_payouts_unavailable unless feature_enabled?("tour_payouts", *actors)
    return render_payouts_unavailable if fleet.present? && !feature_enabled?("fleet_tours", *actors)
    return if !contract_ledger? || feature_enabled?("fleet_contracts", *actors)

    render_payouts_unavailable
  end

  # A contract's ledger is a contracts surface as well as a payouts one, so it
  # is also gated the way the contract itself is.
  private def check_contract_subscription
    return unless contract_ledger?

    require_fleet_subscription(:contracts)
  end

  private def contract_ledger?
    @payout_ledger&.subject.is_a?(FleetContract)
  end

  private def render_payouts_unavailable
    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end

  # Nil for a standalone tour's ledger, which is the personal tool and stays
  # free -- the same split check_tour_payouts_feature makes above.
  private def subscription_fleet
    @payout_ledger&.fleet
  end

  private def ledger_context
    {payout_ledger: @payout_ledger, fleet: @payout_ledger&.fleet}
  end
end

# frozen_string_literal: true

# Declare `before_action -> { require_fleet_subscription(:capability) }`
# **after** the capability's own flag check, and after the doorkeeper callbacks
# so an unauthenticated request still gets a 401.
#
# The order carries meaning (D10). Two questions are asked, and both must pass:
#
#   is this feature rolled out here?  -> Flipper       -> `forbidden`
#   has this fleet bought it?         -> subscriptions -> `subscription_required`
#
# A feature that is not rolled out answers "not available" to everyone,
# subscribed or not. Only one that *is* rolled out and unbought answers with an
# upsell. Reversed, a fleet would be sold something it could not yet have.
#
# Flipper never learns the word premium and this never learns about rollout --
# except for the one gate below, which is rollout of *enforcement itself*.
module FleetSubscriptionConcern
  extend ActiveSupport::Concern

  # `fleet_subscriptions` gates whether enforcement runs at all, not whether a
  # fleet is entitled. While it is off this is inert and nothing about the four
  # capabilities changes -- which is what lets the whole entitlement half ship
  # to production before the transition is announced (D16).
  #
  # Actor-aware on purpose: enabling it for one fleet enforces there first,
  # rather than for all 13,746 at once on a single switch.
  private def require_fleet_subscription(capability)
    return unless Subscriptions::PREMIUM_FEATURES.include?(capability)

    # No fleet, nothing to have bought. A standalone tour under /tools/ and its
    # ledger reach here with none, and they are personal surfaces that stay
    # free (D3) -- without this they would be the one thing a *fleet*
    # subscription paywalled.
    fleet = subscription_fleet
    return if fleet.blank?

    return unless enforcement_rolled_out?(fleet)
    return if fleet.subscribed?

    render json: {
      code: "subscription_required",
      message: I18n.t("messages.subscription_required")
    }, status: :forbidden
  end

  private def enforcement_rolled_out?(fleet)
    feature_enabled?("fleet_subscriptions", fleet)
  end

  # `@fleet` on every fleet-scoped controller, which is what `set_fleet`
  # assigns. A controller that reaches its fleet another way overrides this --
  # the payout ledger's, for one, hangs off a ledger rather than a slug.
  private def subscription_fleet
    @fleet
  end
end

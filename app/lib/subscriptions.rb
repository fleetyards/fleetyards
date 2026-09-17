# frozen_string_literal: true

# What a fleet subscription covers, and what it takes to hold one.
#
# One place on purpose: the capability list is read by the enforcement concern
# (#4957) and the reconciler (#4954), and a second copy would drift from this
# one the first time a capability is added.
module Subscriptions
  # Four capabilities, one flat tier (D4). Deliberately not per-capability
  # pricing: splitting them means deciding which of contracts, events,
  # logistics and tours is worth less than the others, before a single fleet
  # has paid for any of them.
  #
  # These are capability keys, not flag names. They map one-to-one onto flags
  # today, and that is a fact about today rather than something to depend on --
  # Flipper answers rollout, this answers entitlement, and the two are asked
  # separately (D1).
  PREMIUM_FEATURES = %i[contracts events logistics tours].freeze

  # The figure, in cents. A one-off is judged on `amount_cents`, which
  # `SupporterImporter#apply_amount` has already normalised to EUR through
  # ExchangeRateFetcher, so nothing converts at read time.
  #
  # A standing pledge is judged on the currency it was pledged in instead --
  # see `qualifying?`. Matches the second SUPPORTER_TIERS step on User, which is
  # the figure a recurring pledge already has to clear to read as committed
  # support.
  QUALIFYING_AMOUNT_CENTS = 500

  def self.qualifying_amount_cents
    QUALIFYING_AMOUNT_CENTS
  end

  # Whether this contribution, on its own, is enough to open a subscription.
  # Whether it is active, and which fleet it names, are the reconciler's
  # questions rather than this one's.
  def self.qualifying?(contribution)
    return true if contribution.amount_cents.to_i >= QUALIFYING_AMOUNT_CENTS

    standing_pledge_at_the_figure?(contribution)
  end

  # A standing pledge is judged on what the supporter set it to, not on what
  # the exchange rate made of it this month.
  #
  # Every recurring pledge on the platform today is $5, which converts to €4.36
  # -- so an amount-only rule refuses the only people currently paying, which is
  # the one outcome D16 exists to prevent. The commitment did not change; the
  # rate did.
  #
  # Source-blind, because `User#supporter_recurring?` already settled that a
  # standing pledge is one whatever it was set up on. The comparison is against
  # the figure in the currency it was pledged in, which is not the same unit --
  # deliberately so: $5 a month and €5 a month are the same commitment, and
  # pricing them apart by the day's rate is what this avoids.
  private_class_method def self.standing_pledge_at_the_figure?(contribution)
    return false unless contribution.recurring?

    contribution.source_amount_cents.to_i >= QUALIFYING_AMOUNT_CENTS
  end
end

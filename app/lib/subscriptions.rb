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

  # The figure, in EUR cents, compared against `amount_cents` -- which
  # `SupporterImporter#apply_amount` and `Kofi::PaymentImporter#apply_amount`
  # have both already normalised through ExchangeRateFetcher. One currency, one
  # comparison, no conversion at read time.
  #
  # Set below EUR 5 on purpose. Every standing pledge on the platform is $5,
  # which converts to about EUR 4.36, and refusing the only people currently
  # paying is the outcome D16 exists to prevent. EUR 4 clears that with room for
  # the rate to move against us by roughly 8% before it bites again.
  #
  # This is the one number that decides who qualifies, so it is meant to be
  # argued about rather than inherited.
  QUALIFYING_AMOUNT_CENTS = 400

  def self.qualifying_amount_cents
    QUALIFYING_AMOUNT_CENTS
  end

  # Whether this contribution, on its own, is enough to open a subscription.
  # Whether it is active, and which fleet it names, are the reconciler's
  # questions rather than this one's.
  #
  # Only the normalised figure is compared. An earlier version also accepted
  # `source_amount_cents` against the same number, to let a $5 pledge through --
  # but minor units are not comparable across currencies, so 500 HUF (about
  # EUR 1.25) qualified too. The pledge problem is a question about the figure,
  # not about which currency to measure it in.
  def self.qualifying?(contribution)
    contribution.amount_cents.to_i >= QUALIFYING_AMOUNT_CENTS
  end
end

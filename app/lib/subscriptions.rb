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
  #
  # The figure is met in *either* currency: the normalised EUR amount, or what
  # the supporter actually set in the currency they set it in.
  #
  # Deliberately not keyed on `recurring?`. Every pledge on the platform today
  # is $5, which converts to EUR 4.36, so an EUR-only rule refuses the only
  # people currently paying -- and `recurring` is not the axis that separates
  # them, because the two importers record a standing pledge differently.
  # Patreon marks one row recurring; Ko-fi deliberately writes a fresh
  # non-recurring row per payment, since it notifies on payment and never on
  # cancellation. Keying on the flag would qualify a $5 Patreon pledge and
  # refuse an identical $5 Ko-fi subscription, which is a fact about our
  # importers rather than about what the supporter did.
  #
  # The cost is that a one-off $5 also clears an EUR 5 bar. That is the right
  # side to err on: the alternative refuses somebody who gave what was asked
  # because the rate moved between their pledge and the read.
  def self.qualifying?(contribution)
    [contribution.amount_cents, contribution.source_amount_cents]
      .compact
      .any? { |cents| cents >= QUALIFYING_AMOUNT_CENTS }
  end
end

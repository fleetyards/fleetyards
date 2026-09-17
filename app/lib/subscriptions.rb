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

  # In EUR cents, compared against `amount_cents` rather than the source
  # currency: `SupporterImporter#apply_amount` already normalises through
  # ExchangeRateFetcher and stores both figures, so nothing converts at read
  # time and a rate move cannot silently drop a fleet below the line.
  #
  # Matches the second SUPPORTER_TIERS step on User, which is the figure a
  # recurring pledge already has to clear to read as committed support.
  QUALIFYING_AMOUNT_CENTS = 500

  def self.qualifying_amount_cents
    QUALIFYING_AMOUNT_CENTS
  end

  # Whether this contribution, on its own, is enough to open a subscription.
  # Amount only -- whether it is active, and which fleet it names, are the
  # reconciler's questions rather than this one's.
  def self.qualifying_amount?(contribution)
    contribution.amount_cents.to_i >= QUALIFYING_AMOUNT_CENTS
  end
end

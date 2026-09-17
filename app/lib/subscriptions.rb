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

  # The figure, in the currency the supporter pledged in.
  #
  # Five of your own currency, which is how Patreon and Ko-fi price a tier in
  # the first place. A single EUR figure cannot express that: Patreon bills in
  # USD, so a $5 pledge lands as whatever the rate made of it that day, and
  # comparing that to a EUR bar gives different answers to identical pledges
  # depending on when each one was first imported.
  #
  # That is not hypothetical. `Patreon::SupporterImporter#apply_amount` skips
  # reconversion while the pledge amount is unchanged, so an existing patron's
  # EUR figure is frozen at the day-one rate, while a new patron pledging the
  # same $5 is converted at today's. One EUR threshold would eventually pass the
  # first and refuse the second. Ko-fi reconverts on every payment, so a monthly
  # subscriber could qualify one month and not the next.
  QUALIFYING_AMOUNTS = {
    "EUR" => 500,
    "USD" => 500,
    "GBP" => 500,
    "CAD" => 700,
    "AUD" => 800
  }.freeze

  # For a currency nobody has priced: convert and compare in EUR. Deliberately
  # not "500 of anything" -- minor units are not comparable, and 500 HUF is
  # about EUR 1.25.
  FALLBACK_CURRENCY = "EUR"

  def self.qualifying_amount_cents(currency = FALLBACK_CURRENCY)
    QUALIFYING_AMOUNTS.fetch(currency.to_s.upcase, QUALIFYING_AMOUNTS.fetch(FALLBACK_CURRENCY))
  end

  # Whether this contribution, on its own, is enough to open a subscription.
  # Whether it is active, and which fleet it names, are the reconciler's
  # questions rather than this one's.
  #
  # Judged in the currency it was pledged in when that currency has a figure,
  # so the same pledge always gives the same answer however the rate moved
  # since. Anything else falls back to the normalised EUR amount, which is what
  # keeps an unpriced currency from qualifying on its minor units alone.
  def self.qualifying?(contribution)
    currency = contribution.source_currency.to_s.upcase

    if QUALIFYING_AMOUNTS.key?(currency)
      contribution.source_amount_cents.to_i >= QUALIFYING_AMOUNTS.fetch(currency)
    else
      contribution.amount_cents.to_i >= qualifying_amount_cents
    end
  end
end

# frozen_string_literal: true

# What a fleet subscription covers, and what it takes to hold one.
#
# One place on purpose: the capability list is read by the enforcement concern
# and the reconciler, and a second copy would drift from this
# one the first time a capability is added.
module Subscriptions
  # Four capabilities, one flat tier. Deliberately not per-capability
  # pricing: splitting them means deciding which of contracts, events,
  # logistics and tours is worth less than the others, before a single fleet
  # has paid for any of them.
  #
  # These are capability keys, not flag names. They map one-to-one onto flags
  # today, and that is a fact about today rather than something to depend on --
  # Flipper answers rollout, this answers entitlement, and the two are asked
  # separately.
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
  # Judged on the amount in whatever currency that amount is actually in, so
  # the same pledge gives the same answer however the rate moved since. The
  # importers set the source pair and normalise `amount_cents` to EUR; an
  # admin-entered row has no source pair, and its `amount_cents` is in whatever
  # `currency` says -- which is not always EUR, and reading it as though it were
  # let CAD 5 clear a figure meant to be CAD 7.
  def self.qualifying?(contribution)
    amount, currency =
      if priced?(contribution.source_currency)
        # Priced: judge the pledge in the currency it was pledged in.
        [contribution.source_amount_cents, contribution.source_currency]
      elsif contribution.source_currency.present?
        # Unpriced but imported, so `amount_cents` is the normalised EUR figure.
        [contribution.amount_cents, FALLBACK_CURRENCY]
      else
        # Hand-entered: `amount_cents` is in whatever `currency` says.
        [contribution.amount_cents, contribution.currency]
      end

    amount.to_i >= qualifying_amount_cents(currency)
  end

  # A currency nobody has priced falls back to the EUR figure. For an imported
  # row that is exact -- `amount_cents` is already normalised, so the comparison
  # is EUR against EUR, and 500 HUF stays the EUR 1.25 it is worth. For a
  # hand-entered row in an unpriced currency there is nothing to convert from,
  # so the figure is the best available answer rather than a correct one; price
  # the currency here if that ever stops being rare.
  private_class_method def self.priced?(currency)
    QUALIFYING_AMOUNTS.key?(currency.to_s.upcase)
  end
end

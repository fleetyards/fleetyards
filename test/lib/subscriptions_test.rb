# frozen_string_literal: true

require "test_helper"

class SubscriptionsTest < ActiveSupport::TestCase
  test "it names the four capabilities a subscription covers" do
    assert_equal %i[contracts events logistics tours], Subscriptions::PREMIUM_FEATURES
  end

  test "the capability list cannot be edited in place" do
    assert Subscriptions::PREMIUM_FEATURES.frozen?
  end

  test "a contribution at or above the figure qualifies" do
    below = build(:supporter_contribution, amount_cents: Subscriptions::QUALIFYING_AMOUNT_CENTS - 1)
    exact = build(:supporter_contribution, amount_cents: Subscriptions::QUALIFYING_AMOUNT_CENTS)
    above = build(:supporter_contribution, amount_cents: Subscriptions::QUALIFYING_AMOUNT_CENTS + 1)

    refute Subscriptions.qualifying?(below)
    assert Subscriptions.qualifying?(exact), "the figure itself qualifies"
    assert Subscriptions.qualifying?(above)
  end

  # The case an EUR-only rule gets wrong: every pledge on the platform today is
  # $5, which converts to EUR 4.36. Refusing them is the outcome D16 exists to
  # prevent.
  test "the figure is met in the currency the supporter set it in" do
    pledge = build(:supporter_contribution,
      recurring: true,
      amount_cents: 436,
      source_amount_cents: 500,
      source_currency: "USD")

    assert Subscriptions.qualifying?(pledge),
      "a $5 pledge must not be refused because the rate moved"
  end

  # The two importers record a standing pledge differently -- Patreon marks the
  # row recurring, Ko-fi writes a fresh non-recurring row per payment because it
  # never notifies on cancellation. Keying on the flag would qualify one and
  # refuse the other for identical money.
  test "an identical pledge qualifies however its importer recorded it" do
    patreon = build(:supporter_contribution, source: "patreon", recurring: true,
      amount_cents: 436, source_amount_cents: 500, source_currency: "USD")
    kofi = build(:supporter_contribution, source: "kofi", recurring: false,
      amount_cents: 436, source_amount_cents: 500, source_currency: "USD")

    assert Subscriptions.qualifying?(patreon)
    assert Subscriptions.qualifying?(kofi),
      "a Ko-fi subscription payment is not recurring by design, and still counts"
  end

  test "below the figure in both currencies does not qualify" do
    contribution = build(:supporter_contribution,
      recurring: true,
      amount_cents: 200,
      source_amount_cents: 200,
      source_currency: "USD")

    refute Subscriptions.qualifying?(contribution)
  end

  test "a contribution with no source amount is judged on the EUR figure alone" do
    contribution = build(:supporter_contribution,
      amount_cents: Subscriptions::QUALIFYING_AMOUNT_CENTS,
      source_amount_cents: nil,
      source_currency: nil)

    assert Subscriptions.qualifying?(contribution)
  end
end

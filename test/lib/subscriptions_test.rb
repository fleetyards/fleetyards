# frozen_string_literal: true

require "test_helper"

class SubscriptionsTest < ActiveSupport::TestCase
  test "it names the four capabilities a subscription covers" do
    assert_equal %i[contracts events logistics tours], Subscriptions::PREMIUM_FEATURES
  end

  test "the capability list cannot be edited in place" do
    assert Subscriptions::PREMIUM_FEATURES.frozen?
  end

  test "a EUR contribution is judged on the EUR figure" do
    below = build(:supporter_contribution, amount_cents: 499,
      source_amount_cents: 499, source_currency: "EUR")
    exact = build(:supporter_contribution, amount_cents: 500,
      source_amount_cents: 500, source_currency: "EUR")

    refute Subscriptions.qualifying?(below)
    assert Subscriptions.qualifying?(exact), "the figure itself qualifies"
  end

  # The reason this is per currency at all. Patreon bills in USD, and
  # `SupporterImporter#apply_amount` skips reconversion while the pledge amount
  # is unchanged -- so an existing patron's EUR figure is frozen at the day-one
  # rate while a new patron pledging the same $5 is converted at today's. A
  # single EUR bar would eventually pass one and refuse the other.
  test "the same pledge qualifies whatever the rate made of it" do
    frozen_at_day_one = build(:supporter_contribution,
      amount_cents: 436, source_amount_cents: 500, source_currency: "USD")
    converted_at_a_worse_rate = build(:supporter_contribution,
      amount_cents: 390, source_amount_cents: 500, source_currency: "USD")

    assert Subscriptions.qualifying?(frozen_at_day_one)
    assert Subscriptions.qualifying?(converted_at_a_worse_rate),
      "a $5 pledge is a $5 pledge whatever EUR/USD did since"
  end

  test "a pledge below its own currency's figure does not qualify" do
    contribution = build(:supporter_contribution,
      amount_cents: 350, source_amount_cents: 400, source_currency: "USD")

    refute Subscriptions.qualifying?(contribution)
  end

  test "a contribution with no source currency falls back to the EUR figure" do
    contribution = build(:supporter_contribution,
      amount_cents: 500, source_amount_cents: nil, source_currency: nil)

    assert Subscriptions.qualifying?(contribution)
  end

  # An admin-entered row has no source pair, and its `amount_cents` is in
  # whatever `currency` says -- reading it as EUR let CAD 5 clear a figure meant
  # to be CAD 7.
  test "a hand-entered row is judged in its own stated currency" do
    below = build(:supporter_contribution, amount_cents: 500,
      currency: "CAD", source_amount_cents: nil, source_currency: nil)
    at_the_figure = build(:supporter_contribution, amount_cents: 700,
      currency: "CAD", source_amount_cents: nil, source_currency: nil)

    refute Subscriptions.qualifying?(below), "CAD 5 is not the CAD figure"
    assert Subscriptions.qualifying?(at_the_figure)
  end

  # Imported rows always carry the source pair, and `amount_cents` is already
  # normalised -- so an unpriced currency is compared EUR against EUR.
  test "an imported row in an unpriced currency is compared on its EUR value" do
    small = build(:supporter_contribution, amount_cents: 125,
      source_amount_cents: 500, source_currency: "HUF", currency: "EUR")
    large = build(:supporter_contribution, amount_cents: 600,
      source_amount_cents: 240_000, source_currency: "HUF", currency: "EUR")

    refute Subscriptions.qualifying?(small), "500 HUF is about EUR 1.25"
    assert Subscriptions.qualifying?(large)
  end

  test "the figure is looked up per currency and falls back to EUR" do
    assert_equal 500, Subscriptions.qualifying_amount_cents("USD")
    assert_equal 500, Subscriptions.qualifying_amount_cents("usd"), "case does not matter"
    assert_equal 700, Subscriptions.qualifying_amount_cents("CAD")
    assert_equal Subscriptions.qualifying_amount_cents("EUR"),
      Subscriptions.qualifying_amount_cents("HUF")
  end

  test "the figures cannot be edited in place" do
    assert Subscriptions::QUALIFYING_AMOUNTS.frozen?
  end
end

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

  # Minor units are not comparable across currencies: 500 HUF is about EUR 1.25.
  test "an unpriced currency is converted rather than compared on its units" do
    contribution = build(:supporter_contribution,
      amount_cents: 125, source_amount_cents: 500, source_currency: "HUF")

    refute Subscriptions.qualifying?(contribution)
  end

  test "an unpriced currency still qualifies once it converts above the figure" do
    contribution = build(:supporter_contribution,
      amount_cents: 600, source_amount_cents: 240_000, source_currency: "HUF")

    assert Subscriptions.qualifying?(contribution)
  end

  test "a contribution with no source currency falls back to the EUR figure" do
    contribution = build(:supporter_contribution,
      amount_cents: 500, source_amount_cents: nil, source_currency: nil)

    assert Subscriptions.qualifying?(contribution)
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

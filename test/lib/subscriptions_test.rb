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

  # The case that matters most, and the one an amount-only rule gets wrong:
  # every recurring pledge on the platform today is $5, which converts to
  # €4.36. Refusing them is the outcome D16 exists to prevent.
  test "a standing pledge is judged on what it was set to, not the day's rate" do
    pledge = build(:supporter_contribution,
      recurring: true,
      amount_cents: 436,
      source_amount_cents: 500,
      source_currency: "USD")

    assert Subscriptions.qualifying?(pledge),
      "a $5 monthly pledge must not be refused because the rate moved"
  end

  test "a standing pledge below the figure in its own currency does not qualify" do
    pledge = build(:supporter_contribution,
      recurring: true,
      amount_cents: 100,
      source_amount_cents: 100,
      source_currency: "USD")

    refute Subscriptions.qualifying?(pledge)
  end

  # Source-blind, the way User#supporter_recurring? already decided: a standing
  # pledge is one whatever platform it was set up on.
  test "a standing pledge qualifies whatever it was set up on" do
    %w[patreon kofi].each do |platform|
      pledge = build(:supporter_contribution,
        source: platform,
        recurring: true,
        amount_cents: 436,
        source_amount_cents: 500,
        source_currency: "USD")

      assert Subscriptions.qualifying?(pledge), "#{platform} pledge should qualify"
    end
  end

  test "a one-off below the figure does not qualify however it was paid" do
    one_off = build(:supporter_contribution,
      recurring: false,
      amount_cents: 436,
      source_amount_cents: 500,
      source_currency: "USD")

    refute Subscriptions.qualifying?(one_off),
      "only a standing pledge is judged on its source amount"
  end
end

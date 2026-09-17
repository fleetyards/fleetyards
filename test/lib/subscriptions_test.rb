# frozen_string_literal: true

require "test_helper"

class SubscriptionsTest < ActiveSupport::TestCase
  test "it names the four capabilities a subscription covers" do
    assert_equal %i[contracts events logistics tours], Subscriptions::PREMIUM_FEATURES
  end

  test "the capability list cannot be edited in place" do
    assert Subscriptions::PREMIUM_FEATURES.frozen?
  end

  # Against the normalised EUR figure, never the source currency: the importer
  # already converts, so a rate move cannot drop a fleet below the line at read
  # time.
  test "a contribution qualifies on the EUR amount rather than what was paid" do
    below = build(:supporter_contribution, amount_cents: Subscriptions::QUALIFYING_AMOUNT_CENTS - 1)
    exact = build(:supporter_contribution, amount_cents: Subscriptions::QUALIFYING_AMOUNT_CENTS)
    above = build(:supporter_contribution, amount_cents: Subscriptions::QUALIFYING_AMOUNT_CENTS + 1)

    refute Subscriptions.qualifying_amount?(below)
    assert Subscriptions.qualifying_amount?(exact), "the figure itself qualifies"
    assert Subscriptions.qualifying_amount?(above)
  end

  test "a contribution in another currency is judged on its converted amount" do
    contribution = build(:supporter_contribution,
      amount_cents: Subscriptions::QUALIFYING_AMOUNT_CENTS,
      source_amount_cents: 1,
      source_currency: "USD")

    assert Subscriptions.qualifying_amount?(contribution)
  end
end

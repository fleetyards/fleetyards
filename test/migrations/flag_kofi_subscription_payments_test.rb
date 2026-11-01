# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261101120100_flag_kofi_subscription_payments.rb")

class FlagKofiSubscriptionPaymentsTest < ActiveSupport::TestCase
  private def kofi(started_at, **attrs)
    create(:supporter_contribution, source: "kofi", started_at:, **attrs)
  end

  test "payments a month apart from the same account are flagged" do
    user = create(:user)
    september = kofi(Date.new(2026, 9, 16), user:)
    october = kofi(Date.new(2026, 10, 16), user:)

    FlagKofiSubscriptionPayments.new.up

    assert september.reload.kofi_subscription?
    assert october.reload.kofi_subscription?
  end

  test "an unlinked payer is matched by email, whatever its case" do
    first = kofi(Date.new(2026, 9, 3), payer_email: "pilot@example.com")
    second = kofi(Date.new(2026, 10, 3), payer_email: "Pilot@Example.com")

    FlagKofiSubscriptionPayments.new.up

    assert first.reload.kofi_subscription?
    assert second.reload.kofi_subscription?
  end

  test "a linked and an unlinked payment from the same email are paired" do
    linked = kofi(Date.new(2026, 9, 16), user: create(:user), payer_email: "pilot@example.com")
    unlinked = kofi(Date.new(2026, 10, 16), payer_email: "pilot@example.com")

    FlagKofiSubscriptionPayments.new.up

    assert linked.reload.kofi_subscription?
    assert unlinked.reload.kofi_subscription?
  end

  test "a gift between two renewals does not hide them" do
    user = create(:user)
    september = kofi(Date.new(2026, 9, 1), user:)
    gift = kofi(Date.new(2026, 9, 15), user:)
    october = kofi(Date.new(2026, 10, 1), user:)

    FlagKofiSubscriptionPayments.new.up

    assert september.reload.kofi_subscription?
    assert october.reload.kofi_subscription?
    assert_not gift.reload.kofi_subscription?
  end

  test "a single payment, or two far apart, stays a one-off" do
    user = create(:user)
    once = kofi(Date.new(2026, 10, 16), payer_email: "once@example.com")
    spring = kofi(Date.new(2026, 4, 1), user:)
    autumn = kofi(Date.new(2026, 10, 1), user:)

    FlagKofiSubscriptionPayments.new.up

    assert_not once.reload.kofi_subscription?
    assert_not spring.reload.kofi_subscription?
    assert_not autumn.reload.kofi_subscription?
  end

  test "different payers are never paired with each other" do
    kofi(Date.new(2026, 9, 16), payer_email: "a@example.com")
    kofi(Date.new(2026, 10, 16), payer_email: "b@example.com")

    FlagKofiSubscriptionPayments.new.up

    assert_not SupporterContribution.where(kofi_subscription: true).exists?
  end
end

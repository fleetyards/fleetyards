# frozen_string_literal: true

# == Schema Information
#
# Table name: supporter_contributions
#
#  id           :uuid             not null, primary key
#  amount_cents :integer          not null
#  anonymous    :boolean          default(FALSE), not null
#  currency     :string           default("EUR"), not null
#  ended_at     :date
#  name         :string
#  note         :text
#  recurring    :boolean          default(FALSE), not null
#  started_at   :date             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_supporter_contributions_on_recurring_and_ended_at  (recurring,ended_at)
#  index_supporter_contributions_on_started_at              (started_at)
#
require "test_helper"

class SupporterContributionTest < ActiveSupport::TestCase
  test "requires amount_cents > 0 and started_at; name is optional" do
    refute SupporterContribution.new(amount_cents: 0, started_at: Date.current).valid?
    refute SupporterContribution.new(amount_cents: 100, started_at: nil).valid?
    assert SupporterContribution.new(amount_cents: 100, started_at: Date.current).valid?
    assert SupporterContribution.new(name: nil, amount_cents: 100, started_at: Date.current).valid?
    assert SupporterContribution.new(name: "", amount_cents: 100, started_at: Date.current).valid?
  end

  test "auto-sets anonymous when name is blank" do
    contribution = create(:supporter_contribution, name: nil, anonymous: false)
    assert contribution.anonymous?

    contribution = create(:supporter_contribution, name: "", anonymous: false)
    assert contribution.anonymous?

    contribution = create(:supporter_contribution, name: "Alice", anonymous: false)
    refute contribution.anonymous?
  end

  test "validates ended_at is on or after started_at" do
    record = SupporterContribution.new(
      amount_cents: 100,
      started_at: Date.new(2026, 6, 1),
      ended_at: Date.new(2026, 5, 1)
    )

    refute record.valid?
    assert_includes record.errors[:ended_at], record.errors.generate_message(:ended_at, :must_be_after_started_at)
  end

  test ".active_in includes one-time contributions whose started_at lands in the month" do
    in_month = create(:supporter_contribution, started_at: Date.new(2026, 6, 10))
    before_month = create(:supporter_contribution, started_at: Date.new(2026, 5, 28))
    after_month = create(:supporter_contribution, started_at: Date.new(2026, 7, 1))

    ids = SupporterContribution.active_in(Date.new(2026, 6, 1), Date.new(2026, 6, 30)).pluck(:id)

    assert_includes ids, in_month.id
    refute_includes ids, before_month.id
    refute_includes ids, after_month.id
  end

  test ".active_in includes ongoing recurring contributions that overlap the month" do
    ongoing = create(:supporter_contribution, :recurring, started_at: Date.new(2026, 1, 1))
    ended_before = create(:supporter_contribution, :recurring, started_at: Date.new(2025, 1, 1), ended_at: Date.new(2026, 5, 31))
    ended_during = create(:supporter_contribution, :recurring, started_at: Date.new(2025, 1, 1), ended_at: Date.new(2026, 6, 15))
    starts_after = create(:supporter_contribution, :recurring, started_at: Date.new(2026, 7, 1))

    ids = SupporterContribution.active_in(Date.new(2026, 6, 1), Date.new(2026, 6, 30)).pluck(:id)

    assert_includes ids, ongoing.id
    assert_includes ids, ended_during.id
    refute_includes ids, ended_before.id
    refute_includes ids, starts_after.id
  end

  test ".monthly_total sums amount_cents of active contributions" do
    create(:supporter_contribution, amount_cents: 500, started_at: Date.new(2026, 6, 5))
    create(:supporter_contribution, :recurring, amount_cents: 1_000, started_at: Date.new(2026, 1, 1))
    create(:supporter_contribution, amount_cents: 9_999, started_at: Date.new(2026, 5, 28))

    assert_equal 1_500, SupporterContribution.monthly_total(Date.new(2026, 6, 15))
  end
end

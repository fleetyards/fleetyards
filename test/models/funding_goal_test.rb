# frozen_string_literal: true

# == Schema Information
#
# Table name: funding_goals
#
#  id             :uuid             not null, primary key
#  amount_cents   :integer          not null
#  currency       :string           default("EUR"), not null
#  description    :text
#  effective_from :date             not null
#  ended_at       :date
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_funding_goals_on_effective_from  (effective_from)
#  index_funding_goals_on_ended_at        (ended_at)
#
require "test_helper"

class FundingGoalTest < ActiveSupport::TestCase
  test "requires title, amount_cents > 0, effective_from" do
    refute FundingGoal.new(amount_cents: 100, effective_from: Date.current).valid?
    refute FundingGoal.new(title: "x", amount_cents: 0, effective_from: Date.current).valid?
    refute FundingGoal.new(title: "x", amount_cents: -10, effective_from: Date.current).valid?
    refute FundingGoal.new(title: "x", amount_cents: 100).valid?
    assert FundingGoal.new(title: "x", amount_cents: 1, effective_from: Date.current).valid?
  end

  test "validates ended_at is on or after effective_from" do
    record = FundingGoal.new(
      title: "x", amount_cents: 100,
      effective_from: Date.new(2026, 6, 1),
      ended_at: Date.new(2026, 5, 1)
    )

    refute record.valid?
    assert_includes record.errors[:ended_at], record.errors.generate_message(:ended_at, :must_be_after_effective_from)
  end

  test ".active_on includes goals where effective_from <= date and not yet ended" do
    in_window = create(:funding_goal, effective_from: 30.days.ago.to_date, ended_at: nil)
    future = create(:funding_goal, effective_from: 30.days.from_now.to_date)
    ended_before = create(:funding_goal, effective_from: 90.days.ago.to_date, ended_at: 30.days.ago.to_date)
    ends_today = create(:funding_goal, effective_from: 90.days.ago.to_date, ended_at: Date.current)

    ids = FundingGoal.active_on(Date.current).pluck(:id)

    assert_includes ids, in_window.id
    assert_includes ids, ends_today.id
    refute_includes ids, future.id
    refute_includes ids, ended_before.id
  end

  test ".monthly_total sums amount_cents of all active goals" do
    create(:funding_goal, amount_cents: 5_000, effective_from: 30.days.ago.to_date)
    create(:funding_goal, amount_cents: 3_000, effective_from: 1.day.ago.to_date)
    create(:funding_goal, amount_cents: 9_999, effective_from: 30.days.from_now.to_date)

    assert_equal 8_000, FundingGoal.monthly_total
  end

  test ".active_for_month returns empty relation when no goals exist" do
    assert_equal 0, FundingGoal.active_for_month.count
  end
end

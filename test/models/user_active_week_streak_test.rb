# frozen_string_literal: true

require "test_helper"

class UserActiveWeekStreakTest < ActiveSupport::TestCase
  # A Wednesday, so a week either side stays clear of the boundary.
  NOW = Time.zone.local(2026, 10, 21, 12, 0)

  test "the first activity starts a streak" do
    user = create(:user)

    user.record_activity!(NOW)

    assert_equal 1, user.reload.active_week_streak
    assert_equal NOW, user.last_active_at
  end

  test "activity in the week after the last one extends the streak" do
    user = create(:user, last_active_at: NOW - 1.week, active_week_streak: 4)

    user.record_activity!(NOW)

    assert_equal 5, user.reload.active_week_streak
  end

  test "more activity in the same week leaves the streak as it is" do
    user = create(:user, last_active_at: NOW - 1.day, active_week_streak: 4)

    user.record_activity!(NOW)

    assert_equal 4, user.reload.active_week_streak
  end

  test "a week without activity starts the streak over" do
    user = create(:user, last_active_at: NOW - 2.weeks, active_week_streak: 4)

    user.record_activity!(NOW)

    assert_equal 1, user.reload.active_week_streak
  end

  test "activity right after the week turns extends the streak" do
    monday = NOW.beginning_of_week
    user = create(:user, last_active_at: monday - 1.minute, active_week_streak: 2)

    user.record_activity!(monday + 1.minute)

    assert_equal 3, user.reload.active_week_streak
  end

  test "a user who objected to usage analytics keeps no streak" do
    user = create(:user, tracking: false, last_active_at: NOW - 1.week)

    user.record_activity!(NOW)

    assert_equal 0, user.reload.active_week_streak
    assert_equal NOW, user.last_active_at
  end

  test "objecting to usage analytics clears the streak" do
    user = create(:user, active_week_streak: 7)

    user.update!(tracking: false)

    assert_equal 0, user.reload.active_week_streak
  end
end

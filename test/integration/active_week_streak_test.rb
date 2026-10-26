# frozen_string_literal: true

require "test_helper"

class ActiveWeekStreakTest < ActionDispatch::IntegrationTest
  test "a request in a new week counts even right after the last one" do
    monday = Time.zone.local(2026, 10, 19)
    user = create(:user, last_active_at: monday - 5.minutes, active_week_streak: 2)
    sign_in user

    travel_to(monday + 1.minute) { get "/api/v1/users/me", as: :json }

    assert_equal 3, user.reload.active_week_streak
  end

  test "requests within a few minutes of each other write nothing" do
    user = create(:user, last_active_at: 5.minutes.ago, active_week_streak: 2)
    sign_in user

    assert_no_changes -> { user.reload.last_active_at } do
      get "/api/v1/users/me", as: :json
    end
  end
end

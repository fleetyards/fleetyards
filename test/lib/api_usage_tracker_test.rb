# frozen_string_literal: true

require "test_helper"

class ApiUsageTrackerTest < ActiveSupport::TestCase
  setup do
    @application_id = SecureRandom.uuid
    @time = Time.utc(2026, 8, 12, 10, 30)
  end

  teardown do
    ApiUsageTracker.reset(@application_id, @time)
  end

  test "#track counts requests per application and day" do
    3.times { ApiUsageTracker.track(@application_id, time: @time) }

    assert_equal 3, ApiUsageTracker.count(@application_id, @time)
  end

  test "#track buckets by day" do
    ApiUsageTracker.track(@application_id, time: @time)
    other_day = @time + 1.day
    ApiUsageTracker.track(@application_id, time: other_day)

    assert_equal 1, ApiUsageTracker.count(@application_id, @time)
    assert_equal 1, ApiUsageTracker.count(@application_id, other_day)
  ensure
    ApiUsageTracker.reset(@application_id, @time + 1.day)
  end

  test "#track ignores requests without an application" do
    assert_nil ApiUsageTracker.track(nil, time: @time)
  end

  test "#count is zero for an untracked application" do
    assert_equal 0, ApiUsageTracker.count(SecureRandom.uuid, @time)
  end

  test "#reset clears the counter" do
    ApiUsageTracker.track(@application_id, time: @time)
    ApiUsageTracker.reset(@application_id, @time)

    assert_equal 0, ApiUsageTracker.count(@application_id, @time)
  end

  test "#pending_counters finds counters without a matching application" do
    day = 2.days.ago.utc.beginning_of_day
    ApiUsageTracker.track(@application_id, time: day)

    counter = ApiUsageTracker.pending_counters.find { |_day, id, _requests| id == @application_id }

    assert_not_nil counter
    assert_equal day.to_date, counter.first.to_date
    assert_equal 1, counter.last
  ensure
    ApiUsageTracker.reset(@application_id, 2.days.ago)
  end

  test "#pending_counters ignores counters of the running day" do
    ApiUsageTracker.track(@application_id)

    assert_empty ApiUsageTracker.pending_counters.select { |_day, id, _requests| id == @application_id }
  ensure
    ApiUsageTracker.reset(@application_id, Time.current)
  end

  test "#pending_days excludes today and covers the retention window" do
    now = Time.utc(2026, 8, 13, 1, 0)
    days = ApiUsageTracker.pending_days(now:).map(&:to_date)

    assert_not_includes days, now.to_date
    assert_equal Date.new(2026, 8, 12), days.first
    assert_equal ApiUsageTracker::RETENTION.in_days.to_i, days.size
  end
end

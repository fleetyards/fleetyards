# frozen_string_literal: true

require "test_helper"

class MetricsJobTest < ActiveJob::TestCase
  test "#perform generates rollup metrics without errors" do
    assert_nothing_raised do
      MetricsJob.new.perform
    end
  end

  test "#perform rolls up api usage counters per application" do
    application = create(:oauth_application)
    day = 1.day.ago.utc.beginning_of_day
    2.times { ApiUsageTracker.track(application.id, time: day) }

    MetricsJob.new.perform

    rollup = Rollup.find_by(name: ApiUsageTracker::ROLLUP_NAME, interval: "day")

    assert_not_nil rollup
    assert_equal 2, rollup.value
    assert_equal application.name, rollup.dimensions["application"]
    assert_equal application.id, rollup.dimensions["application_id"]
  end

  test "#perform rolls up usage of applications deleted since their requests" do
    application = create(:oauth_application)
    application_id = application.id
    day = 1.day.ago.utc.beginning_of_day
    ApiUsageTracker.track(application_id, time: day)
    application.destroy!

    MetricsJob.new.perform

    rollup = Rollup.find_by(name: ApiUsageTracker::ROLLUP_NAME, interval: "day")

    assert_not_nil rollup
    assert_equal 1, rollup.value
    assert_equal application_id, rollup.dimensions["application_id"]
  end

  test "#perform clears counters it has rolled up" do
    application = create(:oauth_application)
    day = 1.day.ago.utc.beginning_of_day
    ApiUsageTracker.track(application.id, time: day)

    MetricsJob.new.perform

    assert_equal 0, ApiUsageTracker.count(application.id, day)
  end

  test "#perform skips applications without usage" do
    create(:oauth_application)

    MetricsJob.new.perform

    assert_not Rollup.exists?(name: ApiUsageTracker::ROLLUP_NAME)
  end
end

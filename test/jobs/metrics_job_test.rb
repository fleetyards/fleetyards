# frozen_string_literal: true

require "test_helper"

class MetricsJobTest < ActiveJob::TestCase
  test "#perform generates rollup metrics without errors" do
    assert_nothing_raised do
      MetricsJob.new.perform
    end
  end
end

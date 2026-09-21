# frozen_string_literal: true

require "test_helper"

class AdminWeeklyReportTest < ActiveSupport::TestCase
  def gauge(report, section_key, metric_key)
    section = report[:sections].find { |item| item.key == section_key }

    section.metrics.find { |metric| metric.key == metric_key }
  end

  test "counts a pledge-store ship with no price as missing one" do
    create(:model, pledge_price: nil)

    assert_equal 1, gauge(AdminWeeklyReport.build, :content, :models_without_price).current
  end

  # An in-game-only ship has no pledge price and never will, so it is not a gap
  # in the curation backlog.
  test "leaves an in-game-only ship out of the missing-price count" do
    create(:model, pledge_price: nil, ingame_only: true)

    assert_equal 0, gauge(AdminWeeklyReport.build, :content, :models_without_price).current
  end
end

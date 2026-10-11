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

  # A failed run has no outcome and is still a sync someone tried, which is what
  # `failed_hangar_syncs` is read against.
  test "counts hangar syncs but not runs that had nothing to do" do
    user = create(:user)
    create(:import, :hangar_sync, user:, aasm_state: "finished", output: {"outcome" => "synced"})
    create(:import, :hangar_sync, user:, aasm_state: "failed")
    HangarSync::NO_OP_OUTCOMES.each do |outcome|
      create(:import, :hangar_sync, user:, aasm_state: "finished", output: {"outcome" => outcome})
    end

    assert_equal 2, gauge(AdminWeeklyReport.build, :ops, :hangar_syncs).current
  end
end

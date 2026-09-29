# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260929120000_rebuild_ship_views_per_visit.rb")

class RebuildShipViewsPerVisitTest < ActiveSupport::TestCase
  test "a retained day counted per view is rebuilt per visit" do
    day = 10.days.ago.to_date
    store_ship_views(day, 3)
    visit = Ahoy::Visit.create!(visit_token: SecureRandom.hex, visitor_token: SecureRandom.hex, started_at: day.noon)
    ["/ships/aurora-mr/", "/ships/aurora-mr/images/", "/ships/aurora-mr/videos/"].each do |page|
      Ahoy::Event.create!(visit:, name: "$view", properties: {"page" => page}, time: day.noon)
    end

    RebuildShipViewsPerVisit.new.up

    assert_equal 1, ship_views_on(day)
  end

  test "a day past the cleanup cutoff keeps its stored count" do
    day = 40.days.ago.to_date
    store_ship_views(day, 3)

    RebuildShipViewsPerVisit.new.up

    assert_equal 3, ship_views_on(day)
  end

  private def store_ship_views(day, value)
    Rollup.create!(name: MetricsJob::ROLLUP_SHIP_VIEWS, interval: "day", time: day,
      dimensions: {model_slug: "aurora-mr"}, value:)
  end

  # The gem stores a day at midnight UTC, and a date assigned here lands at
  # midnight in the app's zone, so the whole local day is searched for either.
  private def ship_views_on(day)
    Rollup.where(name: MetricsJob::ROLLUP_SHIP_VIEWS, interval: "day", time: day.all_day).sum(:value)
  end
end

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

  test "#perform rolls up ship page views per slug" do
    track_ship_view("/ships/aurora-mr/")
    track_ship_view("/ships/aurora-mr/")
    track_ship_view("/ships/cutlass-black/")

    MetricsJob.new.perform

    assert_equal 2, ship_views("aurora-mr")
    assert_equal 1, ship_views("cutlass-black")
  end

  test "#perform counts a ship's sub-pages towards the ship" do
    track_ship_view("/ships/aurora-mr/")
    track_ship_view("/ships/aurora-mr/images/")

    MetricsJob.new.perform

    assert_equal 2, ship_views("aurora-mr")
  end

  test "#perform ignores the ship index, which names no ship" do
    track_ship_view("/ships/")

    MetricsJob.new.perform

    assert_equal 0, Rollup.where(name: MetricsJob::ROLLUP_SHIP_VIEWS).count
  end

  # Ahoy refuses to record an objecting user from the moment they object, so
  # what is left to exclude here are the rows written before that.
  test "#perform leaves out views by a user who objected to tracking" do
    objector = create(:user, tracking: false)
    track_ship_view("/ships/aurora-mr/", user: objector)
    track_ship_view("/ships/aurora-mr/")

    MetricsJob.new.perform

    assert_equal 1, ship_views("aurora-mr")
  end

  private def track_ship_view(page, user: nil, at: 1.day.ago)
    visit = Ahoy::Visit.create!(
      visit_token: SecureRandom.hex,
      visitor_token: SecureRandom.hex,
      started_at: at,
      user_id: user&.id
    )

    Ahoy::Event.create!(
      visit: visit,
      user_id: user&.id,
      name: "$view",
      properties: {"page" => page},
      time: at
    )
  end

  private def ship_views(slug)
    Rollup.where(
      name: MetricsJob::ROLLUP_SHIP_VIEWS,
      interval: "day",
      dimensions: {model_slug: slug}
    ).sum(:value)
  end

  test "#perform rolls up wishlist additions per model" do
    wanted = create(:model)
    other = create(:model)
    create_list(:vehicle, 2, model: wanted, wanted: true, loaner: false)
    create(:vehicle, model: other, wanted: true, loaner: false)

    MetricsJob.new.perform

    assert_equal 2, wishlist_additions(wanted)
    assert_equal 1, wishlist_additions(other)
  end

  test "#perform leaves purchased ships out of the wishlist rollup" do
    model = create(:model)
    create(:vehicle, model:, wanted: true, loaner: false)
    create(:vehicle, model:, wanted: false, loaner: false)

    MetricsJob.new.perform

    assert_equal 1, wishlist_additions(model)
  end

  # The dimensionless series is twelve years of history and nothing else writes
  # it, so the per-model rollup has to sit beside it rather than replace it.
  test "#perform keeps the plain wishlist series" do
    model = create(:model)
    create(:vehicle, model:, wanted: true, loaner: false)

    MetricsJob.new.perform

    assert_operator Rollup.where(name: "Vehicle Wish", interval: "month").count, :>, 0
  end

  private def wishlist_additions(model)
    Rollup.where(
      name: MetricsJob::ROLLUP_WISHLIST_BY_MODEL,
      interval: "month",
      dimensions: {model_id: model.id}
    ).sum(:value)
  end
end

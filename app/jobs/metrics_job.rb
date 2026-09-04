# frozen_string_literal: true

class MetricsJob < ApplicationJob
  # A `$view` event records the path it happened on, so the ship is the third
  # segment of `/ships/<slug>/`. Sub-pages (`images/`, `videos/`) resolve to the
  # same slug and count towards the ship, which is what interest in it looks
  # like.
  SHIP_VIEW_SLUG = Arel.sql("split_part(ahoy_events.properties->>'page', '/', 3)")

  ROLLUP_SHIP_VIEWS = "Ship Views"

  # Its own name rather than a dimension on `Vehicle Wish`: the same name and
  # interval would then hold both a total row and one row per model, and reading
  # the plain series back would have to know to ask for the empty dimensions.
  ROLLUP_WISHLIST_BY_MODEL = "Vehicle Wish by Model"

  def perform
    User.rollup("Registrations", interval: "month")
    User.rollup("Registrations", interval: "year")
    User.rollup("Activity", interval: "year", column: :last_active_at)
    User.rollup("Activity", interval: "month", column: :last_active_at)
    User.rollup("Activity", interval: "week", column: :last_active_at)
    Model.visible.active.rollup("Models", interval: "month")
    Model.visible.active.rollup("Models", interval: "year")
    Fleet.rollup("Fleet", interval: "month")
    Fleet.rollup("Fleet", interval: "year")
    Vehicle.visible.purchased.where(loaner: false).rollup("Vehicle", interval: "year")
    Vehicle.visible.purchased.where(loaner: false).rollup("Vehicle", interval: "month")
    Vehicle.visible.wanted.where(loaner: false).rollup("Vehicle Wish", interval: "year")
    Vehicle.visible.wanted.where(loaner: false).rollup("Vehicle Wish", interval: "month")

    track_ship_views
    track_wishlist_by_model
    track_ship_of_the_month
    track_api_usage
  end

  private

  # Ahoy keeps visits for a month (`Cleanup::VisitsJob`) and rolls up nothing but
  # a monthly total, so per-ship views are gone before anything can read them.
  # The interval is deliberately `day`: the gem recomputes from the newest stored
  # interval onward, so a monthly rollup would recompute a half-purged month down
  # to a wrong number, while a day is always complete by the time it is purged.
  def track_ship_views
    scope = Ahoy::Event
      .where(name: "$view")
      .where("ahoy_events.properties->>'page' LIKE ?", "/ships/_%")

    # `Ahoy.exclude_method` already refuses to record an objecting user, so this
    # only covers rows written before they objected. `NOT IN` alone would drop
    # every anonymous view along with them, since `NULL NOT IN (...)` is NULL.
    blocked_user_ids = User.where(tracking: false).pluck(:id)
    if blocked_user_ids.any?
      scope = scope.where(
        "ahoy_events.user_id IS NULL OR ahoy_events.user_id NOT IN (?)",
        blocked_user_ids
      )
    end

    scope.group(SHIP_VIEW_SLUG).rollup(
      ROLLUP_SHIP_VIEWS,
      interval: "day",
      column: :time,
      # The gem derives a dimension name from the grouped column and only accepts
      # a bare word, which an expression is not.
      dimension_names: ["model_slug"]
    )
  end

  # Which ship the wishlist grew by, which the dimensionless `Vehicle Wish`
  # rollup beside it cannot say.
  #
  # This counts `created_at`, so it measures wishlist *additions* in a month
  # rather than how many people want the ship in total. A ship whose demand is
  # steady and high shows a flat line, not a rising one.
  def track_wishlist_by_model
    Vehicle.visible.wanted.where(loaner: false)
      .group(:model_id)
      .rollup(ROLLUP_WISHLIST_BY_MODEL, interval: "month")
  end

  # Rolls up every day still held in Redis, not just yesterday, so a failed run
  # does not drop a day of counters.
  def track_api_usage
    names = Oauth::Application.pluck(:id, :name).to_h

    ApiUsageTracker.pending_counters.each do |day, application_id, count|
      dimensions = {application_id:, application: names[application_id]}.compact

      Rollup.where(name: ApiUsageTracker::ROLLUP_NAME, interval: "day", time: day, dimensions:).delete_all
      Rollup.create!(
        name: ApiUsageTracker::ROLLUP_NAME,
        interval: "day",
        time: day,
        value: count,
        dimensions:
      )

      ApiUsageTracker.reset(application_id, day)
    end
  end

  ROLLUP_SHIP_OF_THE_PERIOD = "Ship of the Month"

  def track_ship_of_the_month
    track_most_hangared(Time.current.beginning_of_month, interval: "month")
    track_most_hangared(Time.current.beginning_of_year, interval: "year")
  end

  # The ship that entered the most hangars since `from`. Written under one name
  # at two intervals rather than two names: the reader tells them apart by the
  # interval it asks for, the way every other rollup here does.
  def track_most_hangared(from, interval:)
    ship = Vehicle.visible
      .where(loaner: false, wanted: false)
      .where(created_at: from..)
      .joins(:model)
      .group("models.name")
      .order(Arel.sql("count(*) DESC"))
      .limit(1)
      .count
      .first

    return unless ship

    Rollup.where(name: ROLLUP_SHIP_OF_THE_PERIOD, interval:, time: from).delete_all
    Rollup.create!(
      name: ROLLUP_SHIP_OF_THE_PERIOD,
      interval:,
      time: from,
      value: ship.last,
      dimensions: {name: ship.first}
    )
  end
end

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

  # Visits per OS, split by whether they ran as the installed app, so the share
  # of installed use per platform can be read back after the visits are purged.
  ROLLUP_VISITS_BY_OS = "Visits by OS"

  # Page views per device, OS and install state, which says which pages get used
  # on a phone and from the installed app once the events behind it are purged.
  ROLLUP_VIEWS_BY_DEVICE = "Views by device"

  # A visit's installed flag can only change while the visit lasts, so a day is
  # settled well within this.
  VISIT_RECOMPUTE = 2.days

  # The oldest day whose visits and events are all still there.
  def self.cleanup_floor
    (Cleanup::VisitsJob::RETENTION.ago + 1.day).to_date
  end

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
    track_views_by_device
    track_visits
    track_wishlist_by_model
    track_ship_of_the_month
    track_api_usage
  end

  # Ahoy keeps visits for a month (`Cleanup::VisitsJob`) and rolls up nothing but
  # a monthly total, so per-ship views are gone before anything can read them.
  # A ship counts once per visit: every tab on a ship page is a view of its own,
  # so counting views would rank ships by how many tabs people click through.
  # Public so every retained day can be rebuilt (`since:` the cleanup cutoff)
  # without running the other rollups, which consume counters as they go.
  def track_ship_views(since: nil)
    scope = page_views.where("ahoy_events.properties->>'page' LIKE ?", "/ships/_%")

    rebuild_recent_days(ROLLUP_SHIP_VIEWS, since:) do |range|
      scope.group(SHIP_VIEW_SLUG).rollup(
        ROLLUP_SHIP_VIEWS,
        interval: "day",
        column: :time,
        range:,
        # The gem derives a dimension name from the grouped column and only
        # accepts a bare word, which an expression is not.
        dimension_names: ["model_slug"]
      ) { |views| views.distinct.count(:visit_id) }
    end
  end

  private

  # `Cleanup::VisitsJob` writes the monthly total under the same name, but it
  # runs once a month, which no per-day chart can be built on. The day interval
  # is the only safe one here: the gem recomputes from the newest stored interval
  # onward, so a monthly rollup would recompute a half-purged month down to a
  # wrong number, while a day is always complete by the time it is purged.
  def track_visits
    visits = Ahoy::Visit.without_users(User.where(tracking: false).pluck(:id))

    visits.rollup("Visits", interval: "day", column: :started_at)
    track_visits_by_os(visits)
  end

  # A NULL flag is a visit from before it was recorded, not a browser visit.
  def track_visits_by_os(visits)
    rebuild_recent_days(ROLLUP_VISITS_BY_OS) do |range|
      visits.where.not(installed: nil).group(:os, :installed)
        .rollup(ROLLUP_VISITS_BY_OS, interval: "day", column: :started_at, range:)
    end
  end

  # The gem only upserts the groups it finds, so a visit flagged installed after
  # its day was rolled up would leave its old `installed: false` row behind. The
  # recent days are therefore cleared and rebuilt as a window rather than left to
  # the gem's own resume point. The window never reaches past the cleanup cutoff:
  # every visit newer than that is always still there, and an older day may be
  # partly purged, so its stored counts are all that is left.
  def rebuild_recent_days(name, since: nil)
    stored = Rollup.where(name:, interval: "day")
    latest = stored.maximum(:time)&.to_date
    start = [self.class.cleanup_floor, since || [latest, VISIT_RECOMPUTE.ago.to_date].compact.min].max
    range = start.in_time_zone(Rollup.time_zone)..Time.current

    Rollup.transaction do
      # By day, not by `range`: a day is stored at its midnight UTC, which for the
      # current day is still ahead of `Time.current` until UTC catches up.
      stored.where(time: start..).delete_all

      yield range
    end
  end

  # A view is counted under the visit's install state, which a later view of the
  # same visit can still flip, so its days are rebuilt like `Visits by OS`.
  def track_views_by_device
    rebuild_recent_days(ROLLUP_VIEWS_BY_DEVICE) do |range|
      page_views.joins(:visit)
        .where.not(ahoy_visits: {installed: nil})
        .group("ahoy_visits.device_type", "ahoy_visits.os", "ahoy_visits.installed")
        .rollup(
          ROLLUP_VIEWS_BY_DEVICE,
          interval: "day",
          column: "ahoy_events.time",
          range:,
          dimension_names: ["device_type", "os", "installed"]
        )
    end
  end

  # `Ahoy.exclude_method` already refuses to record an objecting user, so this
  # only covers rows written before they objected. `NOT IN` alone would drop
  # every anonymous view along with them, since `NULL NOT IN (...)` is NULL.
  def page_views
    scope = Ahoy::Event.where(name: "$view")

    blocked_user_ids = User.where(tracking: false).pluck(:id)
    return scope if blocked_user_ids.empty?

    scope.where(
      "ahoy_events.user_id IS NULL OR ahoy_events.user_id NOT IN (?)",
      blocked_user_ids
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

# frozen_string_literal: true

module TrackingStatsConcern
  ONLINE_WINDOW = 15.minutes

  # Signed-in clients are counted through `users.last_active_at`, which every API
  # client updates, while Ahoy only sees the web frontend. Anonymous visits still
  # have to come from Ahoy, and they cannot overlap with the user count because a
  # visit with a `user_id` is excluded.
  private def online_count
    active_users_count + anonymous_visits_count
  end

  private def active_users_count
    User.where.not(tracking: false).where(last_active_at: ONLINE_WINDOW.ago..).count
  end

  private def anonymous_visits_count
    Ahoy::Event.joins(:visit)
      .where(ahoy_visits: {user_id: nil})
      .where(time: ONLINE_WINDOW.ago..)
      .distinct.count(:visit_id)
  end

  private def tracking_blocklist
    @tracking_blocklist ||= User.where(tracking: false).pluck(:id)
  end
end

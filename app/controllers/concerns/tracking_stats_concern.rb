# frozen_string_literal: true

module TrackingStatsConcern
  ONLINE_WINDOW = 15.minutes

  # Short, because this is the one figure on the dashboard that is meant to read
  # as now. It still collapses the 30-second poll, and the several admins who
  # may have the page open, down to one pair of queries a minute.
  ONLINE_COUNT_TTL = 1.minute

  # Signed-in clients are counted from the presence set, which is exact for
  # anything holding a socket rather than the 15-minute proxy `last_active_at`
  # was. Two consequences worth knowing: the figure is lower than it used to be,
  # and OAuth/API clients no longer appear in it at all — they hold no socket.
  #
  # Anonymous visits still have to come from Ahoy, and they cannot overlap with
  # the user count because a visit with a `user_id` is excluded.
  private def online_count
    Rails.cache.fetch("stats/online_count", expires_in: ONLINE_COUNT_TTL) do
      active_users_count + anonymous_visits_count
    end
  end

  # `tracking: false` still takes a user out of the figure, which is the one
  # thing that switch has always done here.
  private def active_users_count
    online_ids = UserPresence.online_user_ids
    return 0 if online_ids.empty?

    User.where(id: online_ids).where.not(tracking: false).count
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

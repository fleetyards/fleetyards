# frozen_string_literal: true

# Visits are only kept for a month, so a streak can be started from those
# weeks rather than from zero. A streak that reaches back past the oldest
# retained visit is counted from there, which is the most that is still known.
#
# It ends at the week of `last_active_at`, as a live streak does: a visit in a
# later week would otherwise be counted here and again on the next request.
class SeedActiveWeekStreaks < ActiveRecord::Migration[8.1]
  VISIT_DAY = Arel.sql("DISTINCT ahoy_visits.user_id, (ahoy_visits.started_at AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.name}')::date")

  def up
    current_week = Time.current.beginning_of_week
    tracked_users = User.where(tracking: [true, nil])

    last_weeks = tracked_users.where(last_active_at: (current_week - 1.week)..).pluck(:id, :last_active_at)
      .to_h { |user_id, last_active_at| [user_id, last_active_at.in_time_zone.beginning_of_week] }

    weeks_by_user = Hash.new { |hash, user_id| hash[user_id] = Set.new }
    Ahoy::Visit.where(user_id: last_weeks.keys).where.not(started_at: nil).pluck(VISIT_DAY).each do |user_id, day|
      weeks_by_user[user_id] << day.in_time_zone.beginning_of_week
    end

    user_ids_by_streak = Hash.new { |hash, streak| hash[streak] = [] }
    last_weeks.each do |user_id, last_week|
      weeks = weeks_by_user[user_id] << last_week
      week = last_week
      streak = 0
      while weeks.include?(week)
        streak += 1
        week -= 1.week
      end

      user_ids_by_streak[streak] << user_id
    end

    user_ids_by_streak.each do |streak, user_ids|
      User.where(id: user_ids).update_all(active_week_streak: streak)
    end
  end

  def down
    User.update_all(active_week_streak: 0)
  end
end

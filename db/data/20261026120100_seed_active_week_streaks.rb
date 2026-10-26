# frozen_string_literal: true

# Visits are only kept for a month, so a streak can be started from those
# weeks rather than from zero. A streak that reaches back past the oldest
# retained visit is counted from there, which is the most that is still known.
class SeedActiveWeekStreaks < ActiveRecord::Migration[8.1]
  def up
    current_week = Time.current.beginning_of_week
    weeks_by_user = Hash.new { |hash, user_id| hash[user_id] = Set.new }

    tracked_users = User.where(tracking: true)

    Ahoy::Visit.where(user_id: tracked_users.select(:id)).pluck(:user_id, :started_at).each do |user_id, started_at|
      weeks_by_user[user_id] << started_at.in_time_zone.beginning_of_week
    end

    tracked_users.where(last_active_at: (current_week - 1.week)..).pluck(:id, :last_active_at).each do |user_id, last_active_at|
      weeks_by_user[user_id] << last_active_at.in_time_zone.beginning_of_week
    end

    user_ids_by_streak = weeks_by_user.each_with_object(Hash.new { |hash, streak| hash[streak] = [] }) do |(user_id, weeks), result|
      week = weeks.max
      next if week < current_week - 1.week

      streak = 0
      while weeks.include?(week)
        streak += 1
        week -= 1.week
      end

      result[streak] << user_id
    end

    user_ids_by_streak.each do |streak, user_ids|
      User.where(id: user_ids).update_all(active_week_streak: streak)
    end
  end

  def down
    User.update_all(active_week_streak: 0)
  end
end

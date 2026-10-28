# frozen_string_literal: true

module Raffles
  # Tells every user when a raffle opens, and those who have not entered when
  # it has a day left. Each kind goes out once per raffle: the timestamp is
  # set before anything is sent, so an overlapping run finds nothing to do.
  class AnnounceJob < ::ApplicationJob
    sidekiq_options retry: false, queue: "notifications"

    BATCH_SIZE = 1_000

    def perform
      now = Time.current

      Raffle.start_unannounced(now).find_each do |raffle|
        next unless claim(raffle, :start_announced_at, now)

        fan_out(raffle, :raffle_started, User.confirmed.pluck(:id))
        Raffles::PostSocialJob.perform_async(raffle.id)
      end

      Raffle.last_day_unannounced(now).find_each do |raffle|
        next unless claim(raffle, :last_day_announced_at, now)

        entered = raffle.entries.where.not(user_id: nil).select(:user_id)
        fan_out(raffle, :raffle_last_day, User.confirmed.where.not(id: entered).pluck(:id))
      end
    end

    private def claim(raffle, column, now)
      Raffle.where(:id => raffle.id, column => nil).update_all(column => now, :updated_at => now) == 1
    end

    private def fan_out(raffle, type, user_ids)
      user_ids.each_slice(BATCH_SIZE) do |batch|
        Raffles::AnnounceBatchJob.perform_async(raffle.id, type.to_s, batch)
      end
    end
  end
end

# frozen_string_literal: true

require "discord/weekly_digest"

module Discord
  class PostWeeklyDigestJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    def perform(fleet_id)
      fleet = Fleet.find_by(id: fleet_id)
      return if fleet.blank?

      WeeklyDigest.new(fleet).run
    end
  end
end

# frozen_string_literal: true

require "discord/announcement_target"

module Discord
  class DeliverAnnouncementJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    # Positional on purpose: Sidekiq replays arguments positionally.
    def perform(fleet_id, kind, channel_id, content)
      fleet = Fleet.find_by(id: fleet_id)
      return if fleet.blank?

      AnnouncementTarget.new(kind, channel_id).deliver(fleet, content)
    end
  end
end

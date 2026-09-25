# frozen_string_literal: true

require "discord/event_published"

module Discord
  class AnnounceEventPublishedJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    def perform(event_id)
      event = FleetEvent.find_by(id: event_id)
      return if event.blank?
      return if event.archived_at.present?
      # Narrowed while still a draft: nothing is published to announce.
      return if event.draft?
      # Published and cancelled again before the job ran: announcing it now
      # would send people to an event that is not happening.
      return if event.cancelled?

      message = EventPublished.new(event: event)
      return unless message.upcoming?

      message.run
    end
  end
end

# frozen_string_literal: true

require "discord/announcement_target"
require "discord/join_request_message"

module Discord
  # Posts a new join request to the officers' channel, with the buttons that
  # answer it. Only a message the bot sent can carry buttons, so a fleet
  # that reaches Discord through a webhook alone gets no such post.
  class PostJoinRequestJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    def perform(membership_id)
      membership = FleetMembership.kept.includes(:user, :fleet).find_by(id: membership_id)
      return if membership.blank? || membership.fleet.blank? || membership.fleet.discarded?
      # Answered on the website while this waited in the queue.
      return unless membership.requested?

      payload = JoinRequestMessage.new(membership).pending_payload
      AnnouncementTarget.officers.deliver(membership.fleet, payload[:content], components: payload[:components])
    end
  end
end

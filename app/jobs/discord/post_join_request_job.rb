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
      message = AnnouncementTarget.officers.deliver(membership.fleet, payload[:content], components: payload[:components])
      return unless message.is_a?(Hash) && message["id"].present?

      # Not a save: nothing about the membership changed, so neither its
      # callbacks nor its version history have anything to do with this.
      membership.update_columns(
        discord_request_channel_id: message["channel_id"],
        discord_request_message_id: message["id"]
      )

      # Answered or withdrawn while the post was on its way, the request found
      # no message to update when it closed.
      unless FleetMembership.kept.exists?(id: membership.id, aasm_state: "requested")
        RefreshJoinRequestMessageJob.perform_async(membership.id)
      end
    end
  end
end

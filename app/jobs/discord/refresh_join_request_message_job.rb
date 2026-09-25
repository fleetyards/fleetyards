# frozen_string_literal: true

require "discord/api_client"
require "discord/channel_post"
require "discord/join_request_message"

module Discord
  # Brings a join request's message in the officers' channel up to date once
  # the request is no longer pending, however that happened: answered on the
  # website, by slash command or by button, withdrawn by the applicant, or
  # removed. Otherwise the message would keep offering buttons for a request
  # that is already settled.
  class RefreshJoinRequestMessageJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    # The ids are passed along for a membership that has been destroyed; for
    # one that still exists, its own columns are read, since the post may
    # have landed after the caller loaded it.
    def perform(membership_id, channel_id = nil, message_id = nil)
      return unless ApiClient.configured?

      membership = FleetMembership.includes(:user, :fleet).find_by(id: membership_id)
      channel_id = membership&.discord_request_channel_id.presence || channel_id
      message_id = membership&.discord_request_message_id.presence || message_id
      return if channel_id.blank? || message_id.blank?
      return if membership&.kept? && membership.requested?

      payload = membership ? JoinRequestMessage.new(membership).settled_payload : JoinRequestMessage.closed_payload(membership_id)
      ApiClient.new.edit_message(channel_id, message_id, payload)
    rescue ApiClient::Error => e
      # The message or its channel was deleted, or the bot lost access to it.
      raise unless ChannelPost::UNDELIVERABLE_STATUSES.include?(e.status)

      Rails.logger.warn("[Discord::RefreshJoinRequestMessageJob] membership=#{membership_id} not updated: #{e.status}")
    end
  end
end

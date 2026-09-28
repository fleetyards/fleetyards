# frozen_string_literal: true

require "discord/api_client"

module Discord
  # Reaction counts for the messages an announcement was posted as. Reactions
  # are all Discord has: it exposes no views and no share counts.
  #
  # Read through the bot rather than the webhook that posted them, so the bot
  # has to be able to see the updates channel.
  class Engagement
    def self.configured?
      ::Discord::ApiClient.configured?
    end

    def initialize(client: ::Discord::ApiClient.new)
      @client = client
    end

    # Parts are the delivery's `posted_parts`. Those posted before the webhook
    # waited for its message carry no id and are left out; nil when none do.
    def fetch(parts, guild_id: nil)
      messages = parts.select { |part| part["message_id"].present? && part["channel_id"].present? }
      return nil if messages.empty?

      first = messages.first

      {
        "reactions" => reactions(messages),
        "guild_id" => guild_id.presence || @client.get_channel(first["channel_id"])&.dig("guild_id")
      }.compact
    end

    # One entry per emoji, whichever message it was left on. A custom emoji is
    # keyed on its id, because two servers can each have a `:party:`.
    private def reactions(messages)
      merged = {}

      messages.each do |part|
        message = @client.get_channel_message(part["channel_id"], part["message_id"])

        Array(message&.dig("reactions")).each do |reaction|
          emoji = reaction["emoji"] || {}
          key = emoji["id"].presence || emoji["name"]
          next if key.blank?

          merged[key] ||= {"emoji" => emoji["name"], "id" => emoji["id"], "count" => 0}.compact
          merged[key]["count"] += reaction["count"].to_i
        end
      end

      merged.values.sort_by { |reaction| -reaction["count"] }
    end
  end
end

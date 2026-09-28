# frozen_string_literal: true

require "discord/api_client"

module Discord
  # Reaction counts for the messages an announcement was posted as. Reactions
  # are all Discord has: it exposes no views and no share counts.
  #
  # Read through the bot rather than the webhook that posted them, so the bot
  # needs View Channel and Read Message History on the updates channel --
  # without the second, every read is a 403.
  class Engagement
    def self.configured?
      ::Discord::ApiClient.configured?
    end

    # What a part needs before its reactions can be read back.
    def self.readable?(part)
      part["message_id"].present? && part["channel_id"].present?
    end

    def initialize(client: ::Discord::ApiClient.new)
      @client = client
    end

    # Parts are the delivery's `posted_parts`. Those posted before the webhook
    # waited for its message carry no id and are left out; nil when none do.
    def fetch(parts, guild_id: nil)
      messages = parts.select { |part| self.class.readable?(part) }
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
        message = read(part)

        Array(message&.dig("reactions")).each do |reaction|
          emoji = reaction["emoji"] || {}
          key = emoji["id"].presence || emoji["name"]
          # A custom emoji deleted from its server comes back without a name,
          # and there is nothing left to show it as.
          next if key.blank? || emoji["name"].blank?

          merged[key] ||= {"emoji" => emoji["name"], "id" => emoji["id"], "count" => 0}.compact
          merged[key]["count"] += reaction["count"].to_i
        end
      end

      merged.values.sort_by { |reaction| -reaction["count"] }
    end

    # A message a moderator deleted is gone for good. Skipping it keeps the
    # rest of the announcement's reactions current rather than failing every
    # refresh for the next thirty days.
    private def read(part)
      @client.get_channel_message(part["channel_id"], part["message_id"])
    rescue ::Discord::ApiClient::Error => e
      raise unless e.status == 404

      nil
    end
  end
end

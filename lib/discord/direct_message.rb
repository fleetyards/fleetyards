# frozen_string_literal: true

module Discord
  # Delivers a Notification to its reader as a Discord DM.
  #
  # This is what makes the Discord account link worth something to a *member*
  # rather than to an org: the sale alert for a ship on their own wishlist
  # arrives where they already are.
  #
  # Requirements Discord imposes and this cannot work around:
  #
  # - The recipient must share a server with the bot. Nothing in the API says
  #   whether they do until the send fails.
  # - The recipient must not have DMs from server members closed.
  #
  # Both produce a **403**, which is a normal outcome here, not an error to
  # retry into a rate limit: the reader's Discord privacy settings are not
  # something a retry changes.
  class DirectMessage
    # Discord's own colour-free default; the embed is deliberately plain so a DM
    # does not look like an advert.
    EMBED_COLOR = 0x2d9cdb

    def initialize(notification)
      @notification = notification
    end

    def self.deliverable?(user)
      ApiClient.configured? && discord_uid_for(user).present?
    end

    def self.discord_uid_for(user)
      user&.omniauth_connections&.find_by(provider: "discord")&.uid
    end

    def run
      uid = self.class.discord_uid_for(@notification.user)
      return false if uid.blank?
      return false unless ApiClient.configured?

      channel = api.create_dm_channel(uid)
      channel_id = channel&.dig("id")
      return false if channel_id.blank?

      api.create_message(channel_id, payload)
      true
    rescue ApiClient::Error => e
      # 403: cannot DM this reader. 404: the account was deleted or unlinked
      # between the notification and the send. Neither is worth a retry.
      raise unless [403, 404].include?(e.status)

      Rails.logger.info(
        "[Discord::DirectMessage] notification=#{@notification.id} not delivered: #{e.status}"
      )
      false
    end

    private def payload
      {embeds: [embed]}
    end

    private def embed
      {
        title: @notification.title,
        description: @notification.body.presence,
        url: link,
        color: EMBED_COLOR,
        footer: {text: I18n.t("discord.direct_message.footer")}
      }.compact_blank
    end

    # Notification#link is a path, and a DM has no site around it to resolve
    # one against.
    private def link
      path = @notification.link.presence
      return nil if path.blank?
      return path if path.start_with?("http")

      "https://#{Rails.configuration.app.domain}#{path}"
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end

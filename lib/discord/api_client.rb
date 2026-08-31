# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module Discord
  # Thin wrapper around Discord's REST API for bot-token operations.
  # Used for guild scheduled events; the existing Discord::Webhook stays
  # for one-shot announcement posts via webhook URLs.
  class ApiClient
    # Trailing slash is required so Faraday treats subsequent relative
    # paths (e.g. "guilds/123") as joins, not absolute replacements.
    BASE_URL = "https://discord.com/api/v10/"

    class Error < StandardError
      attr_reader :status, :body

      def initialize(status, body)
        @status = status
        @body = body
        super("Discord API error #{status}: #{body}")
      end
    end

    def self.bot_token
      Rails.application.config.app.discord[:bot_token].presence
    end

    # The Discord application's ID — same value as the OAuth login client_id,
    # used here to build the bot install URL on the fleet settings page.
    def self.application_id
      Rails.application.config.app.discord[:client_id].presence
    end

    # Manage Events (1 << 33), View Channel (1 << 10), Connect (1 << 20) and
    # Manage Roles (1 << 28).
    #
    # Discord rejects a voice-channel scheduled event without View Channel and
    # Connect when a fleet sets a discord_channel_id, and role assignment needs
    # Manage Roles. Must stay in sync with the app's Default Install Settings in
    # the Discord dev portal.
    #
    # Raising this does NOT upgrade servers that installed under the old mask --
    # Discord keeps their original grant. Discord::RoleCapability is what tells
    # a fleet it has to re-authorise.
    INSTALL_PERMISSIONS = 8_859_419_648

    def self.install_url
      return nil if application_id.blank?

      "https://discord.com/oauth2/authorize" \
        "?client_id=#{application_id}" \
        "&permissions=#{INSTALL_PERMISSIONS}" \
        "&integration_type=0" \
        "&scope=bot+applications.commands"
    end

    def self.configured?
      bot_token.present?
    end

    def initialize(token: self.class.bot_token)
      @token = token
    end

    def get_guild(guild_id)
      request(:get, "guilds/#{guild_id}")
    end

    # A full replacement of the application's global command list, which is
    # what makes `discord:commands:sync` idempotent: whatever the registry does
    # not list stops existing. Rate-limited per day, so it belongs in a task
    # rather than in a deploy hook.
    def put_application_commands(application_id, definitions)
      request(:put, "applications/#{application_id}/commands", definitions)
    end

    def create_guild_scheduled_event(guild_id, payload)
      post("guilds/#{guild_id}/scheduled-events", payload)
    end

    # Opens (or returns the existing) DM channel with one user. Discord treats
    # this as idempotent, so there is nothing to cache.
    def create_dm_channel(recipient_id)
      post("users/@me/channels", {recipient_id: recipient_id})
    end

    def create_message(channel_id, payload)
      post("channels/#{channel_id}/messages", payload)
    end

    def get_guild_roles(guild_id)
      request(:get, "guilds/#{guild_id}/roles")
    end

    def get_guild_member(guild_id, user_id)
      request(:get, "guilds/#{guild_id}/members/#{user_id}")
    end

    def add_guild_member_role(guild_id, user_id, role_id)
      request(:put, "guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}")
    end

    def remove_guild_member_role(guild_id, user_id, role_id)
      request(:delete, "guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}")
    end

    def update_guild_scheduled_event(guild_id, event_id, payload)
      patch("guilds/#{guild_id}/scheduled-events/#{event_id}", payload)
    end

    def delete_guild_scheduled_event(guild_id, event_id)
      request(:delete, "guilds/#{guild_id}/scheduled-events/#{event_id}")
    end

    # Discord caps a page at 100 and paginates by user id.
    SUBSCRIBER_PAGE_SIZE = 100

    # Who has clicked "Interested" on a scheduled event. This is the only way
    # to see RSVPs without a Gateway connection -- the corresponding
    # GUILD_SCHEDULED_EVENT_USER_ADD/REMOVE events are Gateway-only.
    def list_guild_scheduled_event_users(guild_id, event_id, after: nil, limit: SUBSCRIBER_PAGE_SIZE)
      query = {limit: limit}
      query[:after] = after if after.present?

      request(:get, "guilds/#{guild_id}/scheduled-events/#{event_id}/users?#{query.to_query}")
    end

    private def post(path, payload)
      request(:post, path, payload)
    end

    private def patch(path, payload)
      request(:patch, path, payload)
    end

    private def request(method, path, payload = nil)
      raise Error.new(0, "missing bot token") if @token.blank?

      response = connection.run_request(method, path, payload&.to_json, nil)
      handle_response(response)
    end

    private def handle_response(response)
      return nil if response.status == 204
      return JSON.parse(response.body) if response.status.between?(200, 299)

      raise Error.new(response.status, response.body)
    end

    private def connection
      @connection ||= Faraday.new(url: BASE_URL) do |c|
        c.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
          retry_statuses: [429, 502, 503, 504],
          methods: %i[get post patch delete put]
        c.headers["Authorization"] = "Bot #{@token}"
        c.headers["Content-Type"] = "application/json"
        c.headers["User-Agent"] = "Fleetyards (https://fleetyards.net, 1.0)"
      end
    end
  end
end

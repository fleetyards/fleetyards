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

    # Manage Events permission bit (1 << 33).
    INSTALL_PERMISSIONS = 8_589_934_592

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

    def create_guild_scheduled_event(guild_id, payload)
      post("guilds/#{guild_id}/scheduled-events", payload)
    end

    def update_guild_scheduled_event(guild_id, event_id, payload)
      patch("guilds/#{guild_id}/scheduled-events/#{event_id}", payload)
    end

    def delete_guild_scheduled_event(guild_id, event_id)
      request(:delete, "guilds/#{guild_id}/scheduled-events/#{event_id}")
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

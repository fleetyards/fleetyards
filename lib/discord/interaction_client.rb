# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module Discord
  # Sends the real answer for an interaction the endpoint already deferred.
  #
  # Separate from ApiClient because this path is authenticated by the
  # interaction token in the URL, not by the bot token. ApiClient refuses to
  # run without a bot token, and relaxing that would weaken the one guard that
  # keeps a misconfigured deploy from talking to Discord unauthenticated.
  class InteractionClient
    BASE_URL = "https://discord.com/api/v10/"

    # An interaction token is valid for 15 minutes. A job still queued after
    # that cannot deliver anything, and retrying only burns rate limit.
    TOKEN_TTL = 15.minutes

    Error = Class.new(StandardError)

    def self.expired?(requested_at)
      return false if requested_at.blank?

      Time.current.to_i - requested_at.to_i > TOKEN_TTL.to_i
    end

    def initialize(application_id:, token:)
      @application_id = application_id
      @token = token
    end

    def edit_original(payload)
      response = connection.patch(
        "webhooks/#{@application_id}/#{@token}/messages/@original",
        payload.to_json
      )

      return true if response.status.between?(200, 299)

      raise Error, "Discord interaction edit failed: #{response.status} #{response.body}"
    end

    # A new message rather than an edit. After a deferred *update* there is no
    # placeholder for the answer to replace, so this is how a click is answered
    # privately while the message it was on stays as it is -- and unlike the
    # follow-up to a deferred command, it honours the ephemeral flag.
    def create_followup(payload)
      response = connection.post(
        "webhooks/#{@application_id}/#{@token}",
        payload.merge(flags: Commands::Base::EPHEMERAL).to_json
      )

      return true if response.status.between?(200, 299)

      raise Error, "Discord interaction follow-up failed: #{response.status} #{response.body}"
    end

    private def connection
      @connection ||= Faraday.new(url: BASE_URL) do |c|
        c.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
          retry_statuses: [429, 502, 503, 504],
          methods: %i[patch post]
        c.headers["Content-Type"] = "application/json"
        c.headers["User-Agent"] = "Fleetyards (https://fleetyards.net, 1.0)"
      end
    end
  end
end

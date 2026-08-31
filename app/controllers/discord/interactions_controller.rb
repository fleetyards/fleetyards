# frozen_string_literal: true

module Discord
  # Discord's Interactions Endpoint. Every slash command arrives here as a
  # POST; there is no session, no cookie and no user.
  #
  # Inherits ActionController::Base rather than ApplicationController on
  # purpose: ApplicationController adds HTTP basic auth whenever
  # basic_auth.password is set, which is how staging is protected. Discord
  # cannot supply those credentials, so every interaction would 401 there.
  class InteractionsController < ActionController::Base
    skip_forgery_protection

    # Interaction request types.
    PING = 1
    APPLICATION_COMMAND = 2

    # Interaction response types.
    PONG = 1
    MESSAGE = 4
    DEFERRED_MESSAGE = 5

    def create
      return head :unauthorized unless verified?

      case payload["type"]
      # PING answers regardless of the feature flag: saving the endpoint URL in
      # the Discord portal is what triggers it, and that has to be possible
      # before the commands are switched on.
      when PING then render json: {type: PONG}
      when APPLICATION_COMMAND
        Flipper.enabled?(:discord_commands) ? acknowledge_command : refuse_command
      else head :no_content
      end
    end

    # Discord probes a newly saved endpoint URL with a deliberately invalid
    # signature and refuses to accept the URL unless that probe is rejected --
    # so an unverified request must be a 401, never a 200 with an error body.
    private def verified?
      return false unless SignatureVerifier.configured?

      SignatureVerifier.new.valid?(
        signature: request.headers[SignatureVerifier::SIGNATURE_HEADER],
        timestamp: request.headers[SignatureVerifier::TIMESTAMP_HEADER],
        body: raw_body
      )
    end

    # Nothing runs inline. Even a command that would finish in 40 ms locally
    # has to survive a cold connection pool and Discord's hard 3 second
    # deadline, after which the interaction cannot be answered at all.
    #
    # Visibility is decided *here*, not by the command: Discord fixes it at the
    # deferred acknowledgement and ignores flags on the follow-up. The registry
    # is the only place that knows it before the job has run.
    private def acknowledge_command
      Discord::CommandJob.perform_async(command_context)

      data = {}
      data[:flags] = Discord::Commands::Base::EPHEMERAL if ephemeral_command?

      render json: {type: DEFERRED_MESSAGE, data: data}
    end

    private def ephemeral_command?
      Discord::Commands::Registry.ephemeral?(payload.dig("data", "name"))
    end

    private def refuse_command
      render json: {
        type: MESSAGE,
        data: {
          content: I18n.t("discord.commands.disabled"),
          flags: Discord::Commands::Base::EPHEMERAL
        }
      }
    end

    # String keys throughout: Sidekiq serialises arguments to JSON and rejects
    # symbols under strict args, and the job reads this back with
    # with_indifferent_access anyway.
    private def command_context
      data = payload["data"] || {}

      {
        "application_id" => payload["application_id"],
        "token" => payload["token"],
        "command" => data["name"],
        "options" => command_options(data["options"]),
        "guild_id" => payload["guild_id"],
        "discord_user_id" => invoking_user_id,
        # Discord tells us the invoking member's own client locale; the guild
        # locale is the fallback for a member who has none.
        "locale" => payload["locale"] || payload["guild_locale"],
        "requested_at" => Time.current.to_i
      }
    end

    private def command_options(options)
      Array(options).to_h { |option| [option["name"], option["value"]] }
    end

    # In a guild the invoking user is under `member`; in a DM it is `user`.
    private def invoking_user_id
      payload.dig("member", "user", "id") || payload.dig("user", "id")
    end

    # The signature covers the raw bytes, so the body is read once here and the
    # parse is ours -- request.params would be a different byte sequence and
    # could never be verified.
    private def raw_body
      @raw_body ||= request.raw_post
    end

    private def payload
      @payload ||= JSON.parse(raw_body)
    rescue JSON::ParserError
      {}
    end
  end
end

# frozen_string_literal: true

require "discord/commands/registry"
require "discord/interaction_client"
require "discord/locale"

module Discord
  # Fills in the answer for an interaction the endpoint already acknowledged
  # with a deferred response. Discord gives us 3 seconds to acknowledge and 15
  # minutes to deliver, so all the actual work happens here.
  class CommandJob < ::ApplicationJob
    # Its own queue, first in config/sidekiq.yml: this is the only queue on a
    # user-facing latency budget, and a loader burst on `notifications` would
    # otherwise be visible as a bot that takes half a minute to answer.
    sidekiq_options retry: 2, queue: "discord"

    # A single hash rather than positional arguments -- Sidekiq replays
    # arguments positionally, and this payload grows a field per command.
    def perform(context)
      context = context.with_indifferent_access
      return if expired?(context)

      client = InteractionClient.new(
        application_id: context[:application_id],
        token: context[:token]
      )

      I18n.with_locale(Locale.resolve(context[:locale])) do
        client.edit_original(payload_for(context))
      end
    end

    private def payload_for(context)
      handler = Commands::Registry.handler_for(context[:command], context[:subcommand])
      return unknown_command(command_name(context)) if handler.nil?

      handler.new(
        options: context[:options] || {},
        guild_id: context[:guild_id],
        discord_user_id: context[:discord_user_id]
      ).call
    rescue => e
      # A command that raises must still say something: the interaction is
      # already showing "thinking...", and an unanswered one stays there.
      # Deterministic failures are not worth a retry, so this does not re-raise
      # -- transport failures in edit_original still do.
      Rails.logger.error("[Discord::CommandJob] command=#{command_name(context)} failed: #{e.class}: #{e.message}")
      Appsignal.report_error(e)

      failure
    end

    private def command_name(context)
      [context[:command], context[:subcommand]].compact_blank.join(" ")
    end

    private def expired?(context)
      started_at = context[:requested_at]
      return false if started_at.blank?

      Time.current.to_i - started_at.to_i > InteractionClient::TOKEN_TTL.to_i
    end

    private def unknown_command(name)
      Rails.logger.warn("[Discord::CommandJob] unknown command=#{name}")

      failure
    end

    private def failure
      # No flags: Discord ignores them on a follow-up, and this message
      # inherits the visibility the acknowledgement already fixed.
      {content: I18n.t("discord.commands.failed")}
    end
  end
end

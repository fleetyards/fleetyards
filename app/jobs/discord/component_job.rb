# frozen_string_literal: true

require "discord/components/fleet_request"
require "discord/interaction_client"
require "discord/join_request_message"
require "discord/locale"

module Discord
  # Answers a button click the endpoint already acknowledged with a deferred
  # update. The same 3 seconds and 15 minutes apply as for a slash command.
  class ComponentJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "discord"

    def perform(context)
      context = context.with_indifferent_access
      return if InteractionClient.expired?(context[:requested_at])

      client = InteractionClient.new(
        application_id: context[:application_id],
        token: context[:token]
      )

      # The clicker's language for what only they read; the shared message
      # picks its own.
      I18n.with_locale(Locale.resolve(context[:locale])) do
        result = result_for(context)

        client.edit_original(result[:update]) if result[:update].present?
        client.create_followup(result[:reply]) if result[:reply].present?
      end
    end

    private def result_for(context)
      request = JoinRequestMessage.parse(context[:custom_id])
      return unknown_component(context[:custom_id]) if request.nil?

      Components::FleetRequest.new(
        **request,
        guild_id: context[:guild_id],
        discord_user_id: context[:discord_user_id]
      ).call
    rescue => e
      # Nothing on screen says anything went wrong after a deferred update:
      # the button simply stops spinning. A private note is the only sign.
      Rails.logger.error("[Discord::ComponentJob] custom_id=#{context[:custom_id]} failed: #{e.class}: #{e.message}")
      Appsignal.report_error(e)

      failure
    end

    private def unknown_component(custom_id)
      Rails.logger.warn("[Discord::ComponentJob] unknown custom_id=#{custom_id}")

      failure
    end

    private def failure
      {reply: {content: I18n.t("discord.commands.failed")}}
    end
  end
end

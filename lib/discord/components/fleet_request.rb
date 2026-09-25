# frozen_string_literal: true

require "discord/commands/base"
require "discord/commands/fleet_context"

module Discord
  module Components
    # A click on Accept or Decline under a join request.
    #
    # The custom_id only says which request the button belongs to. Everything
    # a slash command checks is checked again here, on every click: which fleet
    # this server is, who the clicking member is on Fleetyards, and whether
    # they may answer requests -- a message in a channel says nothing about
    # who is reading it, and the officer who could answer yesterday may not be
    # one today.
    #
    # Answers with `update` (the new state of the shared message), `reply` (a
    # private note to whoever clicked), or both.
    class FleetRequest < Commands::Base
      include Commands::FleetContext

      def initialize(decision:, membership_id:, guild_id:, discord_user_id:)
        super(guild_id: guild_id, discord_user_id: discord_user_id)
        @decision = decision
        @membership_id = membership_id
      end

      def call
        fleet = guild_fleet
        return reply(I18n.t("discord.commands.fleet.not_bound")) if fleet.nil?

        user = linked_user
        return reply(account_not_linked) if user.nil?

        # Before the lookup, as for the slash command: a refusal must not tell
        # whether the request still exists.
        unless JoinRequestDecision.allowed?(@decision, fleet, user)
          return reply(I18n.t("discord.commands.fleet.requests.not_allowed"))
        end

        # Looked up inside this server's fleet, so a button can only ever
        # settle a request to the fleet the clicking officer answers for.
        membership = fleet.fleet_memberships.kept.includes(:user, :fleet).find_by(id: @membership_id)
        if membership.nil?
          return {
            update: JoinRequestMessage.closed_payload(@membership_id),
            reply: message(content: I18n.t("discord.join_request.gone"))
          }
        end

        decide(membership, user)
      end

      private def decide(membership, user)
        case JoinRequestDecision.new(@decision, membership, officer: user).call
        when :done then {update: JoinRequestMessage.new(membership).settled_payload(officer: user)}
        when :not_pending then {update: JoinRequestMessage.new(membership).settled_payload}
        else reply(I18n.t("discord.commands.fleet.requests.failed"))
        end
      end

      private def reply(content)
        {reply: message(content: content)}
      end
    end
  end
end

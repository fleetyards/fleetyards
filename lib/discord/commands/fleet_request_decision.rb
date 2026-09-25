# frozen_string_literal: true

module Discord
  module Commands
    # Accepting or declining a join request from Discord. The two differ only in
    # which decision they make and which sentence they answer with.
    #
    # Ephemeral: the decision itself is announced by the notification the
    # transition already fires, so a second public copy in whatever channel the
    # officer happened to type in adds nothing.
    class FleetRequestDecision < Base
      include FleetContext

      def call
        fleet = guild_fleet
        return message(content: I18n.t("discord.commands.fleet.not_bound")) if fleet.nil?

        user = linked_user
        return message(content: account_not_linked) if user.nil?

        # The privilege is checked before anything is looked up, so the command
        # cannot be used to find out whether a request exists.
        unless JoinRequestDecision.allowed?(self.class.decision, fleet, user)
          return message(content: I18n.t("discord.commands.fleet.requests.not_allowed"))
        end

        username = option("username").to_s.strip
        return message(content: I18n.t("discord.commands.fleet.requests.missing_username")) if username.blank?

        decide(fleet, user, username)
      end

      private def decide(fleet, user, username)
        membership = membership_for(fleet, username)
        return message(content: I18n.t("discord.commands.fleet.requests.no_request", username: username)) if membership.nil?

        case JoinRequestDecision.new(self.class.decision, membership, officer: user).call
        when :not_pending
          message(content: I18n.t("discord.commands.fleet.requests.not_pending",
            username: membership.user.username,
            url: url_for_path("/fleets/#{fleet.slug}/members/")))
        when :failed
          message(content: I18n.t("discord.commands.fleet.requests.failed"))
        else
          message(content: I18n.t("discord.commands.fleet.requests.#{self.class.done_key}",
            username: membership.user.username,
            fleet: fleet.name))
        end
      end

      private def membership_for(fleet, username)
        fleet.fleet_memberships.kept
          .includes(:user)
          .joins(:user)
          .find_by(users: {normalized_username: username.downcase})
      end

      class << self
        def decision
          raise NotImplementedError
        end

        def done_key
          raise NotImplementedError
        end
      end
    end
  end
end

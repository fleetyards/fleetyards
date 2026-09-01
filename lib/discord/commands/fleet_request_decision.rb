# frozen_string_literal: true

module Discord
  module Commands
    # Accepting or declining a join request from Discord. The two differ only in
    # which AASM event they fire and which sentence they answer with.
    #
    # Ephemeral: the decision itself is announced by the notification the
    # transition already fires, so a second public copy in whatever channel the
    # officer happened to type in adds nothing.
    class FleetRequestDecision < Base
      include FleetContext

      def call
        return message(content: I18n.t("discord.commands.disabled")) unless Flipper.enabled?(:discord_fleet_commands)

        fleet = guild_fleet
        return message(content: I18n.t("discord.commands.fleet.not_bound")) if fleet.nil?

        user = linked_user
        return message(content: account_not_linked) if user.nil?

        # The privilege is checked before anything is looked up, so the command
        # cannot be used to find out whether a request exists.
        return message(content: I18n.t("discord.commands.fleet.requests.not_allowed")) unless allowed?(fleet, user)

        username = option("username").to_s.strip
        return message(content: I18n.t("discord.commands.fleet.requests.missing_username")) if username.blank?

        decide(fleet, user, username)
      end

      private def decide(fleet, user, username)
        membership = membership_for(fleet, username)
        return message(content: I18n.t("discord.commands.fleet.requests.no_request", username: username)) if membership.nil?

        # Two officers answering the same request is normal, not an error: AASM
        # runs with whiny_transitions off, so the second call would silently
        # return false and read as a failure.
        unless membership.requested?
          return message(content: I18n.t("discord.commands.fleet.requests.not_pending",
            username: membership.user.username,
            url: url_for_path("/fleets/#{fleet.slug}/members/")))
        end

        # Recorded on the version, so the audit trail names the officer rather
        # than nobody.
        membership.author_id = user.id

        return message(content: I18n.t("discord.commands.fleet.requests.failed")) unless apply(membership)

        message(content: I18n.t("discord.commands.fleet.requests.#{self.class.done_key}",
          username: membership.user.username,
          fleet: fleet.name))
      end

      private def membership_for(fleet, username)
        fleet.fleet_memberships.kept
          .includes(:user)
          .joins(:user)
          .find_by(users: {normalized_username: username.downcase})
      end

      # The same policy the members endpoint authorizes against. It requires an
      # accepted, undiscarded membership of the fleet.
      private def allowed?(fleet, user)
        ::FleetMembershipPolicy.new(fleet, user: user).apply(self.class.policy_rule)
      end

      private def apply(membership)
        raise NotImplementedError
      end

      class << self
        def policy_rule
          raise NotImplementedError
        end

        def done_key
          raise NotImplementedError
        end
      end
    end
  end
end

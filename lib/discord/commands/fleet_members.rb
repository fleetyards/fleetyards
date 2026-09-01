# frozen_string_literal: true

module Discord
  module Commands
    # The fleet's roster, or the join requests waiting on someone.
    #
    # Always ephemeral: a roster is usernames and RSI handles, which is personal
    # data whatever the fleet's public flag says, and the guild it was typed in
    # may have guests.
    class FleetMembers < Base
      include FleetContext
      include ActionView::Helpers::DateHelper

      MAX_MEMBERS = 10

      PENDING = "pending"

      def call
        fleet = guild_fleet
        return message(content: I18n.t("discord.commands.fleet.not_bound")) if fleet.nil?

        user = linked_user
        return message(content: account_not_linked) if user.nil?
        return message(content: I18n.t("discord.commands.fleet.members.not_allowed")) unless allowed?(fleet, user)

        memberships = memberships_for(fleet)
        return message(content: I18n.t("discord.commands.fleet.members.#{empty_key}")) if memberships.empty?

        message(content: content_for(fleet, memberships))
      end

      # The same policy the members endpoint authorizes against, so there is one
      # definition of who may read a roster. It requires an accepted,
      # undiscarded membership.
      private def allowed?(fleet, user)
        ::FleetMembershipPolicy.new(fleet, user: user).apply(:index?)
      end

      private def pending?
        option("filter").to_s == PENDING
      end

      private def empty_key
        pending? ? "no_requests" : "empty"
      end

      # The pending list is a queue, so it reads oldest first -- that is the
      # order someone works through it. The roster is a list to find a name in,
      # so it reads alphabetically.
      private def memberships_for(fleet)
        scope = fleet.fleet_memberships.kept.includes(:user, :fleet_role)

        if pending?
          scope.where(aasm_state: "requested").order(requested_at: :asc)
        else
          scope.where(aasm_state: "accepted").joins(:user).order("users.username asc")
        end
      end

      private def content_for(fleet, memberships)
        shown = memberships.first(MAX_MEMBERS)
        omitted = memberships.size - shown.size

        [
          heading(fleet, memberships.size),
          shown.map { |membership| line_for(membership) }.join("\n"),
          (I18n.t("discord.commands.fleet.members.more", count: omitted) if omitted.positive?)
        ].compact.join("\n")
      end

      private def heading(fleet, count)
        I18n.t("discord.commands.fleet.members.#{pending? ? "requests_heading" : "heading"}",
          fleet: fleet.name,
          url: url_for_path("/fleets/#{fleet.slug}/members/"),
          count: count)
      end

      # A pending line answers "how long has this been waiting"; a roster line
      # answers "what can this person do". Neither carries the other's noise.
      private def line_for(membership)
        if pending?
          "• #{membership.user.username}#{waiting_since(membership)}"
        else
          "• #{membership.user.username}#{role_of(membership)}"
        end
      end

      private def role_of(membership)
        name = membership.fleet_role&.name
        return "" if name.blank?

        " — #{name}"
      end

      private def waiting_since(membership)
        return "" if membership.requested_at.blank?

        " — #{I18n.t("discord.commands.fleet.members.waiting", time: time_ago(membership.requested_at))}"
      end

      private def time_ago(time)
        distance_of_time_in_words(Time.zone.now, time)
      end
    end
  end
end

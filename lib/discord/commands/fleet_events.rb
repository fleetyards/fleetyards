# frozen_string_literal: true

require "discord/event_availability"

module Discord
  module Commands
    # What is coming up in the guild's fleet.
    #
    # Ephemeral, which is not obvious for a list: `fleet:events:read` is a
    # *member* default privilege, so the schedule is internal data -- and a guild
    # can have guests, the same reason /fleet info refuses non-members. Posting
    # it in the channel would hand it to exactly the people the privilege
    # excludes.
    class FleetEvents < Base
      include FleetContext

      MAX_EVENTS = 5

      # Far enough to cover a monthly series, without expanding a daily one
      # forever to find five entries.
      LOOKAHEAD = 90.days

      # A draft is a work in progress; listing it in Discord publishes it in
      # every sense that matters. Cancelled and completed are not "upcoming".
      LISTED_STATUSES = %w[open locked active].freeze

      def call
        fleet = guild_fleet
        return message(content: I18n.t("discord.commands.fleet.not_bound")) if fleet.nil?

        user = linked_user
        return message(content: account_not_linked) if user.nil?
        return message(content: I18n.t("discord.commands.fleet.events.not_allowed")) unless allowed?(fleet, user)

        occurrences = upcoming(fleet)
        return message(content: I18n.t("discord.commands.fleet.events.none")) if occurrences.empty?

        message(content: content_for(fleet, occurrences))
      end

      # The same policy the events endpoint authorizes against; it requires an
      # accepted, undiscarded membership.
      private def allowed?(fleet, user)
        ::FleetEventPolicy.new(fleet, user: user).apply(:index?)
      end

      # The list is of *occurrences*, not of series rows: a weekly op would
      # otherwise appear once, on the date the series started.
      #
      # `starting_after` is what makes the pre-filter safe -- a recurring row
      # whose starts_at is long past still has occurrences ahead of it, so
      # filtering on starts_at would drop it along with all of them.
      private def upcoming(fleet)
        from = Time.current
        to = from + LOOKAHEAD

        fleet.fleet_events
          .active_status
          .starting_after(from)
          .where(status: LISTED_STATUSES)
          .flat_map { |event| occurrences_of(event, from, to) }
          .compact
          .sort_by { |occurrence| occurrence[:starts_at] }
          .first(MAX_EVENTS)
      end

      private def occurrences_of(event, from, to)
        event.occurrences(from: from, to: to).first(MAX_EVENTS).map do |time|
          date = event.recurring? ? time.to_date : nil
          availability = ::Discord::EventAvailability.new(event, occurrence_date: date)

          # A cancelled occurrence of a live series is not upcoming, and only the
          # overlay row knows about it.
          next nil if availability.cancelled?

          {event: event, starts_at: availability.starts_at, title: availability.title, availability: availability.label}
        end
      end

      private def content_for(fleet, occurrences)
        [
          I18n.t("discord.commands.fleet.events.heading",
            fleet: fleet.name,
            url: url_for_path("/fleets/#{fleet.slug}/events/")),
          occurrences.map { |occurrence| line_for(occurrence) }.join("\n")
        ].join("\n")
      end

      # Discord renders <t:unix:f> in the reader's own timezone, which is the
      # only correct answer for a fleet whose members are spread across several.
      private def line_for(occurrence)
        [
          "• [#{occurrence[:title]}](#{event_url(occurrence[:event])})",
          "<t:#{occurrence[:starts_at].to_i}:f>",
          occurrence[:availability]
        ].compact_blank.join(" — ")
      end

      private def event_url(event)
        url_for_path("/fleets/#{event.fleet.slug}/events/#{event.slug}/")
      end
    end
  end
end

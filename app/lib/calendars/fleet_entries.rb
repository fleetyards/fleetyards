# frozen_string_literal: true

module Calendars
  # A fleet's events between two times, as one reader may see them: one-off
  # events that start inside the window, and every occurrence a recurring event
  # has inside it. Shared by the fleet calendar and the personal agenda, so the
  # two can never disagree about which events a member is shown.
  class FleetEntries
    def initialize(fleet:, membership:, from:, to:, manager:, published_only: false)
      @fleet = fleet
      @membership = membership
      @from = from
      @to = to
      @manager = manager
      @published_only = published_only
    end

    # `[event, occurrence_time]` pairs, soonest first. `occurrence_time` is nil
    # for a one-off event.
    def entries
      @entries ||= begin
        one_off = narrow(events.where(recurring: false).where(starts_at: @from..@to))
        recurring = narrow(events.where(recurring: true).where("starts_at <= ?", @to))

        pairs = one_off.map { |event| [event, nil] }
        recurring.each do |event|
          event.occurrences(from: @from, to: @to).each { |occurrence| pairs << [event, occurrence] }
        end

        pairs.sort_by { |(event, occurrence)| occurrence || event.starts_at }
      end
    end

    # Keyed the way a signup names its occurrence: the event, and the day for
    # a recurring one. A withdrawn signup is no longer the reader's plan.
    def viewer_signups
      @viewer_signups ||= begin
        events = entries.map(&:first).uniq

        if @membership.blank? || events.empty?
          {}
        else
          FleetEventSignup
            .where(fleet_membership: @membership, fleet_event_id: events.map(&:id))
            .where.not(status: "withdrawn")
            .index_by { |signup| [signup.fleet_event_id, signup.occurrence_date] }
        end
      end
    end

    private def events
      @fleet.fleet_events.where(archived_at: nil)
    end

    # Whoever runs the fleet's events sees all of them, including the squadron
    # ones they are not in. Everyone else sees what their squadrons allow and,
    # on a summary, only what has been announced to the whole fleet.
    private def narrow(scope)
      return scope if @manager

      scope = scope.for_squadrons_of(@membership)
      scope = scope.where.not(status: "draft").where.not(visibility: "officers") if @published_only
      scope
    end
  end
end

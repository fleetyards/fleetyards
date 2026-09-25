# frozen_string_literal: true

module Discord
  # What Fleetyards knows about an event that Discord does not: how much room is
  # left in it, and -- for one occurrence of a recurring series -- which title
  # and which start time actually apply.
  #
  # Shared by the reminder and the event list on purpose. A bot that disagrees
  # with its own reminder about how many slots are open is a bug report nobody
  # can reproduce.
  class EventAvailability
    def initialize(event, occurrence_date: nil)
      @event = event
      @occurrence_date = occurrence_date
    end

    # An occurrence may override the series title; nil means inherit.
    def title
      state&.title.presence || @event.title
    end

    def starts_at
      return @event.starts_at if @occurrence_date.blank?

      # A recurring occurrence keeps the parent's time of day on its own date.
      @event.starts_at.change(
        year: @occurrence_date.year,
        month: @occurrence_date.month,
        day: @occurrence_date.day
      )
    end

    def cancelled?
      state&.cancelled_at.present?
    end

    # Slots are the point, but plenty of events have none -- those report the
    # signup count instead of "0 of 0 slots open", which reads like a full event.
    # An event with neither reports nothing at all rather than a zero.
    def label
      total = @event.slots.count
      return signups if total.zero?

      I18n.t("discord.event_availability.slots", open: total - taken_slots, total: total)
    end

    private def signups
      count = signups_scope.count
      return nil if count.zero?

      I18n.t("discord.event_availability.signups", count: count)
    end

    private def taken_slots
      signups_scope.where.not(fleet_event_slot_id: nil).count
    end

    # A withdrawn signup frees its slot again, so the count matches what the
    # event page shows.
    private def signups_scope
      scope = @event.fleet_event_signups.where.not(status: "withdrawn")
      return scope if @occurrence_date.blank?

      scope.where(occurrence_date: @occurrence_date)
    end

    private def state
      return nil if @occurrence_date.blank?

      @state = @event.occurrence_state_for(@occurrence_date, build: false) unless defined?(@state)
      @state
    end
  end
end
